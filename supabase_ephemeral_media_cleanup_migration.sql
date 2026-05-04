-- Ephemeral media cleanup: make Supabase Storage a transfer layer
-- Applied to Supabase project: ljnparociyyggmxdewwv
-- Created at: 2026-04-30 (Asia/Shanghai)

create or replace function public.delete_chat_media_for_message(p_message_id bigint)
returns void
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  m record;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select id, sender_id, receiver_id, media_path
    into m
  from public.messages
  where id = p_message_id;

  if not found then
    return;
  end if;

  if auth.uid() <> m.sender_id and auth.uid() <> m.receiver_id then
    raise exception 'Not allowed';
  end if;

  if m.media_path is null or btrim(m.media_path) = '' then
    return;
  end if;

  -- delete the object (best-effort)
  delete from storage.objects
  where bucket_id = 'chat_media'
    and name = m.media_path;
end;
$$;

grant execute on function public.delete_chat_media_for_message(bigint) to authenticated;
