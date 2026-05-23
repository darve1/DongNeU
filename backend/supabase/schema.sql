create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  role text not null default 'customer'
    check (role in ('customer', 'owner', 'admin')),
  current_location text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.profiles(id) on delete set null,
  name text not null,
  category text not null,
  address text not null,
  lat double precision,
  lng double precision,
  description text,
  image_url text,
  rating numeric(2,1) not null default 0,
  review_count integer not null default 0,
  price_range text,
  opening_hours text,
  phone text,
  tags text[] not null default '{}',
  features text[] not null default '{}',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  name text not null,
  description text,
  price integer not null default 0 check (price >= 0),
  image_url text,
  is_representative boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.saved_stores (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, store_id)
);

create table if not exists public.recommendation_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  query text not null,
  location_text text,
  budget text,
  situation text,
  keywords text[] not null default '{}',
  candidate_store_ids uuid[] not null default '{}',
  result_store_ids uuid[] not null default '{}',
  ai_response jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.enforce_recommendation_history_limits()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recent_insert_count integer;
begin
  if new.user_id is null then
    raise exception 'recommendation_history.user_id is required';
  end if;

  if auth.uid() is not null and new.user_id <> auth.uid() then
    raise exception 'cannot insert recommendation history for another user';
  end if;

  select count(*)
  into recent_insert_count
  from public.recommendation_history
  where user_id = new.user_id
    and created_at >= now() - interval '1 minute';

  if recent_insert_count >= 20 then
    raise exception 'recommendation history rate limit exceeded';
  end if;

  return new;
end;
$$;

create or replace function public.prune_recommendation_history()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.recommendation_history
  where user_id = new.user_id
    and (
      created_at < now() - interval '90 days'
      or id in (
        select id
        from (
          select
            id,
            row_number() over (
              partition by user_id
              order by created_at desc, id desc
            ) as row_num
          from public.recommendation_history
          where user_id = new.user_id
        ) ranked
        where row_num > 100
      )
    );

  return null;
end;
$$;

create table if not exists public.promotion_history (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  store_id uuid references public.stores(id) on delete set null,
  promotion_type text not null
    check (promotion_type in ('sns', 'description', 'coupon')),
  event_text text,
  keywords text[] not null default '{}',
  tone text,
  generated_copy text not null,
  created_at timestamptz not null default now()
);

create or replace function public.enforce_promotion_history_limits()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recent_insert_count integer;
begin
  if new.owner_id is null then
    raise exception 'promotion_history.owner_id is required';
  end if;

  if auth.uid() is not null and new.owner_id <> auth.uid() then
    raise exception 'cannot insert promotion history for another owner';
  end if;

  select count(*)
  into recent_insert_count
  from public.promotion_history
  where owner_id = new.owner_id
    and created_at >= now() - interval '1 minute';

  if recent_insert_count >= 20 then
    raise exception 'promotion history rate limit exceeded';
  end if;

  return new;
end;
$$;

create or replace function public.prune_promotion_history()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.promotion_history
  where owner_id = new.owner_id
    and (
      created_at < now() - interval '90 days'
      or id in (
        select id
        from (
          select
            id,
            row_number() over (
              partition by owner_id
              order by created_at desc, id desc
            ) as row_num
          from public.promotion_history
          where owner_id = new.owner_id
        ) ranked
        where row_num > 100
      )
    );

  return null;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_stores_updated_at on public.stores;
create trigger set_stores_updated_at
before update on public.stores
for each row execute function public.set_updated_at();

drop trigger if exists set_menu_items_updated_at on public.menu_items;
create trigger set_menu_items_updated_at
before update on public.menu_items
for each row execute function public.set_updated_at();

drop trigger if exists enforce_recommendation_history_limits
on public.recommendation_history;
create trigger enforce_recommendation_history_limits
before insert on public.recommendation_history
for each row execute function public.enforce_recommendation_history_limits();

drop trigger if exists prune_recommendation_history
on public.recommendation_history;
create trigger prune_recommendation_history
after insert on public.recommendation_history
for each row execute function public.prune_recommendation_history();

drop trigger if exists enforce_promotion_history_limits
on public.promotion_history;
create trigger enforce_promotion_history_limits
before insert on public.promotion_history
for each row execute function public.enforce_promotion_history_limits();

drop trigger if exists prune_promotion_history
on public.promotion_history;
create trigger prune_promotion_history
after insert on public.promotion_history
for each row execute function public.prune_promotion_history();

create index if not exists idx_stores_owner_id on public.stores(owner_id);
create index if not exists idx_stores_category on public.stores(category);
create index if not exists idx_stores_is_active on public.stores(is_active);
create index if not exists idx_stores_rating on public.stores(rating desc);
create index if not exists idx_stores_tags_gin on public.stores using gin(tags);
create index if not exists idx_stores_features_gin
  on public.stores using gin(features);
create index if not exists idx_menu_items_store_id
  on public.menu_items(store_id);
create index if not exists idx_saved_stores_user_id
  on public.saved_stores(user_id);
create index if not exists idx_saved_stores_store_id
  on public.saved_stores(store_id);
create index if not exists idx_recommendation_history_user_created
  on public.recommendation_history(user_id, created_at desc);
create index if not exists idx_promotion_history_owner_created
  on public.promotion_history(owner_id, created_at desc);
