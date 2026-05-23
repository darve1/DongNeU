alter table public.profiles enable row level security;
alter table public.stores enable row level security;
alter table public.menu_items enable row level security;
alter table public.saved_stores enable row level security;
alter table public.recommendation_history enable row level security;
alter table public.promotion_history enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles
for select
using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles
for insert
with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "stores_select_active" on public.stores;
create policy "stores_select_active"
on public.stores
for select
using (is_active = true);

drop policy if exists "stores_insert_owner" on public.stores;
create policy "stores_insert_owner"
on public.stores
for insert
with check (auth.uid() = owner_id);

drop policy if exists "stores_update_owner" on public.stores;
create policy "stores_update_owner"
on public.stores
for update
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists "stores_delete_owner" on public.stores;
create policy "stores_delete_owner"
on public.stores
for delete
using (auth.uid() = owner_id);

drop policy if exists "menu_items_select_active_store" on public.menu_items;
create policy "menu_items_select_active_store"
on public.menu_items
for select
using (
  exists (
    select 1
    from public.stores s
    where s.id = menu_items.store_id
      and s.is_active = true
  )
);

drop policy if exists "menu_items_insert_store_owner" on public.menu_items;
create policy "menu_items_insert_store_owner"
on public.menu_items
for insert
with check (
  exists (
    select 1
    from public.stores s
    where s.id = menu_items.store_id
      and s.owner_id = auth.uid()
  )
);

drop policy if exists "menu_items_update_store_owner" on public.menu_items;
create policy "menu_items_update_store_owner"
on public.menu_items
for update
using (
  exists (
    select 1
    from public.stores s
    where s.id = menu_items.store_id
      and s.owner_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.stores s
    where s.id = menu_items.store_id
      and s.owner_id = auth.uid()
  )
);

drop policy if exists "menu_items_delete_store_owner" on public.menu_items;
create policy "menu_items_delete_store_owner"
on public.menu_items
for delete
using (
  exists (
    select 1
    from public.stores s
    where s.id = menu_items.store_id
      and s.owner_id = auth.uid()
  )
);

drop policy if exists "saved_stores_select_own" on public.saved_stores;
create policy "saved_stores_select_own"
on public.saved_stores
for select
using (auth.uid() = user_id);

drop policy if exists "saved_stores_insert_own" on public.saved_stores;
create policy "saved_stores_insert_own"
on public.saved_stores
for insert
with check (auth.uid() = user_id);

drop policy if exists "saved_stores_delete_own" on public.saved_stores;
create policy "saved_stores_delete_own"
on public.saved_stores
for delete
using (auth.uid() = user_id);

drop policy if exists "recommendation_history_select_own"
on public.recommendation_history;
create policy "recommendation_history_select_own"
on public.recommendation_history
for select
using (auth.uid() = user_id);

drop policy if exists "recommendation_history_insert_own"
on public.recommendation_history;
create policy "recommendation_history_insert_own"
on public.recommendation_history
for insert
with check (auth.uid() = user_id or user_id is null);

drop policy if exists "promotion_history_select_own"
on public.promotion_history;
create policy "promotion_history_select_own"
on public.promotion_history
for select
using (auth.uid() = owner_id);

drop policy if exists "promotion_history_insert_own"
on public.promotion_history;
create policy "promotion_history_insert_own"
on public.promotion_history
for insert
with check (auth.uid() = owner_id or owner_id is null);
