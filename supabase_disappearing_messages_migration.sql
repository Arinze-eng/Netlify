-- Disappearing / view-once message metadata migration
-- Applied to Supabase project: ljnparociyyggmxdewwv

alter table public.messages
  add column if not exists expires_at timestamptz,
  add column if not exists view_once boolean not null default false,
  add column if not exists viewed_by_sender boolean not null default false,
  add column if not exists viewed_by_receiver boolean not null default false;

create index if not exists messages_expires_at_idx on public.messages(expires_at);
