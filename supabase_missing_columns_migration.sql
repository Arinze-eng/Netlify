-- Comprehensive missing columns migration for CDN-NETCHAT
-- Project: ljnparociyyggmxdewwv
-- This adds all columns referenced in app code but missing from base schema

-- Messages: is_liked, is_pinned, reactions columns
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS is_liked BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS reactions JSONB DEFAULT '{}';

CREATE INDEX IF NOT EXISTS messages_is_pinned_idx ON public.messages(is_pinned) WHERE is_pinned = true;

-- Fix: Update messages UPDATE policy to allow both sender and receiver to update
-- (needed for reactions, read receipts, pinning, etc.)
DROP POLICY IF EXISTS "Users can update received message flags" ON public.messages;
DROP POLICY IF EXISTS "Users can update own sent messages" ON public.messages;

-- Sender can update their own messages (edits, deletes)
CREATE POLICY "Users can update own sent messages" ON public.messages
FOR UPDATE TO authenticated
USING (auth.uid() = sender_id)
WITH CHECK (auth.uid() = sender_id);

-- Receiver can update received messages (read receipts, reactions)
CREATE POLICY "Users can update received message flags" ON public.messages
FOR UPDATE TO authenticated
USING (auth.uid() = receiver_id)
WITH CHECK (auth.uid() = receiver_id);

-- Fix: Storage delete policy - use proper approach without owner column
DROP POLICY IF EXISTS "chat_media delete" ON storage.objects;
CREATE POLICY "chat_media delete" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'chat_media');
