# DongNeU Backend

DongNeU의 1차 백엔드는 Supabase와 기존 Flask AI 서버를 함께 사용합니다.

## 구성

- `backend/supabase/schema.sql`: Supabase 테이블, 인덱스, trigger
- `backend/supabase/policies.sql`: RLS 정책
- `backend/supabase/seed.sql`: 충남대/궁동 샘플 가게와 메뉴
- `backend/supabase/README.md`: Supabase SQL 실행 순서
- `ai-server/app.py`: 기존 Flask AI 서버

## Flutter 실행 환경값

Flutter 앱에는 public client 값만 넣습니다.

```powershell
flutter run `
  --dart-define=SUPABASE_URL=<supabase-url> `
  --dart-define=SUPABASE_ANON_KEY=<supabase-anon-or-publishable-key> `
  --dart-define=FLASK_AI_BASE_URL=http://127.0.0.1:5000
```

`SUPABASE_SERVICE_ROLE_KEY`, AI API key, Flask 내부 secret, Kakao REST API key는 Flutter 앱에 넣지 않습니다.

## Flask AI 서버 보안 설정

Flask AI 서버는 환경변수에서 설정을 읽습니다. 예시는 `ai-server/.env.example`을 참고합니다.

- `SUPABASE_URL`, `SUPABASE_ANON_KEY`: Supabase 사용자 토큰 검증과 공개 가게 조회에 사용
- `KAKAO_REST_API_KEY`: 사장님 주소 검색 프록시에 사용하며 Flutter 앱에 노출하지 않음
- `CORS_ORIGINS`: Flutter 개발/배포 origin만 쉼표로 허용
- `HOST`: 로컬 개발은 `127.0.0.1`, 외부 공개가 필요할 때만 프록시 뒤에서 별도 설정
- `RATE_LIMIT_REQUESTS`, `RATE_LIMIT_WINDOW_SECONDS`: 사용자/IP 기준 요청 제한

Flutter는 Flask `POST /api/ai`, `GET /api/address/search` 요청에 Supabase access token을 `Authorization: Bearer <token>`으로 보냅니다.
Flask 서버는 요청 body의 `role`을 그대로 믿지 않고, Supabase `profiles.role`을 조회해 손님/사장님 권한을 확인합니다.

## 데이터 흐름

손님:

1. Supabase Auth로 로그인/회원가입
2. `profiles.role = customer` 저장
3. `stores`와 `menu_items` 조회
4. Flask `POST /api/ai`에 `role=user`로 추천 요청
5. 추천 결과를 `recommendation_history`에 저장
6. 가게 저장/해제는 `saved_stores`에 반영

사장님:

1. Supabase Auth로 로그인/회원가입
2. `profiles.role = owner` 저장
3. Flask 주소 검색 프록시 결과로 `stores` 등록
4. 대표 메뉴와 추가 메뉴를 `menu_items`에 저장
5. Flask `POST /api/ai`에 `role=owner`로 홍보 문구 요청
6. 생성 결과를 `promotion_history`에 저장

## 배포 전 체크리스트

- Supabase Dashboard에서 `schema.sql`, `policies.sql`, `seed.sql` 순서로 실행
- Auth Email provider 설정 확인
- Flask 서버 CORS 허용 도메인 제한
- Flask 서버에 Supabase access token 검증 적용 확인
- service role key는 서버 환경변수에만 보관
