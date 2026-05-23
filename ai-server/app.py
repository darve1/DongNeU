import os
from flask import Flask, request, jsonify
import requests
import json
import re
from transformers import pipeline
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
# ⭐️ 실제 발급받은 영문/숫자 키를 입력하세요! (따옴표 안에 한글/공백 절대 금지)
SUPABASE_URL = "https://stbdmjcdivkhpqvfegwm.supabase.co"
SUPABASE_KEY = "sb_publishable_Rq50iIhTcIqSufu0AN5EfQ_Nu1G4elc"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

OLLAMA_API_URL = "http://localhost:11434/api/generate"
MAIN_MODEL = "qwen2.5:7b"

# 프롬프트 인젝션 방어 모델 로드
print("🛡️ [보안] ProtectAI 인젝션 방어 모델 로딩 중...")
try:
    guardrail = pipeline("text-classification", model="protectai/deberta-v3-base-prompt-injection-v2")
    print("✅ [보안] Guardrail 모델 로딩 완료!")
except Exception as e:
    print(f"❌ [에러] 모델 로딩 실패: {e}")
    exit(1)

# 한국어 특화 악성 지시어 정규식 패턴
INJECTION_PATTERNS = [
    r"이전 지시", r"무시하고", r"시스템 프롬프트", r"초기 설정", 
    r"명령어\s*출력", r"너의 목적", r"너의 역할", r"개발자 모드", r"탈옥"
]

def is_heuristic_injection(text):
    for pattern in INJECTION_PATTERNS:
        if re.search(pattern, text, re.IGNORECASE):
            return True
    return False

# =====================================================================
# [DB 검색 함수] - 테이블 스키마 완벽 반영 버전
# ========================================== ===========================
def search_restaurants(keywords, top_n=10):
    if not keywords:
        # 키워드가 없으면 활성화된(is_active=True) 식당 중 아무거나 가져옴
        res = supabase.table('stores').select('*').eq('is_active', True).limit(top_n).execute()
        return res.data
    
    all_matched_records = []
    
    # 1. 일반 텍스트 컬럼(name, category, description)만 DB에 직접 검색 요청
    # (tags, features는 text[] 배열이라 DB 에러 방지를 위해 아래 파이썬에서 처리)
    for kw in keywords:
        query_str = f"name.ilike.%{kw}%,category.ilike.%{kw}%,description.ilike.%{kw}%"
        res = supabase.table('stores').select('*').eq('is_active', True).or_(query_str).execute()
        all_matched_records.extend(res.data)
        
    # 2. 중복된 가게 제거 및 매칭 점수(Score) 기초 세팅
    unique_stores = {}
    for store in all_matched_records:
        store_id = store.get('id')
        if store_id not in unique_stores:
            unique_stores[store_id] = store
            unique_stores[store_id]['score'] = 0
            
    # 검색된 게 없으면 활성화된 목록 기본 반환
    if not unique_stores: 
        return supabase.table('stores').select('*').eq('is_active', True).limit(top_n).execute().data
        
    # 3. 파이썬 내부에서 배열(text[])까지 포함하여 정밀 점수 계산
    for store_id, store in unique_stores.items():
        name = store.get('name') or ''
        category = store.get('category') or ''
        desc = store.get('description') or ''
        tags = store.get('tags') or []       # 배열(List) 형태
        features = store.get('features') or [] # 배열(List) 형태
        
        search_text = f"{name} {category} {desc}"
        
        for kw in keywords:
            # 3-1. 텍스트 정보에 키워드가 있는 경우
            if kw in search_text:
                store['score'] += 1
            # 3-2. 배열(tags, features) 안에 키워드가 포함된 경우
            if any(kw in tag for tag in tags) or any(kw in feat for feat in features):
                store['score'] += 1
                
    # 4. 점수가 높은 순으로 정렬해서 상위 N개만 잘라냄
    sorted_stores = sorted(unique_stores.values(), key=lambda x: x['score'], reverse=True)
    return sorted_stores[:top_n]

# =====================================================================
# [API 엔드포인트]
# =====================================================================
@app.route('/api/ai', methods=['POST', 'OPTIONS'])
def process_ai_request():
    if request.method == 'OPTIONS':
        return ('', 204)

    data = request.json
    if not data or 'input' not in data:
        return jsonify({"status": "error", "message": "입력값(input)이 없습니다."}), 400
        
    user_input = data.get('input', '')
    role = data.get('role', 'user')

    print(f"\n--- 📥 [요청 수신] 역할: {role} ---")
    print(f"입력값: {user_input}")

    # [1계층] 보안 검사
    if is_heuristic_injection(user_input):
        return jsonify({"status": "error", "message": "허용되지 않는 명령 패턴이 포함되어 있습니다."}), 400

    gr_result = guardrail(user_input)[0]
    if gr_result['label'] == 'INJECTION' and gr_result['score'] > 0.5:
        return jsonify({"status": "error", "message": "시스템 탈취 지시어가 감지되어 차단되었습니다."}), 400

    # [2계층] 역할별 로직
    kw_json = {}
    if role == 'user':
        # [Step 1] 키워드 추출
        print("⏳ [1단계] 상황 분석 및 조건/키워드 추출 중...")
        keyword_prompt = f"""너는 맛집 검색용 조건 및 키워드 추출기다.
사용자의 상황을 분석해서 위치, 예산, 시간대, 상황 정보와 검색에 쓸 핵심 단어(메뉴, 분위기 등)를 2~4개만 뽑아라.
사용자 입력에 특정 정보가 명시되어 있지 않다면 "정보 없음"이라고 기입해라.
반드시 아래 JSON 스키마로만 답변해라.
{{"location": "위치 정보", "budget": "예산 정보", "time": "시간대 정보", "situation": "상황 정보", "keywords": ["키워드1", "키워드2"]}}

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
            print(f"✅ [키워드 추출 완료] {keywords}, 조건: {kw_json}")
        except Exception:
            kw_json = {}
            keywords = []

        # [Step 2] 스키마에 맞춘 DB 검색
        print("🔍 [2단계] Supabase DB 검색 중...")
        top_restaurants = search_restaurants(keywords, top_n=10)
        
        # 검색된 데이터를 AI가 읽을 수 있도록 문자열로 조립
        db_context = []
        for r in top_restaurants:
            # 배열(list) 데이터를 문자열로 예쁘게 묶어줌
            tags_str = ", ".join(r.get('tags') or [])
            features_str = ", ".join(r.get('features') or [])
            
            info = f"가게명: {r.get('name', '')} | 업종: {r.get('category', '')} | 설명: {r.get('description', '')} | 태그: {tags_str} | 특징: {features_str} | 주소: {r.get('address', '')}"
            db_context.append(info)
            
        db_context_str = "\n".join(db_context)
        print(f"✅ [검색 완료] {len(top_restaurants)}개의 후보 발견")

        # [Step 3] 최종 프롬프트 생성
        system_prompt = f"""너는 대전·충청권 로컬마켓 서비스 '동네U'의 맛집 추천 AI다.
사용자의 상황에 깊이 공감해주며, **반드시 아래 제공된 [DB 검색 후보] 안에서만 가장 어울리는 3곳을 골라 추천해라.**
가상의 식당을 절대 지어내면 안 된다.

[DB 검색 후보]
{db_context_str}

반드시 아래 JSON 스키마 형식으로만 답변해라.
{{"recommendations": [{{"card_type": "동네U추천", "store_name": "가게이름", "reason": "사용자 상황에 맞춘 추천 이유 (가게명이나 메뉴 언급)"}}]}}"""
        
        isolated_prompt = f"{system_prompt}\n\n<user_input>\n{user_input}\n</user_input>"
        
    elif role == 'owner':
        system_prompt = """너는 소상공인을 돕는 '동네U'의 마케터 AI다.
사장님이 입력한 메뉴와 가게 특징을 바탕으로 자연스러운 인스타그램 홍보 문구와 해시태그를 생성해라.
반드시 아래 JSON 스키마 형식으로만 답변해라.
{"marketing": {"post_text": "홍보문구 본문", "hashtags": ["#태그1", "#태그2"]}}"""
        isolated_prompt = f"{system_prompt}\n\n<owner_input>\n{user_input}\n</owner_input>"
    else:
        return jsonify({"status": "error", "message": "잘못된 권한입니다."}), 400

    # [3계층] 최종 Ollama 호출
    print("⏳ [메인 LLM] 최종 응답 생성 중...")
    try:
        response = requests.post(OLLAMA_API_URL, json={
            "model": MAIN_MODEL,
            "prompt": isolated_prompt,
            "format": "json", 
            "stream": False,
            "options": {"temperature": 0.7} 
        }, timeout=45)
        response.raise_for_status()
        llm_output = response.json().get('response', '')
    except Exception as e:
        print(f"❌ [에러] Ollama 서버 통신 실패: {e}")
        return jsonify({"status": "error", "message": "AI 추론 서버(Ollama) 통신 에러."}), 500

    # [4계층] 결과 반환
    try:
        parsed_result = json.loads(llm_output)
        if "동네U의 맛집 추천 AI" in llm_output or "DB 검색 후보" in llm_output:
            raise ValueError("민감 지시어 유출")
            
        if role == 'user' and kw_json:
            parsed_result['conditions'] = kw_json
            
        print("✅ [완료] 응답 반환 성공")
        return jsonify({"status": "success", "data": parsed_result})
    except Exception:
        return jsonify({"status": "error", "message": "AI 응답 파싱 실패."}), 500

if __name__ == '__main__':
    print("\n🚀 동네U AI 서버(Supabase 스키마 완벽 연동) 시작 - 포트 5000")
    app.run(host='0.0.0.0', port=5000)