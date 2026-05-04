-- Privacy settings: hide last seen, hide read receipts
-- Project: ljnparociyyggmxdewwv

alter table public.profiles
  add column if not exists hide_last_seen boolean not null default false,
  add column if not exists hide_read_receipts boolean not null default false;

-- Harden last_seen updates: only update if user does not hide last seen
create or replace function public.touch_last_seen()
returns void
language plpgsql
as $$
begin
  update public.profiles
  set last_seen = now()
  where id = auth.uid()
    and coalesce(hide_last_seen,false) = false;
end;
$$;

grant execute on function public.touch_last_seen() to authenticated;
