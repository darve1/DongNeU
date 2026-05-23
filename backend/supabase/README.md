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

## 주의

- `policies.sql` 실행 후에는 anon key로도 RLS 정책이 적용됩니다.
- `seed.sql`은 Dashboard SQL Editor에서 실행하는 것을 전제로 합니다.
- Flask 서버가 service role key를 사용하면 RLS를 우회할 수 있으므로, service role key는 서버 환경변수에만 보관합니다.
