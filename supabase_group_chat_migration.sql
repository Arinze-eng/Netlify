-- Group chat migration for CDN-NETCHAT
-- Adds: groups table, group_members, group_messages
-- Project: ljnparociyyggmxdewwv

-- 1) Groups table
CREATE TABLE IF NOT EXISTS public.groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  avatar_url TEXT,
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Groups are viewable by members" ON public.groups;
CREATE POLICY "Groups are viewable by members" ON public.groups
FOR SELECT TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = public.groups.id AND gm.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users can create groups" ON public.groups;
CREATE POLICY "Users can create groups" ON public.groups
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "Group creator can update" ON public.groups;
CREATE POLICY "Group creator can update" ON public.groups
FOR UPDATE TO authenticated
USING (auth.uid() = created_by);

DROP POLICY IF EXISTS "Group creator can delete" ON public.groups;
CREATE POLICY "Group creator can delete" ON public.groups
FOR DELETE TO authenticated
USING (auth.uid() = created_by);

-- 2) Group members table
CREATE TABLE IF NOT EXISTS public.group_members (
  id BIGSERIAL PRIMARY KEY,
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view group members" ON public.group_members;
CREATE POLICY "Members can view group members" ON public.group_members
FOR SELECT TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = public.group_members.group_id AND gm.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Admins can add members" ON public.group_members;
CREATE POLICY "Admins can add members" ON public.group_members
FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = public.group_members.group_id AND gm.user_id = auth.uid() AND gm.role = 'admin')
  OR EXISTS (SELECT 1 FROM public.groups g WHERE g.id = public.group_members.group_id AND g.created_by = auth.uid())
);

DROP POLICY IF EXISTS "Admins can remove members" ON public.group_members;
CREATE POLICY "Admins can remove members" ON public.group_members
FOR DELETE TO authenticated
USING (
  -- Admin can remove others, any member can remove themselves (leave group)
  (public.group_members.user_id = auth.uid())
  OR EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = public.group_members.group_id AND gm.user_id = auth.uid() AND gm.role = 'admin')
  OR EXISTS (SELECT 1 FROM public.groups g WHERE g.id = public.group_members.group_id AND g.created_by = auth.uid())
);

DROP POLICY IF EXISTS "Admins can update roles" ON public.group_members;
CREATE POLICY "Admins can update roles" ON public.group_members
FOR UPDATE TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = public.group_members.group_id AND gm.user_id = auth.uid() AND gm.role = 'admin')
  OR EXISTS (SELECT 1 FROM public.groups g WHERE g.id = public.group_members.group_id AND g.created_by = auth.uid())
);

-- 3) Group messages table (separate from 1:1 messages for cleaner querying)
CREATE TABLE IF NOT EXISTS public.group_messages (
  id BIGSERIAL PRIMARY KEY,
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL DEFAULT '',
  message_type TEXT NOT NULL DEFAULT 'text',
  media_path TEXT,
  media_mime TEXT,
  media_duration_ms INTEGER,
  media_name TEXT,
  media_size_bytes BIGINT,
  caption TEXT,
  reply_to_id BIGINT REFERENCES public.group_messages(id) ON DELETE SET NULL,
  edited_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  is_pinned BOOLEAN DEFAULT FALSE,
  reactions JSONB DEFAULT '{}',
  media_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.group_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Group members can view messages" ON public.group_messages;
CREATE POLICY "Group members can view messages" ON public.group_messages
FOR SELECT TO authenticated
USING (
  EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = public.group_messages.group_id AND gm.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Group members can send messages" ON public.group_messages;
CREATE POLICY "Group members can send messages" ON public.group_messages
FOR INSERT TO authenticated
WITH CHECK (
  auth.uid() = sender_id
  AND EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = public.group_messages.group_id AND gm.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Sender can update own group messages" ON public.group_messages;
CREATE POLICY "Sender can update own group messages" ON public.group_messages
FOR UPDATE TO authenticated
USING (auth.uid() = sender_id);

-- 4) Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.groups;
ALTER PUBLICATION supabase_realtime ADD TABLE public.group_members;
ALTER PUBLICATION supabase_realtime ADD TABLE public.group_messages;

-- 5) Helper: get user's groups with last message
CREATE OR REPLACE FUNCTION public.get_my_groups()
RETURNS TABLE(
  group_id uuid,
  group_name text,
  group_description text,
  group_avatar_url text,
  member_count bigint,
  last_message text,
  last_message_at timestamptz
)
LANGUAGE sql
AS $$
WITH my_groups AS (
  SELECT gm.group_id
  FROM public.group_members gm
  WHERE gm.user_id = auth.uid()
),
latest AS (
  SELECT DISTINCT ON (gm.group_id)
    gm.group_id,
    gm.content AS last_message,
    gm.created_at AS last_message_at
  FROM public.group_messages gm
  WHERE gm.group_id IN (SELECT group_id FROM my_groups)
    AND gm.deleted_at IS NULL
  ORDER BY gm.group_id, gm.created_at DESC
),
member_counts AS (
  SELECT group_id, COUNT(*)::bigint AS member_count
  FROM public.group_members
  WHERE group_id IN (SELECT group_id FROM my_groups)
  GROUP BY group_id
)
SELECT
  g.id AS group_id,
  g.name AS group_name,
  g.description AS group_description,
  g.avatar_url AS group_avatar_url,
  COALESCE(mc.member_count, 0) AS member_count,
  l.last_message,
  l.last_message_at
FROM my_groups mg
JOIN public.groups g ON g.id = mg.group_id
LEFT JOIN latest l ON l.group_id = g.id
LEFT JOIN member_counts mc ON mc.group_id = g.id
ORDER BY COALESCE(l.last_message_at, g.created_at) DESC;
$$;
GRANT EXECUTE ON FUNCTION public.get_my_groups() TO authenticated;
