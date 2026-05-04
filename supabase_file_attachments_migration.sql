-- File attachments metadata
-- Project: ljnparociyyggmxdewwv

alter table public.messages
  add column if not exists media_name text,
  add column if not exists media_size_bytes bigint;

create index if not exists messages_media_name_idx on public.messages(media_name);
