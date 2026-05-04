-- WebRTC signaling via Supabase

create table if not exists public.call_signals (
  id uuid primary key default gen_random_uuid(),
  from_id uuid not null references public.profiles(id) on delete cascade,
  to_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  payload jsonb not null,
  created_at timestamptz not null default now()
);

alter table public.call_signals enable row level security;

drop policy if exists "call_signals_insert_own" on public.call_signals;
create policy "call_signals_insert_own" on public.call_signals
for insert to authenticated
with check (auth.uid() = from_id);

drop policy if exists "call_signals_select_own" on public.call_signals;
create policy "call_signals_select_own" on public.call_signals
for select to authenticated
using (auth.uid() = to_id or auth.uid() = from_id);

drop policy if exists "call_signals_delete_own" on public.call_signals;
create policy "call_signals_delete_own" on public.call_signals
for delete to authenticated
using (auth.uid() = from_id);

alter publication supabase_realtime add table public.call_signals;
