import json
import os
import re
import time
from collections import defaultdict, deque
from pathlib import Path

import requests
from flask import Flask, jsonify, request
from supabase import Client, create_client
from transformers import pipeline


def _load_env_file() -> None:
    env_file = os.getenv("AI_SERVER_ENV_FILE")
    candidates = []
    if env_file:
        candidates.append(Path(env_file))
    app_dir = Path(__file__).resolve().parent
    candidates.extend(
        [
            app_dir / ".env",
            app_dir.parent / "backend" / "flask_ai" / ".env",
        ]
    )

    for path in candidates:
        if not path.is_file():
            continue
        for raw_line in path.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))
        return


_load_env_file()


def _required_env(name: str, fallback_name: str | None = None) -> str:
    value = os.getenv(name)
    if not value and fallback_name:
        value = os.getenv(fallback_name)
    if not value:
        raise RuntimeError(f"{name} environment variable is required")
    return value.strip()


app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = int(os.getenv("MAX_CONTENT_LENGTH", "16384"))

SUPABASE_URL = _required_env("SUPABASE_URL").rstrip("/")
SUPABASE_ANON_KEY = _required_env("SUPABASE_ANON_KEY", "SUPABASE_KEY")
OLLAMA_API_URL = os.getenv("OLLAMA_API_URL", "http://127.0.0.1:11434/api/generate")
MAIN_MODEL = os.getenv("AI_MODEL", os.getenv("MAIN_MODEL", "qwen2.5:7b"))
KAKAO_REST_API_KEY = os.getenv("KAKAO_REST_API_KEY", "").strip()
ALLOWED_ORIGINS = {
    origin.strip()
    for origin in os.getenv(
        "CORS_ORIGINS",
        "http://localhost:8092,http://127.0.0.1:8092",
    ).split(",")
    if origin.strip()
}
MAX_INPUT_LENGTH = int(os.getenv("MAX_INPUT_LENGTH", "1000"))
RATE_LIMIT_WINDOW_SECONDS = int(os.getenv("RATE_LIMIT_WINDOW_SECONDS", "60"))
RATE_LIMIT_REQUESTS = int(os.getenv("RATE_LIMIT_REQUESTS", "20"))
STORE_SELECT_COLUMNS = "id,name,category,address,description,tags,features,is_active"
MAX_STORE_CANDIDATES = int(os.getenv("MAX_STORE_CANDIDATES", "100"))

supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
_rate_buckets: dict[str, deque[float]] = defaultdict(deque)


@app.after_request
def add_security_headers(response):
    origin = request.headers.get("Origin")
    if origin and origin in ALLOWED_ORIGINS:
        response.headers["Access-Control-Allow-Origin"] = origin
        response.headers["Vary"] = "Origin"
    response.headers["Access-Control-Allow-Headers"] = (
        "Content-Type, Authorization"
    )
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["Cache-Control"] = "no-store"
    return response


print("[security] Loading ProtectAI prompt-injection guardrail model...")
try:
    guardrail = pipeline(
        "text-classification",
        model="protectai/deberta-v3-base-prompt-injection-v2",
    )
    print("[security] Guardrail model loaded")
except Exception as error:
    print(f"[error] Failed to load guardrail model: {error}")
    raise SystemExit(1)


INJECTION_PATTERNS = [
    r"이전 지시",
    r"무시하고",
    r"시스템 프롬프트",
    r"초기 설정",
    r"명령어\s*출력",
    r"너의 목적",
    r"너의 역할",
    r"개발자 모드",
    r"탈옥",
]


def _error(message: str, status: int):
    return jsonify({"status": "error", "message": message}), status


def _safe_log_text(text: str, max_length: int = 120) -> str:
    return re.sub(r"\s+", " ", text).strip()[:max_length]


def _check_rate_limit(key: str) -> bool:
    now = time.monotonic()
    bucket = _rate_buckets[key]
    while bucket and now - bucket[0] > RATE_LIMIT_WINDOW_SECONDS:
        bucket.popleft()
    if len(bucket) >= RATE_LIMIT_REQUESTS:
        return False
    bucket.append(now)
    return True


def _bearer_token() -> str | None:
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.lower().startswith("bearer "):
        return None
    token = auth_header[7:].strip()
    return token or None


def _fetch_profile_role(user_id: str, token: str) -> str:
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/profiles",
        params={"id": f"eq.{user_id}", "select": "role"},
        headers={
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
        },
        timeout=10,
    )
    response.raise_for_status()
    rows = response.json()
    if not rows:
        return "customer"
    return rows[0].get("role") or "customer"


def _authenticate_request() -> dict[str, str] | None:
    token = _bearer_token()
    if token is None:
        return None

    response = requests.get(
        f"{SUPABASE_URL}/auth/v1/user",
        headers={
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
        },
        timeout=10,
    )
    if response.status_code != 200:
        return None

    user = response.json()
    user_id = user.get("id")
    if not user_id:
        return None

    try:
        role = _fetch_profile_role(user_id, token)
    except requests.RequestException as error:
        print(f"[warn] profile role lookup failed: {type(error).__name__}")
        return None
    return {"id": user_id, "role": role}


def _has_required_role(user: dict[str, str], requested_role: str) -> bool:
    actual_role = user.get("role")
    if requested_role == "user":
        return actual_role in {"customer", "owner", "admin"}
    if requested_role == "owner":
        return actual_role in {"owner", "admin"}
    return False


def is_heuristic_injection(text: str) -> bool:
    return any(re.search(pattern, text, re.IGNORECASE) for pattern in INJECTION_PATTERNS)


def _sanitize_keywords(raw_keywords) -> list[str]:
    if not isinstance(raw_keywords, list):
        return []
    keywords: list[str] = []
    for item in raw_keywords[:6]:
        keyword = re.sub(r"[^0-9A-Za-z가-힣\s]", "", str(item)).strip()
        if keyword and len(keyword) <= 30:
            keywords.append(keyword)
    return keywords


def search_restaurants(keywords, top_n=10):
    safe_keywords = _sanitize_keywords(keywords)
    response = (
        supabase.table("stores")
        .select(STORE_SELECT_COLUMNS)
        .eq("is_active", True)
        .limit(MAX_STORE_CANDIDATES)
        .execute()
    )
    stores = response.data or []
    if not safe_keywords:
        return stores[:top_n]

    for store in stores:
        tags = store.get("tags") or []
        features = store.get("features") or []
        search_text = " ".join(
            [
                store.get("name") or "",
                store.get("category") or "",
                store.get("description") or "",
                " ".join(str(tag) for tag in tags),
                " ".join(str(feature) for feature in features),
            ]
        )
        store["score"] = sum(1 for keyword in safe_keywords if keyword in search_text)

    ranked = sorted(stores, key=lambda item: item.get("score", 0), reverse=True)
    return ranked[:top_n]


def _ollama_generate(prompt: str, temperature: float, timeout: int):
    response = requests.post(
        OLLAMA_API_URL,
        json={
            "model": MAIN_MODEL,
            "prompt": prompt,
            "format": "json",
            "stream": False,
            "options": {"temperature": temperature},
        },
        timeout=timeout,
    )
    response.raise_for_status()
    return response.json().get("response", "")


def _build_store_context(stores: list[dict]) -> str:
    lines = []
    for store in stores:
        tags = ", ".join(store.get("tags") or [])
        features = ", ".join(store.get("features") or [])
        lines.append(
            " | ".join(
                [
                    f"가게명: {store.get('name', '')}",
                    f"업종: {store.get('category', '')}",
                    f"설명: {store.get('description', '')}",
                    f"태그: {tags}",
                    f"특징: {features}",
                    f"주소: {store.get('address', '')}",
                ]
            )
        )
    return "\n".join(lines)


def _validate_user_recommendations(parsed_result: dict, candidate_stores: list[dict]):
    if not isinstance(parsed_result, dict):
        raise ValueError("invalid result")
    raw_recommendations = parsed_result.get("recommendations")
    if not isinstance(raw_recommendations, list):
        raise ValueError("missing recommendations")

    allowed_names = {store.get("name") for store in candidate_stores if store.get("name")}
    filtered = []
    for item in raw_recommendations:
        if not isinstance(item, dict):
            continue
        store_name = str(item.get("store_name") or "").strip()
        if store_name not in allowed_names:
            continue
        filtered.append(
            {
                "card_type": str(item.get("card_type") or "동네U추천").strip()[:20],
                "store_name": store_name,
                "reason": str(item.get("reason") or "입력한 조건과 잘 맞는 가게예요.").strip()[:300],
            }
        )
        if len(filtered) == 3:
            break

    if not filtered:
        for store in candidate_stores[:3]:
            filtered.append(
                {
                    "card_type": "동네U추천",
                    "store_name": store.get("name", "이름 없는 가게"),
                    "reason": "입력한 조건과 가까운 후보 중 하나예요.",
                }
            )

    parsed_result["recommendations"] = filtered
    return parsed_result


def _validate_owner_marketing(parsed_result: dict):
    marketing = parsed_result.get("marketing") if isinstance(parsed_result, dict) else None
    if not isinstance(marketing, dict):
        raise ValueError("missing marketing")
    post_text = str(marketing.get("post_text") or "").strip()
    hashtags = marketing.get("hashtags")
    if not post_text:
        raise ValueError("empty marketing text")
    if not isinstance(hashtags, list):
        hashtags = []
    parsed_result["marketing"] = {
        "post_text": post_text[:1200],
        "hashtags": [str(tag).strip()[:40] for tag in hashtags[:12] if str(tag).strip()],
    }
    return parsed_result


@app.route("/api/address/search", methods=["GET", "OPTIONS"])
def search_address():
    if request.method == "OPTIONS":
        return ("", 204)

    if not KAKAO_REST_API_KEY:
        return _error("주소 검색 API key가 설정되지 않았습니다.", 503)
    if not _check_rate_limit(f"ip:{request.remote_addr or 'unknown'}:address"):
        return _error("요청이 너무 많습니다. 잠시 후 다시 시도해주세요.", 429)

    user = _authenticate_request()
    if user is None:
        return _error("인증이 필요합니다.", 401)
    if user.get("role") not in {"owner", "admin"}:
        return _error("주소 검색 권한이 없습니다.", 403)

    query = str(request.args.get("query") or "").strip()
    if not query:
        return _error("검색어(query)가 필요합니다.", 400)
    if len(query) > 100:
        return _error("검색어가 너무 깁니다.", 413)

    try:
        response = requests.get(
            "https://dapi.kakao.com/v2/local/search/address.json",
            params={"query": query, "size": "10"},
            headers={"Authorization": f"KakaoAK {KAKAO_REST_API_KEY}"},
            timeout=12,
        )
        response.raise_for_status()
        payload = response.json()
    except requests.RequestException as error:
        print(f"[error] Kakao address lookup failed: {type(error).__name__}")
        return _error("주소 검색 API 요청에 실패했습니다.", 502)

    documents = payload.get("documents")
    if not isinstance(documents, list):
        documents = []
    return jsonify({"status": "success", "documents": documents[:10]})


@app.route("/api/ai", methods=["POST", "OPTIONS"])
def process_ai_request():
    if request.method == "OPTIONS":
        return ("", 204)

    if not _check_rate_limit(f"ip:{request.remote_addr or 'unknown'}"):
        return _error("요청이 너무 많습니다. 잠시 후 다시 시도해주세요.", 429)

    user = _authenticate_request()
    if user is None:
        return _error("인증이 필요합니다.", 401)
    if not _check_rate_limit(f"user:{user['id']}"):
        return _error("요청이 너무 많습니다. 잠시 후 다시 시도해주세요.", 429)

    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return _error("JSON 요청 본문이 필요합니다.", 400)

    user_input = str(data.get("input") or "").strip()
    requested_role = str(data.get("role") or "user").strip()
    if requested_role not in {"user", "owner"}:
        return _error("잘못된 권한입니다.", 400)
    if not _has_required_role(user, requested_role):
        return _error("해당 기능을 사용할 권한이 없습니다.", 403)
    if not user_input:
        return _error("입력값(input)이 없습니다.", 400)
    if len(user_input) > MAX_INPUT_LENGTH:
        return _error("입력값이 너무 깁니다.", 413)

    print(f"[request] user={user['id']} role={requested_role} input={_safe_log_text(user_input)}")

    if is_heuristic_injection(user_input):
        return _error("허용되지 않는 명령 패턴이 포함되어 있습니다.", 400)

    guardrail_result = guardrail(user_input)[0]
    if guardrail_result["label"] == "INJECTION" and guardrail_result["score"] > 0.5:
        return _error("시스템 탈취 지시어가 감지되어 차단되었습니다.", 400)

    conditions = {}
    candidate_stores: list[dict] = []
    if requested_role == "user":
        keyword_prompt = f"""너는 맛집 검색용 조건 및 키워드 추출기다.
사용자의 상황을 분석해서 위치, 예산, 시간대, 상황 정보와 검색에 쓸 핵심 단어를 2~4개만 뽑아라.
사용자 입력에 특정 정보가 명시되어 있지 않다면 "정보 없음"이라고 기입해라.
반드시 아래 JSON 스키마로만 답변해라.
{{"location": "위치 정보", "budget": "예산 정보", "time": "시간대 정보", "situation": "상황 정보", "keywords": ["키워드1", "키워드2"]}}

<user_input>
{user_input}
</user_input>"""

        try:
            keyword_output = _ollama_generate(keyword_prompt, temperature=0.3, timeout=30)
            conditions = json.loads(keyword_output)
            keywords = _sanitize_keywords(conditions.get("keywords", []))
        except Exception as error:
            print(f"[warn] keyword extraction failed: {type(error).__name__}")
            conditions = {}
            keywords = []

        candidate_stores = search_restaurants(keywords, top_n=10)
        db_context = _build_store_context(candidate_stores)

        isolated_prompt = f"""너는 대전·충청권 로컬마켓 서비스 '동네U'의 맛집 추천 AI다.
사용자의 상황에 공감하되, 반드시 아래 제공된 [DB 검색 후보] 안에서만 가장 어울리는 3곳을 골라 추천해라.
가상의 식당을 절대 지어내면 안 된다.

[DB 검색 후보]
{db_context}

반드시 아래 JSON 스키마 형식으로만 답변해라.
{{"recommendations": [{{"card_type": "동네U추천", "store_name": "가게이름", "reason": "사용자 상황에 맞춘 추천 이유"}}]}}

<user_input>
{user_input}
</user_input>"""
    else:
        isolated_prompt = f"""너는 소상공인을 돕는 '동네U'의 마케터 AI다.
사장님이 입력한 메뉴와 가게 특징을 바탕으로 자연스러운 인스타그램 홍보 문구와 해시태그를 생성해라.
반드시 아래 JSON 스키마 형식으로만 답변해라.
{{"marketing": {{"post_text": "홍보문구 본문", "hashtags": ["#태그1", "#태그2"]}}}}

<owner_input>
{user_input}
</owner_input>"""

    try:
        llm_output = _ollama_generate(isolated_prompt, temperature=0.7, timeout=45)
    except Exception as error:
        print(f"[error] Ollama request failed: {type(error).__name__}")
        return _error("AI 추론 서버 통신 에러.", 500)

    try:
        if "동네U의 맛집 추천 AI" in llm_output or "DB 검색 후보" in llm_output:
            raise ValueError("prompt leakage")
        parsed_result = json.loads(llm_output)
        if requested_role == "user":
            parsed_result = _validate_user_recommendations(parsed_result, candidate_stores)
            if conditions:
                parsed_result["conditions"] = conditions
        else:
            parsed_result = _validate_owner_marketing(parsed_result)
        return jsonify({"status": "success", "data": parsed_result})
    except Exception as error:
        print(f"[error] invalid AI output: {type(error).__name__}")
        return _error("AI 응답 파싱 실패.", 500)


if __name__ == "__main__":
    host = os.getenv("HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "5000"))
    debug = os.getenv("FLASK_DEBUG", "").lower() in {"1", "true", "yes"}
    print(f"[startup] DongNeU AI server listening on {host}:{port}")
    app.run(host=host, port=port, debug=debug)
