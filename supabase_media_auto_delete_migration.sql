-- Media auto-delete (27h expiry) migration
-- Project: ljnparociyyggmxdewwv
-- Adds media_expires_at column to track when Supabase Storage media should be deleted
-- Media stays locally cached (WhatsApp-like) even after Supabase Storage cleanup

ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS media_expires_at timestamptz;

CREATE INDEX IF NOT EXISTS messages_media_expires_at_idx ON public.messages(media_expires_at)
  WHERE media_expires_at IS NOT NULL;
