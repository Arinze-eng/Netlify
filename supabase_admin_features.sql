-- Admin features migration for CDN-NETCHAT
-- Adds: block/unblock users, grant/revoke premium, admin search/list RPCs
-- Updated: 2026-04-28

-- 1) Extend profiles for block control
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_blocked boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS blocked_reason text,
  ADD COLUMN IF NOT EXISTS blocked_at timestamptz;

-- 2) Ensure auth_events exists (used by AdminScreen)
CREATE TABLE IF NOT EXISTS public.auth_events (
  id bigserial primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  event text not null,
  created_at timestamptz not null default now()
);
ALTER TABLE public.auth_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert own auth events" ON public.auth_events;
CREATE POLICY "Users can insert own auth events" ON public.auth_events
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 3) vpn_config table + getter RPC (AdminScreen uses this)
CREATE TABLE IF NOT EXISTS public.vpn_config (
  id int primary key default 1,
  v2ray_share_link text,
  updated_at timestamptz not null default now()
);
ALTER TABLE public.vpn_config ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.get_vpn_config()
RETURNS TABLE(v2ray_share_link text, updated_at timestamptz)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT v2ray_share_link, updated_at
  FROM public.vpn_config
  ORDER BY updated_at DESC
  LIMIT 1;
$$;
GRANT EXECUTE ON FUNCTION public.get_vpn_config() TO authenticated;

-- 4) Blocked users should not be able to send messages
DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
CREATE POLICY "Users can send messages" ON public.messages
FOR INSERT TO authenticated
WITH CHECK (
  auth.uid() = sender_id
  AND EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.is_blocked = false
  )
);

-- 5) Blocked users should not be able to upload media
-- (storage.objects is in the storage schema)
DROP POLICY IF EXISTS "chat_media upload" ON storage.objects;
CREATE POLICY "chat_media upload" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'chat_media'
  AND EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.is_blocked = false
  )
);

-- 6) Admin RPCs (secret-based)
CREATE OR REPLACE FUNCTION public._admin_assert_secret(p_secret text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_secret IS NULL OR btrim(p_secret) = '' THEN
    RAISE EXCEPTION 'Missing admin secret';
  END IF;

  -- NOTE: matches SupabaseService.adminSecret in app.
  IF p_secret <> 'nethuntersupreme@davidnwan' THEN
    RAISE EXCEPTION 'Invalid admin secret';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_list_profiles(p_secret text)
RETURNS SETOF public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public._admin_assert_secret(p_secret);
  RETURN QUERY
    SELECT * FROM public.profiles
    ORDER BY created_at DESC;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_list_profiles(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.admin_list_auth_events(p_secret text, p_limit int default 200)
RETURNS TABLE(user_id uuid, event text, created_at timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public._admin_assert_secret(p_secret);
  RETURN QUERY
    SELECT ae.user_id, ae.event, ae.created_at
    FROM public.auth_events ae
    ORDER BY ae.created_at DESC
    LIMIT LEAST(GREATEST(p_limit, 1), 1000);
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_list_auth_events(text,int) TO authenticated;

CREATE OR REPLACE FUNCTION public.admin_grant_premium(p_secret text, p_user_id uuid, p_days int default 30)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  d int;
BEGIN
  PERFORM public._admin_assert_secret(p_secret);
  d := LEAST(GREATEST(COALESCE(p_days, 30), 1), 3650);

  UPDATE public.profiles
  SET is_subscribed = true,
      subscription_expiry = now() + make_interval(days => d)
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_grant_premium(text,uuid,int) TO authenticated;

CREATE OR REPLACE FUNCTION public.admin_revoke_premium(p_secret text, p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public._admin_assert_secret(p_secret);

  UPDATE public.profiles
  SET is_subscribed = false,
      subscription_expiry = NULL
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_revoke_premium(text,uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.admin_set_user_blocked(
  p_secret text,
  p_user_id uuid,
  p_blocked boolean,
  p_reason text default null
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public._admin_assert_secret(p_secret);

  UPDATE public.profiles
  SET is_blocked = COALESCE(p_blocked, true),
      blocked_reason = CASE WHEN COALESCE(p_blocked, true) THEN NULLIF(btrim(COALESCE(p_reason,'')), '') ELSE NULL END,
      blocked_at = CASE WHEN COALESCE(p_blocked, true) THEN now() ELSE NULL END
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_set_user_blocked(text,uuid,boolean,text) TO authenticated;

CREATE OR REPLACE FUNCTION public.admin_set_vpn_config(p_secret text, p_share_link text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public._admin_assert_secret(p_secret);

  INSERT INTO public.vpn_config (id, v2ray_share_link, updated_at)
  VALUES (1, NULLIF(btrim(p_share_link),''), now())
  ON CONFLICT (id) DO UPDATE
    SET v2ray_share_link = EXCLUDED.v2ray_share_link,
        updated_at = EXCLUDED.updated_at;
END;
$$;
GRANT EXECUTE ON FUNCTION public.admin_set_vpn_config(text,text) TO authenticated;
