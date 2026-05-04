-- Call history migration for CDN-NETCHAT
-- Project: ljnparociyyggmxdewwv

CREATE TABLE IF NOT EXISTS public.call_history (
  id BIGSERIAL PRIMARY KEY,
  caller_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  call_type TEXT NOT NULL DEFAULT 'audio' CHECK (call_type IN ('audio', 'video')),
  status TEXT NOT NULL DEFAULT 'missed' CHECK (status IN ('missed', 'completed', 'declined')),
  duration_seconds INTEGER DEFAULT 0,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.call_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own call history" ON public.call_history;
CREATE POLICY "Users can view own call history" ON public.call_history
FOR SELECT TO authenticated
USING (auth.uid() = caller_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can insert call history" ON public.call_history;
CREATE POLICY "Users can insert call history" ON public.call_history
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = caller_id);

CREATE INDEX IF NOT EXISTS call_history_caller_idx ON public.call_history(caller_id);
CREATE INDEX IF NOT EXISTS call_history_receiver_idx ON public.call_history(receiver_id);
CREATE INDEX IF NOT EXISTS call_history_started_at_idx ON public.call_history(started_at DESC);

ALTER PUBLICATION supabase_realtime ADD TABLE public.call_history;
