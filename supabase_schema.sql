-- CDN-NETCHAT Supabase schema (single source of truth)
-- Updated: 2026-04-27

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  username TEXT UNIQUE NOT NULL, -- Chat UUID (8 chars)
  display_name TEXT,
  trial_ends_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '30 days'),
  is_subscribed BOOLEAN DEFAULT FALSE,
  subscription_expiry TIMESTAMP WITH TIME ZONE,
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Auto-create profile on new user signup (uses auth metadata: username + display_name)
-- IMPORTANT: Remove any legacy auth.users triggers that reference old profile columns.
DROP TRIGGER IF EXISTS on_auth_user_created_create_profile ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user_create_profile();
DROP FUNCTION IF EXISTS public.generate_unique_profile_code();

-- IMPORTANT: We keep RLS enabled, so we also add an INSERT policy.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  chat_uuid text;
  disp text;
BEGIN
  disp := NULLIF(trim(COALESCE(new.raw_user_meta_data->>'display_name', '')), '');
  chat_uuid := COALESCE(
    new.raw_user_meta_data->>'username',
    substring(replace(pg_catalog.gen_random_uuid()::text, '-', '') from 1 for 8)
  );

  INSERT INTO public.profiles (id, email, username, display_name)
  VALUES (new.id, new.email, upper(chat_uuid), disp)
  ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email,
        display_name = COALESCE(public.profiles.display_name, EXCLUDED.display_name);

  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

CREATE TABLE IF NOT EXISTS public.messages (
  id BIGSERIAL PRIMARY KEY,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  is_liked BOOLEAN DEFAULT FALSE,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can view their own messages" ON public.messages;
DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
DROP POLICY IF EXISTS "Users can update like status on received messages" ON public.messages;
CREATE POLICY "Users can view their own messages" ON public.messages FOR SELECT USING (
  auth.uid() = sender_id OR auth.uid() = receiver_id
);
CREATE POLICY "Users can send messages" ON public.messages FOR INSERT WITH CHECK (
  auth.uid() = sender_id
);
CREATE POLICY "Users can update like status on received messages" ON public.messages FOR UPDATE USING (
  auth.uid() = receiver_id
);

CREATE OR REPLACE FUNCTION public.touch_last_seen()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.profiles
  SET last_seen = NOW()
  WHERE id = auth.uid();
END;
$$;
GRANT EXECUTE ON FUNCTION public.touch_last_seen() TO authenticated;

DROP FUNCTION IF EXISTS public.get_chat_threads();
CREATE OR REPLACE FUNCTION public.get_chat_threads()
RETURNS TABLE(
  other_user_id uuid,
  other_username text,
  other_display_name text,
  other_email text,
  last_message text,
  last_message_at timestamptz,
  unread_count bigint
)
LANGUAGE sql
AS $$
WITH my_messages AS (
  SELECT
    CASE WHEN sender_id = auth.uid() THEN receiver_id ELSE sender_id END AS other_user_id,
    content,
    created_at,
    (receiver_id = auth.uid() AND is_read = false) AS is_unread
  FROM public.messages
  WHERE sender_id = auth.uid() OR receiver_id = auth.uid()
), ranked AS (
  SELECT
    other_user_id,
    content,
    created_at,
    is_unread,
    ROW_NUMBER() OVER (PARTITION BY other_user_id ORDER BY created_at DESC) AS rn
  FROM my_messages
), latest AS (
  SELECT other_user_id, content AS last_message, created_at AS last_message_at
  FROM ranked
  WHERE rn = 1
), unread AS (
  SELECT other_user_id, COUNT(*)::bigint AS unread_count
  FROM my_messages
  WHERE is_unread
  GROUP BY other_user_id
)
SELECT
  p.id AS other_user_id,
  p.username AS other_username,
  p.display_name AS other_display_name,
  p.email AS other_email,
  l.last_message,
  l.last_message_at,
  COALESCE(u.unread_count, 0) AS unread_count
FROM latest l
JOIN public.profiles p ON p.id = l.other_user_id
LEFT JOIN unread u ON u.other_user_id = l.other_user_id
ORDER BY l.last_message_at DESC;
$$;
GRANT EXECUTE ON FUNCTION public.get_chat_threads() TO authenticated;

ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
