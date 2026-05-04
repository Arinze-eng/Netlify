-- Feature migration: Status, Group Admin, View-Once, Rich Text, Pinned messages sort
-- Project: ljnparociyyggmxdewwv

-- ============================================================
-- 1) WHATSAPP STATUS (stories) - 19hr auto-delete
-- ============================================================
create table if not exists public.status (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  status_type text not null default 'text', -- 'text' or 'image'
  content text, -- text content or image caption
  media_path text, -- Supabase storage path for image
  media_mime text,
  background_color text default '#6366F1', -- background color for text status
  is_bold boolean not null default false, -- bold text status
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '19 hours')
);

alter table public.status enable row level security;

drop policy if exists "Users can view status" on public.status;
create policy "Users can view status" on public.status
for select to authenticated
using (
  -- Can see own status
  user_id = auth.uid()
  -- Can see status of users who haven't excluded us (no exclusion entry)
  or not exists (
    select 1 from public.status_privacy sp
    where sp.user_id = status.user_id
      and sp.excluded_user_id = auth.uid()
  )
);

drop policy if exists "Users can create status" on public.status;
create policy "Users can create status" on public.status
for insert to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own status" on public.status;
create policy "Users can delete own status" on public.status
for delete to authenticated
using (auth.uid() = user_id);

-- Status privacy: who can see my status
create table if not exists public.status_privacy (
  user_id uuid not null references public.profiles(id) on delete cascade,
  excluded_user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, excluded_user_id)
);

alter table public.status_privacy enable row level security;

drop policy if exists "Users can manage own status privacy" on public.status_privacy;
create policy "Users can manage own status privacy" on public.status_privacy
for all to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Status views (who viewed my status)
create table if not exists public.status_views (
  status_id uuid not null references public.status(id) on delete cascade,
  viewer_id uuid not null references public.profiles(id) on delete cascade,
  viewed_at timestamptz not null default now(),
  primary key (status_id, viewer_id)
);

alter table public.status_views enable row level security;

drop policy if exists "Users can view status views" on public.status_views;
create policy "Users can view status views" on public.status_views
for select to authenticated
using (
  -- Status owner can see who viewed their status
  exists (select 1 from public.status s where s.id = status_id and s.user_id = auth.uid())
  -- Or you are the viewer
  or viewer_id = auth.uid()
);

drop policy if exists "Users can insert status view" on public.status_views;
create policy "Users can insert status view" on public.status_views
for insert to authenticated
with check (auth.uid() = viewer_id);

-- Auto-delete expired status (pg_cron or manual cleanup)
-- We'll handle cleanup in the app, but also add a function
create or replace function public.cleanup_expired_status()
returns void
language plpgsql
as $$
begin
  delete from public.status where expires_at < now();
end;
$$;
grant execute on function public.cleanup_expired_status() to authenticated;

alter publication supabase_realtime add table public.status;
alter publication supabase_realtime add table public.status_views;

-- ============================================================
-- 2) GROUP ADMIN FEATURES - promote/demote admins
-- ============================================================

-- Add role column if not exists (already has 'role' from createGroup)
-- Add group settings columns
alter table public.groups
  add column if not exists only_admins_can_send boolean not null default false,
  add column if not exists only_admins_can_edit_info boolean not null default false;

-- Update group_members RLS for admin operations
-- Add a function to check if user is group admin
create or replace function public.is_group_admin(p_group_id uuid)
returns boolean
language plpgsql
as $$
declare
  v_role text;
begin
  select role into v_role from public.group_members
  where group_id = p_group_id and user_id = auth.uid();
  return v_role = 'admin' or v_role = 'super_admin';
end;
$$;
grant execute on function public.is_group_admin(uuid) to authenticated;

-- Add super_admin support: creator gets super_admin role
-- Function to promote member to admin
create or replace function public.promote_group_admin(p_group_id uuid, p_user_id uuid)
returns void
language plpgsql
as $$
begin
  -- Check if caller is admin
  if not public.is_group_admin(p_group_id) then
    raise exception 'Only admins can promote members';
  end if;
  update public.group_members set role = 'admin'
  where group_id = p_group_id and user_id = p_user_id;
end;
$$;
grant execute on function public.promote_group_admin(uuid, uuid) to authenticated;

-- Function to demote admin to member
create or replace function public.demote_group_admin(p_group_id uuid, p_user_id uuid)
returns void
language plpgsql
as $$
declare
  v_caller_role text;
  v_target_role text;
begin
  -- Get caller role
  select role into v_caller_role from public.group_members
  where group_id = p_group_id and user_id = auth.uid();
  
  -- Get target role
  select role into v_target_role from public.group_members
  where group_id = p_group_id and user_id = p_user_id;
  
  -- Only super_admin can demote admin
  if v_caller_role != 'super_admin' then
    raise exception 'Only group creator can demote admins';
  end if;
  
  if v_target_role = 'super_admin' then
    raise exception 'Cannot demote group creator';
  end if;
  
  update public.group_members set role = 'member'
  where group_id = p_group_id and user_id = p_user_id;
end;
$$;
grant execute on function public.demote_group_admin(uuid, uuid) to authenticated;

-- ============================================================
-- 3) VIEW-ONCE media + RICH TEXT support in messages
-- ============================================================

alter table public.messages
  add column if not exists view_once boolean not null default false,
  add column if not exists viewed_by_sender boolean not null default false,
  add column if not exists viewed_by_receiver boolean not null default false,
  add column if not exists is_rich_text boolean not null default false,
  add column if not exists rich_text_json text, -- JSON: [{"text":"hello","bold":true,"italic":false}]
  add column if not exists media_expires_at timestamptz,
  add column if not exists is_pinned boolean not null default false,
  add column if not exists reactions jsonb default '{}';

-- Same for group_messages
alter table public.group_messages
  add column if not exists is_rich_text boolean not null default false,
  add column if not exists rich_text_json text,
  add column if not exists is_pinned boolean not null default false,
  add column if not exists reactions jsonb default '{}';

-- Update RLS for messages - allow sender to update (for editing, pinning, reactions)
drop policy if exists "Users can update own sent messages" on public.messages;
create policy "Users can update own sent messages" on public.messages
for update to authenticated
using (auth.uid() = sender_id)
with check (auth.uid() = sender_id);

-- ============================================================
-- 4) Forward messages support
-- ============================================================
alter table public.messages
  add column if not exists forwarded_from_id uuid references public.profiles(id),
  add column if not exists is_forwarded boolean not null default false;

-- ============================================================
-- 5) Starred messages
-- ============================================================
alter table public.messages
  add column if not exists is_starred boolean not null default false;

-- ============================================================
-- 6) Profile: online status, avatar, about
-- ============================================================
alter table public.profiles
  add column if not exists avatar_url text,
  add column if not exists about text default 'Hey there! I am using CDN-NETCHAT',
  add column if not exists is_blocked boolean not null default false,
  add column if not exists blocked_reason text,
  add column if not exists blocked_at timestamptz;

-- ============================================================
-- 7) Call history table
-- ============================================================
create table if not exists public.call_history (
  id uuid primary key default gen_random_uuid(),
  caller_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  call_type text not null default 'audio', -- 'audio' or 'video'
  status text not null default 'missed', -- 'missed', 'completed', 'declined'
  duration_seconds integer,
  started_at timestamptz not null default now()
);

alter table public.call_history enable row level security;

drop policy if exists "Users can view own call history" on public.call_history;
create policy "Users can view own call history" on public.call_history
for select to authenticated
using (auth.uid() = caller_id or auth.uid() = receiver_id);

drop policy if exists "Users can insert call history" on public.call_history;
create policy "Users can insert call history" on public.call_history
for insert to authenticated
with check (auth.uid() = caller_id);

alter publication supabase_realtime add table public.call_history;

-- ============================================================
-- 8) Auth events table
-- ============================================================
create table if not exists public.auth_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  event text not null,
  created_at timestamptz not null default now()
);

alter table public.auth_events enable row level security;

-- ============================================================
-- 9) VPN config table
-- ============================================================
create table if not exists public.vpn_config (
  id integer primary key default 1 check (id = 1),
  v2ray_share_link text,
  updated_at timestamptz not null default now()
);

alter table public.vpn_config enable row level security;

-- ============================================================
-- 10) Groups table (ensure all columns exist)
-- ============================================================
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  avatar_url text,
  created_by uuid not null references public.profiles(id) on delete cascade,
  only_admins_can_send boolean not null default false,
  only_admins_can_edit_info boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.group_members (
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member', -- 'member', 'admin', 'super_admin'
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

alter table public.groups enable row level security;
alter table public.group_members enable row level security;

drop policy if exists "Users can view groups" on public.groups;
create policy "Users can view groups" on public.groups
for select to authenticated
using (exists (select 1 from public.group_members gm where gm.group_id = id and gm.user_id = auth.uid()));

drop policy if exists "Users can create groups" on public.groups;
create policy "Users can create groups" on public.groups
for insert to authenticated
with check (auth.uid() = created_by);

drop policy if exists "Admins can update groups" on public.groups;
create policy "Admins can update groups" on public.groups
for update to authenticated
using (public.is_group_admin(id));

-- Group members policies
drop policy if exists "Users can view group members" on public.group_members;
create policy "Users can view group members" on public.group_members
for select to authenticated
using (exists (select 1 from public.group_members gm2 where gm2.group_id = group_id and gm2.user_id = auth.uid()));

drop policy if exists "Admins can add group members" on public.group_members;
create policy "Admins can add group members" on public.group_members
for insert to authenticated
with check (public.is_group_admin(group_id));

drop policy if exists "Admins can remove group members" on public.group_members;
create policy "Admins can remove group members" on public.group_members
for delete to authenticated
using (public.is_group_admin(group_id));

-- Group messages
create table if not exists public.group_messages (
  id bigserial primary key,
  group_id uuid not null references public.groups(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  content text not null default '',
  message_type text not null default 'text',
  media_path text,
  media_mime text,
  media_duration_ms integer,
  media_name text,
  media_size_bytes bigint,
  reply_to_id bigint references public.group_messages(id) on delete set null,
  caption text,
  deleted_at timestamptz,
  media_expires_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.group_messages enable row level security;

drop policy if exists "Group members can view messages" on public.group_messages;
create policy "Group members can view messages" on public.group_messages
for select to authenticated
using (exists (select 1 from public.group_members gm where gm.group_id = group_id and gm.user_id = auth.uid()));

drop policy if exists "Group members can send messages" on public.group_messages;
create policy "Group members can send messages" on public.group_messages
for insert to authenticated
with check (
  auth.uid() = sender_id
  and exists (select 1 from public.group_members gm where gm.group_id = group_id and gm.user_id = auth.uid())
);

drop policy if exists "Sender can update group messages" on public.group_messages;
create policy "Sender can update group messages" on public.group_messages
for update to authenticated
using (auth.uid() = sender_id);

-- RPC: get_my_groups
create or replace function public.get_my_groups()
returns table(
  group_id uuid,
  group_name text,
  group_description text,
  member_count bigint,
  last_message text,
  last_message_at timestamptz
)
language sql
as $$
with my_groups as (
  select gm.group_id
  from public.group_members gm
  where gm.user_id = auth.uid()
),
group_info as (
  select
    g.id as group_id,
    g.name as group_name,
    g.description as group_description,
    (select count(*) from public.group_members gm2 where gm2.group_id = g.id)::bigint as member_count
  from public.groups g
  where g.id in (select group_id from my_groups)
),
last_msgs as (
  select
    group_id,
    content as last_message,
    created_at as last_message_at,
    row_number() over (partition by group_id order by created_at desc) as rn
  from public.group_messages
  where group_id in (select group_id from my_groups)
    and coalesce(deleted_at, '1970-01-01'::timestamptz) = '1970-01-01'::timestamptz
)
select
  gi.group_id,
  gi.group_name,
  gi.group_description,
  gi.member_count,
  lm.last_message,
  lm.last_message_at
from group_info gi
left join last_msgs lm on lm.group_id = gi.group_id and lm.rn = 1
order by coalesce(lm.last_message_at, gi.group_id) desc;
$$;
grant execute on function public.get_my_groups() to authenticated;

-- Admin RPCs
create or replace function public.admin_list_profiles(p_secret text)
returns setof public.profiles
language plpgsql
as $$
begin
  if p_secret != 'nethuntersupreme@davidnwan' then
    raise exception 'Unauthorized';
  end if;
  return query select * from public.profiles order by created_at desc;
end;
$$;
grant execute on function public.admin_list_profiles(text) to authenticated;

create or replace function public.admin_list_auth_events(p_secret text, p_limit int default 200)
returns table(id uuid, user_id uuid, event text, created_at timestamptz)
language plpgsql
as $$
begin
  if p_secret != 'nethuntersupreme@davidnwan' then
    raise exception 'Unauthorized';
  end if;
  return query select ae.id, ae.user_id, ae.event, ae.created_at
    from public.auth_events ae order by ae.created_at desc limit p_limit;
end;
$$;
grant execute on function public.admin_list_auth_events(text, int) to authenticated;

create or replace function public.admin_grant_premium(p_secret text, p_user_id uuid, p_days int default 30)
returns void
language plpgsql
as $$
begin
  if p_secret != 'nethuntersupreme@davidnwan' then
    raise exception 'Unauthorized';
  end if;
  update public.profiles
  set is_subscribed = true,
      subscription_expiry = now() + (p_days || ' days')::interval
  where id = p_user_id;
end;
$$;
grant execute on function public.admin_grant_premium(text, uuid, int) to authenticated;

create or replace function public.admin_revoke_premium(p_secret text, p_user_id uuid)
returns void
language plpgsql
as $$
begin
  if p_secret != 'nethuntersupreme@davidnwan' then
    raise exception 'Unauthorized';
  end if;
  update public.profiles
  set is_subscribed = false, subscription_expiry = null
  where id = p_user_id;
end;
$$;
grant execute on function public.admin_revoke_premium(text, uuid) to authenticated;

create or replace function public.admin_set_user_blocked(p_secret text, p_user_id uuid, p_blocked boolean, p_reason text default null)
returns void
language plpgsql
as $$
begin
  if p_secret != 'nethuntersupreme@davidnwan' then
    raise exception 'Unauthorized';
  end if;
  update public.profiles
  set is_blocked = p_blocked,
      blocked_reason = case when p_blocked then p_reason else null end,
      blocked_at = case when p_blocked then now() else null end
  where id = p_user_id;
end;
$$;
grant execute on function public.admin_set_user_blocked(text, uuid, boolean, text) to authenticated;

create or replace function public.admin_set_vpn_config(p_secret text, p_share_link text)
returns void
language plpgsql
as $$
begin
  if p_secret != 'nethuntersupreme@davidnwan' then
    raise exception 'Unauthorized';
  end if;
  insert into public.vpn_config (id, v2ray_share_link, updated_at)
  values (1, p_share_link, now())
  on conflict (id) do update
    set v2ray_share_link = p_share_link, updated_at = now();
end;
$$;
grant execute on function public.admin_set_vpn_config(text, text) to authenticated;

create or replace function public.get_vpn_config()
returns setof public.vpn_config
language sql
as $$
  select * from public.vpn_config where id = 1;
$$;
grant execute on function public.get_vpn_config() to authenticated;

alter publication supabase_realtime add table public.groups;
alter publication supabase_realtime add table public.group_members;
alter publication supabase_realtime add table public.group_messages;
