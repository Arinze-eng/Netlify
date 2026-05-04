-- Telegram-like chat features migration
-- Applied to Supabase project: ljnparociyyggmxdewwv
-- Applied at: 2026-04-30 (Asia/Shanghai)

-- 1) Per-user blocks (block someone from messaging you)
create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

alter table public.user_blocks enable row level security;

drop policy if exists "Users can view own blocks" on public.user_blocks;
create policy "Users can view own blocks" on public.user_blocks
for select to authenticated
using (auth.uid() = blocker_id);

drop policy if exists "Users can block" on public.user_blocks;
create policy "Users can block" on public.user_blocks
for insert to authenticated
with check (auth.uid() = blocker_id and blocker_id <> blocked_id);

drop policy if exists "Users can unblock" on public.user_blocks;
create policy "Users can unblock" on public.user_blocks
for delete to authenticated
using (auth.uid() = blocker_id);

-- 2) Message metadata: reply, edits, soft deletes, captions
alter table public.messages
  add column if not exists reply_to_id bigint references public.messages(id) on delete set null,
  add column if not exists edited_at timestamptz,
  add column if not exists deleted_at timestamptz,
  add column if not exists deleted_for_sender boolean not null default false,
  add column if not exists deleted_for_receiver boolean not null default false,
  add column if not exists caption text;

-- 3) Tighten messaging policies (remove hard delete, add block checks, split update rules)
drop policy if exists "Users can delete own sent messages" on public.messages;

drop policy if exists "Users can send messages" on public.messages;
create policy "Users can send messages" on public.messages
for insert to authenticated
with check (
  auth.uid() = sender_id
  and exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_blocked = false)
  and not exists (
    select 1 from public.user_blocks b
    where (b.blocker_id = receiver_id and b.blocked_id = sender_id)
       or (b.blocker_id = sender_id and b.blocked_id = receiver_id)
  )
);

drop policy if exists "Users can update own sent messages" on public.messages;
create policy "Users can update own sent messages" on public.messages
for update to authenticated
using (auth.uid() = sender_id)
with check (auth.uid() = sender_id);

drop policy if exists "Users can update like status on received messages" on public.messages;
create policy "Users can update received message flags" on public.messages
for update to authenticated
using (auth.uid() = receiver_id)
with check (auth.uid() = receiver_id);

drop policy if exists "Users can view their own messages" on public.messages;
create policy "Users can view their own messages" on public.messages
for select to authenticated
using (auth.uid() = sender_id or auth.uid() = receiver_id);

-- 4) Realtime
alter publication supabase_realtime add table public.user_blocks;
