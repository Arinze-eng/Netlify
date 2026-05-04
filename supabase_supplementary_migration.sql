-- Supplementary migration: missing columns for group_messages
-- Project: ljnparociyyggmxdewwv

-- Add forwarded/starred columns to group_messages
alter table public.group_messages
  add column if not exists is_forwarded boolean not null default false,
  add column if not exists forwarded_from_id uuid references public.profiles(id),
  add column if not exists is_starred boolean not null default false,
  add column if not exists edited_at timestamptz;

-- Add edited_at to messages
alter table public.messages
  add column if not exists edited_at timestamptz;

-- Add view_once to group_messages
alter table public.group_messages
  add column if not exists view_once boolean not null default false,
  add column if not exists viewed_by text[] default '{}';
