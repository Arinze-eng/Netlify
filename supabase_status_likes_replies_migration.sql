-- Status likes and replies migration
-- Project: ljnparociyyggmxdewwv
-- Version: 2.5.0

-- ============================================================
-- 1) STATUS LIKES (WhatsApp-like emoji reaction on status)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.status_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  status_id UUID NOT NULL REFERENCES public.status(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(status_id, user_id)
);

ALTER TABLE public.status_likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view status likes" ON public.status_likes;
CREATE POLICY "Users can view status likes" ON public.status_likes
FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "Users can like status" ON public.status_likes;
CREATE POLICY "Users can like status" ON public.status_likes
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can unlike status" ON public.status_likes;
CREATE POLICY "Users can unlike status" ON public.status_likes
FOR DELETE TO authenticated
USING (auth.uid() = user_id);

-- ============================================================
-- 2) STATUS REPLIES (WhatsApp-like reply to status)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.status_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  status_id UUID NOT NULL REFERENCES public.status(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.status_replies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view status replies" ON public.status_replies;
CREATE POLICY "Users can view status replies" ON public.status_replies
FOR SELECT TO authenticated
USING (
  -- Status owner can see replies to their status
  EXISTS (SELECT 1 FROM public.status s WHERE s.id = status_id AND s.user_id = auth.uid())
  -- Or you are the replier
  OR user_id = auth.uid()
);

DROP POLICY IF EXISTS "Users can reply to status" ON public.status_replies;
CREATE POLICY "Users can reply to status" ON public.status_replies
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Add realtime support
ALTER PUBLICATION supabase_realtime ADD TABLE public.status_likes;
ALTER PUBLICATION supabase_realtime ADD TABLE public.status_replies;
