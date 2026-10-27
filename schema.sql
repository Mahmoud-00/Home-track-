-- نفّذ هذا الملف في Supabase Dashboard > SQL Editor.
-- الجداول وسياسات RLS مصممة بحيث يرى المستخدم بياناته فقط.
create extension if not exists pgcrypto;

create table if not exists public.items (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
  unit text not null default 'قطعة',
  notes text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.cycles (
  id uuid primary key,
  item_id uuid not null references public.items(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  purchase_date date not null,
  depleted_date date null,
  quantity numeric not null check (quantity > 0),
  unit text not null,
  notes text not null default '',
  constraint valid_cycle_dates check (depleted_date is null or depleted_date >= purchase_date)
);

create index if not exists items_user_id_idx on public.items(user_id);
create index if not exists cycles_user_id_idx on public.cycles(user_id);
create index if not exists cycles_item_id_idx on public.cycles(item_id);

alter table public.items enable row level security;
alter table public.cycles enable row level security;

drop policy if exists "Users manage own items" on public.items;
create policy "Users manage own items" on public.items
for all to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own cycles" on public.cycles;
create policy "Users manage own cycles" on public.cycles
for all to authenticated
using (auth.uid() = user_id)
with check (
  auth.uid() = user_id
  and exists (select 1 from public.items i where i.id = item_id and i.user_id = auth.uid())
);
