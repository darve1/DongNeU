import os
from flask import Flask, request, jsonify
import requests
import json
import re
from transformers import pipeline

app = Flask(__name__)

# =====================================================================
# [초기화 설정]
# =====================================================================
OLLAMA_API_URL = "http://localhost:11434/api/generate"
MAIN_MODEL = "qwen2.5:7b"

# 1. 프롬프트 인젝션 방어 모델 로드 (완전 개방형 오픈소스 모델 사용)
print("🛡️ [보안] ProtectAI 인젝션 방어 모델 로딩 중 (잠시만 기다려주세요)...")
try:
    # Meta 모델 대신 토큰이 필요 없는 ProtectAI 모델 적용
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
# [API 엔드포인트]
# =====================================================================
@app.route('/api/ai', methods=['POST'])
def process_ai_request():
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
    # 1-1. 빠르고 가벼운 정규식 검사
    if is_heuristic_injection(user_input):
        print("🚫 [차단] 휴리스틱 인젝션 패턴 감지됨")
        return jsonify({"status": "error", "message": "허용되지 않는 명령 패턴이 포함되어 있습니다."}), 400

    # 1-2. AI 모델 기반 인젝션/탈옥 검사
    gr_result = guardrail(user_input)[0]
    label = gr_result['label']
    score = gr_result['score']
    
    print(f"🔍 [Guardrail 검사] 결과: {label} (확신도: {score:.2f})")
    
    # ProtectAI 모델은 'SAFE' 또는 'INJECTION'을 반환합니다.
    if label == 'INJECTION' and score > 0.5:
        print("🚫 [차단] 악성 프롬프트 인젝션/탈옥 감지됨")
        return jsonify({"status": "error", "message": "시스템 탈취 및 비정상적인 지시어가 감지되어 요청이 차단되었습니다."}), 400

    # ---------------------------------------------------------
    # 📦 [2계층] Context Isolation (도메인 샌드박싱)
    # ---------------------------------------------------------
    if role == 'user':
        system_prompt = """너는 대전·충청권 로컬마켓 활성화 서비스 '동네U'의 맛집 추천 AI다.
사용자의 위치, 예산, 상황을 분석하여 가장 알맞은 가게 3곳을 추천해라.
반드시 아래 JSON 스키마 형식으로만 답변하고, 다른 말은 절대 추가하지 마라.
{"recommendations": [{"card_type": "가까워U", "store_name": "가게이름", "reason": "추천이유"}, ...]}"""
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
    # 🧠 [3계층] 메인 LLM 추론 (Ollama 호출)
    # ---------------------------------------------------------
    print("⏳ [메인 LLM] Ollama 추론 진행 중...")
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
        response = requests.post(OLLAMA_API_URL, json=payload, timeout=30)
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
        
        if "동네U의 맛집 추천 AI" in llm_output or "JSON 스키마" in llm_output:
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