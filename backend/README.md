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
  --dart-define=FLASK_AI_BASE_URL=http://127.0.0.1:5000 `
  --dart-define=KAKAO_REST_API_KEY=<kakao-rest-api-key>
```

`SUPABASE_SERVICE_ROLE_KEY`, AI API key, Flask 내부 secret은 Flutter 앱에 넣지 않습니다.

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
3. Kakao 주소 검색 결과로 `stores` 등록
4. 대표 메뉴와 추가 메뉴를 `menu_items`에 저장
5. Flask `POST /api/ai`에 `role=owner`로 홍보 문구 요청
6. 생성 결과를 `promotion_history`에 저장

## 배포 전 체크리스트

- Supabase Dashboard에서 `schema.sql`, `policies.sql`, `seed.sql` 순서로 실행
- Auth Email provider 설정 확인
- Flask 서버 CORS 허용 도메인 제한
- Flask 서버에 Supabase access token 검증 추가
- service role key는 서버 환경변수에만 보관
