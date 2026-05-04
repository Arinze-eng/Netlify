-- Typing indicator support
-- Project: ljnparociyyggmxdewwv

create table if not exists public.typing_events (
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  is_typing boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (sender_id, receiver_id)
);

alter table public.typing_events enable row level security;

drop policy if exists "Users can upsert own typing" on public.typing_events;
create policy "Users can upsert own typing" on public.typing_events
for insert to authenticated
with check (auth.uid() = sender_id);

drop policy if exists "Users can update own typing" on public.typing_events;
create policy "Users can update own typing" on public.typing_events
for update to authenticated
using (auth.uid() = sender_id)
with check (auth.uid() = sender_id);

drop policy if exists "Users can read typing" on public.typing_events;
create policy "Users can read typing" on public.typing_events
for select to authenticated
using (auth.uid() = sender_id or auth.uid() = receiver_id);

create or replace function public.set_typing(p_receiver_id uuid, p_is_typing boolean)
returns void
language plpgsql
as $$
begin
  insert into public.typing_events (sender_id, receiver_id, is_typing, updated_at)
  values (auth.uid(), p_receiver_id, coalesce(p_is_typing,false), now())
  on conflict (sender_id, receiver_id)
  do update set is_typing = excluded.is_typing, updated_at = excluded.updated_at;
end;
$$;

grant execute on function public.set_typing(uuid, boolean) to authenticated;

alter publication supabase_realtime add table public.typing_events;
