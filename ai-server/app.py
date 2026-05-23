import os
from flask import Flask, request, jsonify
import requests
import json
import re
from transformers import pipeline

# Supabase 라이브러리 추가
from supabase import create_client, Client

app = Flask(__name__)

# CORS 설정 (외부 접속 허용)
@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    response.headers["Access-Control-Allow-Methods"] = "POST, OPTIONS"
    return response

# =====================================================================
# [초기화 설정]
# =====================================================================
# ⭐️ 여기에 본인의 Supabase 프로젝트 URL과 API 키(anon public)를 입력하세요!
SUPABASE_URL = "https://stbdmjcdivkhpqvfegwm.supabase.co"
SUPABASE_KEY = "sb_publishable_Rq50iIhTcIqSufu0AN5EfQ_Nu1G4elc"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

OLLAMA_API_URL = "http://localhost:11434/api/generate"
MAIN_MODEL = "qwen2.5:7b"

# 1. 프롬프트 인젝션 방어 모델 로드
print("🛡️ [보안] ProtectAI 인젝션 방어 모델 로딩 중 (잠시만 기다려주세요)...")
try:
    guardrail = pipeline("text-classification", model="protectai/deberta-v3-base-prompt-injection-v2")
    print("✅ [보안] Guardrail 모델 로딩 완료!")
except Exception as e:
    print(f"❌ [에러] 모델 로딩 실패: {e}")
    exit(1)

# 한국어 특화 악성 지시어 정규식 패턴 (휴리스틱 방어용)
INJECTION_PATTERNS = [
    r"이전 지시", r"무시하고", r"시스템 프롬프트", r"초기 설정", 
    r"명령어\s*출력", r"너의 목적", r"너의 역할", r"개발자 모드", r"탈옥"
]

def is_heuristic_injection(text):
    """정규식을 통한 0.01초 컷 1차 방어"""
    for pattern in INJECTION_PATTERNS:
        if re.search(pattern, text, re.IGNORECASE):
            return True
    return False

# =====================================================================
# [DB 검색 함수] - Supabase에서 키워드로 식당 찾기
# =====================================================================
def search_restaurants(keywords, top_n=10):
    if not keywords:
        # 키워드가 없으면 최신순(또는 랜덤)으로 아무거나 가져옴
        res = supabase.table('stores').select('*').limit(top_n).execute()
        return res.data
    
    all_matched_records = []
    
    # 1. 각 키워드별로 DB에 검색 요청 (LIKE 검색)
    for kw in keywords:
        query_str = f"음식점명.ilike.%{kw}%,업종정보.ilike.%{kw}%,대표메뉴명.ilike.%{kw}%,메뉴한글명.ilike.%{kw}%"
        res = supabase.table('stores').select('*').or_(query_str).execute()
        all_matched_records.extend(res.data)
        
    # 2. 중복된 가게 제거 및 매칭 점수(Score) 계산
    unique_stores = {}
    for store in all_matched_records:
        store_id = store.get('음식점아이디') # Supabase 내 Primary Key 컬럼명에 맞게 수정 필요
        if store_id not in unique_stores:
            unique_stores[store_id] = store
            unique_stores[store_id]['score'] = 0
            
    if not unique_stores: # 검색된 게 없으면 기본 목록 반환
        return supabase.table('stores').select('*').limit(top_n).execute().data
        
    # 3. 키워드와 가장 많이 겹치는지 점수 계산
    for store_id, store in unique_stores.items():
        name = store.get('음식점명') or ''
        category = store.get('업종정보') or ''
        main_menu = store.get('대표메뉴명') or ''
        menu_list = store.get('메뉴한글명') or ''
        
        search_text = f"{name} {category} {main_menu} {menu_list}"
        
        for kw in keywords:
            if kw in search_text:
                store['score'] += 1
                
    # 4. 점수가 높은 순으로 정렬해서 상위 N개만 잘라냄
    sorted_stores = sorted(unique_stores.values(), key=lambda x: x['score'], reverse=True)
    return sorted_stores[:top_n]

# =====================================================================
# [API 엔드포인트]
# =====================================================================
@app.route('/api/ai', methods=['POST', 'OPTIONS'])
def process_ai_request():
    # Preflight 요청 처리
    if request.method == 'OPTIONS':
        return ('', 204)

    data = request.json
    
    if not data or 'input' not in data:
        return jsonify({"status": "error", "message": "입력값(input)이 없습니다."}), 400
        
    user_input = data.get('input', '')
    role = data.get('role', 'user')

    print(f"\n--- 📥 [요청 수신] 역할: {role} ---")
    print(f"입력값: {user_input}")

    # ---------------------------------------------------------
    # 🕵️‍♂️ [1계층] Input Guardrail (사전 검증 층)
    # ---------------------------------------------------------
    if is_heuristic_injection(user_input):
        print("🚫 [차단] 휴리스틱 인젝션 패턴 감지됨")
        return jsonify({"status": "error", "message": "허용되지 않는 명령 패턴이 포함되어 있습니다."}), 400

    gr_result = guardrail(user_input)[0]
    label = gr_result['label']
    score = gr_result['score']
    
    print(f"🔍 [Guardrail 검사] 결과: {label} (확신도: {score:.2f})")
    
    if label == 'INJECTION' and score > 0.5:
        print("🚫 [차단] 악성 프롬프트 인젝션/탈옥 감지됨")
        return jsonify({"status": "error", "message": "시스템 탈취 및 비정상적인 지시어가 감지되어 요청이 차단되었습니다."}), 400

    # ---------------------------------------------------------
    # 📦 [2계층] Context Isolation & 2-Step RAG 적용
    # ---------------------------------------------------------
    if role == 'user':
        # [Step 1] 사용자 상황에서 검색 키워드 추출 (1차 Ollama 호출)
        print("⏳ [1단계] 사용자 상황 분석 및 키워드 추출 중...")
        keyword_prompt = f"""너는 맛집 검색을 위한 키워드 추출기다.
사용자의 상황을 분석해서 검색에 사용할 핵심 단어(음식 종류, 분위기 등)를 2~4개만 뽑아라.
반드시 아래 JSON 스키마로만 답변해라.
{{"keywords": ["키워드1", "키워드2"]}}

<user_input>
{user_input}
</user_input>"""

        try:
            resp_1 = requests.post(OLLAMA_API_URL, json={
                "model": MAIN_MODEL,
                "prompt": keyword_prompt,
                "format": "json",
                "stream": False,
                "options": {"temperature": 0.3}
            }, timeout=30)
            resp_1.raise_for_status()
            kw_json = json.loads(resp_1.json().get('response', '{}'))
            keywords = kw_json.get('keywords', [])
            print(f"✅ [키워드 추출 완료] {keywords}")
        except Exception as e:
            print(f"⚠️ 키워드 추출 실패. 기본 검색으로 대체합니다. 에러: {e}")
            keywords = []

        # [Step 2] 추출된 키워드로 Supabase DB 검색
        print("🔍 [2단계] Supabase DB에서 맞춤 맛집 검색 중...")
        top_restaurants = search_restaurants(keywords, top_n=10)
        
        db_context = []
        for r in top_restaurants:
            info = f"가게명: {r.get('음식점명', '')} | 카테고리: {r.get('업종정보', '')} | 대표메뉴: {r.get('대표메뉴명', '')} | 메뉴: {r.get('메뉴한글명', '')} | 주소: {r.get('주소', '')}"
            db_context.append(info)
        db_context_str = "\n".join(db_context)
        print(f"✅ [검색 완료] {len(top_restaurants)}개의 후보 식당 발견")

        # [Step 3] 검색된 데이터를 바탕으로 최종 프롬프트 조립
        system_prompt = f"""너는 대전·충청권 로컬마켓 활성화 서비스 '동네U'의 맛집 추천 AI다.
사용자의 상황에 깊이 공감해주며, **반드시 아래 제공된 [DB 검색 후보] 안에서만 가장 어울리는 3곳을 골라 추천해라.**
가상의 식당을 절대 지어내면 안 된다.

[DB 검색 후보]
{db_context_str}

반드시 아래 JSON 스키마 형식으로만 답변하고, 다른 말은 추가하지 마라.
{{"recommendations": [{{"card_type": "동네U추천", "store_name": "가게이름", "reason": "사용자 상황에 맞춘 추천 이유 (가게명이나 메뉴를 자연스럽게 언급)"}}]}}"""
        
        isolated_prompt = f"{system_prompt}\n\n<user_input>\n{user_input}\n</user_input>"
        
    elif role == 'owner':
        system_prompt = """너는 소상공인을 돕는 '동네U'의 전문 마케터 AI다.
사장님이 입력한 메뉴와 가게 특징을 바탕으로 자연스러운 인스타그램 홍보 문구와 해시태그를 생성해라.
반드시 아래 JSON 스키마 형식으로만 답변하고, 다른 말은 절대 추가하지 마라.
{"marketing": {"post_text": "홍보문구 본문", "hashtags": ["#태그1", "#태그2"]}}"""
        isolated_prompt = f"{system_prompt}\n\n<owner_input>\n{user_input}\n</owner_input>"
        
    else:
        return jsonify({"status": "error", "message": "잘못된 권한(role)입니다."}), 400

    # ---------------------------------------------------------
    # 🧠 [3계층] 메인 LLM 추론 (Ollama 호출 2)
    # ---------------------------------------------------------
    print("⏳ [메인 LLM] 최종 응답 생성 중...")
    payload = {
        "model": MAIN_MODEL,
        "prompt": isolated_prompt,
        "format": "json", 
        "stream": False,
        "options": {
            "temperature": 0.7 
        }
    }
    
    try:
        response = requests.post(OLLAMA_API_URL, json=payload, timeout=45)
        response.raise_for_status()
        llm_output = response.json().get('response', '')
    except requests.exceptions.RequestException as e:
        print(f"❌ [에러] Ollama 서버 접속 실패: {e}")
        return jsonify({"status": "error", "message": "AI 추론 서버(Ollama)에 연결할 수 없습니다."}), 500

    # ---------------------------------------------------------
    # 🗂️ [4계층] Egress Filter (출력 검증 및 마스킹)
    # ---------------------------------------------------------
    print("🔍 [출력 검증] JSON 파싱 및 유출 검사 중...")
    try:
        parsed_result = json.loads(llm_output)
        
        if "동네U의 맛집 추천 AI" in llm_output or "DB 검색 후보" in llm_output or "JSON 스키마" in llm_output:
            print("🚫 [차단] 출력물 내 시스템 프롬프트 유출 감지")
            raise ValueError("민감 지시어 유출")
            
        print("✅ [완료] 안전한 응답 반환")
        return jsonify({
            "status": "success",
            "data": parsed_result
        })
        
    except json.JSONDecodeError:
        print(f"❌ [에러] JSON 파싱 실패. LLM 원본 응답: {llm_output}")
        return jsonify({"status": "error", "message": "AI가 올바른 규격(JSON)으로 응답하지 않았습니다."}), 500
    except ValueError as ve:
        return jsonify({"status": "error", "message": "내부 보안 정책에 의해 출력이 차단되었습니다."}), 500

if __name__ == '__main__':
    print("\n🚀 동네U 통합 AI 보안 서버가 포트 5000에서 시작되었습니다!")
    app.run(host='0.0.0.0', port=5000)