# DongNeU Supabase

이 폴더는 Supabase 데이터베이스 초기 구성을 위한 SQL 파일만 담습니다.

## 실행 순서

Supabase Dashboard의 SQL Editor에서 아래 순서대로 실행합니다.

1. `schema.sql`
2. `policies.sql`
3. `seed.sql`

## 파일 역할

- `schema.sql`: 테이블, 인덱스, updated_at trigger 생성
- `policies.sql`: RLS 활성화와 접근 정책 생성
- `seed.sql`: 궁동/충남대 주변 샘플 가게와 메뉴 데이터 삽입

## 앱에서 사용하는 테이블

- `profiles`: Auth 사용자 역할 저장 (`customer`, `owner`, `admin`)
- `stores`: 홈 가게 목록, 상세 화면, 사장님 등록 가게
- `menu_items`: 가게 상세 메뉴와 사장님 메뉴 등록
- `saved_stores`: 손님 가게 저장/해제
- `recommendation_history`: Flask 사용자 추천 요청과 응답 기록
- `promotion_history`: Flask 사장님 홍보 문구 생성 기록

## 추천 기록 보호 정책

`recommendation_history`는 DB trigger로 사용자당 분당 20개까지만 insert를 허용합니다.
새 기록이 저장될 때마다 같은 사용자의 기록은 최신 100개 중 최근 90일 이내 기록만 남기고 정리됩니다.
RLS 정책은 로그인한 사용자가 자신의 `user_id`로만 추천 기록을 insert할 수 있게 제한합니다.

## 권한 보호 정책

`profiles.role`은 사용자가 직접 `admin`으로 바꿀 수 없고, 손님(`customer`) 또는 사장님(`owner`)만 선택할 수 있습니다.
가게와 메뉴 등록/수정/삭제, 홍보 문구 저장은 `profiles.role`이 `owner` 또는 `admin`인 사용자만 가능합니다.
`promotion_history`도 사용자당 분당 20개까지만 insert를 허용하고, 최신 100개 중 최근 90일 이내 기록만 남깁니다.

Flutter 앱은 `SUPABASE_URL`, `SUPABASE_ANON_KEY`를 `--dart-define`으로 받아 anon client로 접근합니다.
Flask AI 서버는 현재 DB write를 하지 않고, Flutter 앱이 Flask 응답을 Supabase에 저장합니다.

## 주의

- `policies.sql` 실행 후에는 anon key로도 RLS 정책이 적용됩니다.
- `seed.sql`은 Dashboard SQL Editor에서 실행하는 것을 전제로 합니다.
- Flask 서버가 service role key를 사용하면 RLS를 우회할 수 있으므로, service role key는 서버 환경변수에만 보관합니다.
