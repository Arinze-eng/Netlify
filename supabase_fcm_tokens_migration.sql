-- [UPDATE #4] FCM tokens table for push notifications
-- This table stores device FCM tokens so the Edge Function can send
-- push notifications even when the app is completely closed/terminated.
-- The device writes its token here after login; the Edge Function reads it.

CREATE TABLE IF NOT EXISTS public.fcm_tokens (
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
  fcm_token TEXT NOT NULL,
  platform TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Users can read their own token (for debugging)
DROP POLICY IF EXISTS "Users can read own FCM token" ON public.fcm_tokens;
CREATE POLICY "Users can read own FCM token" ON public.fcm_tokens
FOR SELECT TO authenticated
USING (auth.uid() = user_id);

-- Users can insert/update their own FCM token
DROP POLICY IF EXISTS "Users can upsert own FCM token" ON public.fcm_tokens;
CREATE POLICY "Users can upsert own FCM token" ON public.fcm_tokens
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own FCM token" ON public.fcm_tokens;
CREATE POLICY "Users can update own FCM token" ON public.fcm_tokens
FOR UPDATE TO authenticated
USING (auth.uid() = user_id);

-- Users can delete their own FCM token (on sign-out)
DROP POLICY IF EXISTS "Users can delete own FCM token" ON public.fcm_tokens;
CREATE POLICY "Users can delete own FCM token" ON public.fcm_tokens
FOR DELETE TO authenticated
USING (auth.uid() = user_id);

-- Service role can read all tokens (for Edge Function to send pushes)
-- This is handled by the SUPABASE_SERVICE_ROLE_KEY which bypasses RLS

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_fcm_token_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_fcm_token_update ON public.fcm_tokens;
CREATE TRIGGER on_fcm_token_update
BEFORE UPDATE ON public.fcm_tokens
FOR EACH ROW EXECUTE FUNCTION public.update_fcm_token_updated_at();
