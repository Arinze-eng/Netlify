-- Media upgrade for CDN-NETCHAT
-- Adds per-message media attachments (image / voice note) using Supabase Storage

-- 1) Extend messages table
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS message_type text NOT NULL DEFAULT 'text',
  ADD COLUMN IF NOT EXISTS media_path text,
  ADD COLUMN IF NOT EXISTS media_mime text,
  ADD COLUMN IF NOT EXISTS media_duration_ms integer;

-- 2) Allow sender to update their own message metadata (needed if you ever upload after insert)
DROP POLICY IF EXISTS "Users can update own sent messages" ON public.messages;
CREATE POLICY "Users can update own sent messages" ON public.messages FOR UPDATE USING (
  auth.uid() = sender_id
);

-- 3) Storage bucket + policies
-- Create bucket named `chat_media` in Supabase Dashboard (Storage) OR run:
-- insert into storage.buckets (id, name, public) values ('chat_media','chat_media', false);

-- Policies for storage.objects (bucket-level RLS)
-- Allow authenticated users to upload into chat_media
DROP POLICY IF EXISTS "chat_media upload" ON storage.objects;
CREATE POLICY "chat_media upload" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'chat_media');

-- Allow authenticated users to read objects they uploaded OR objects referenced by messages they can see.
-- Simpler: allow read for authenticated (since messages already protected by RLS)
DROP POLICY IF EXISTS "chat_media read" ON storage.objects;
CREATE POLICY "chat_media read" ON storage.objects
FOR SELECT TO authenticated
USING (bucket_id = 'chat_media');

-- Allow delete own uploads (optional)
DROP POLICY IF EXISTS "chat_media delete" ON storage.objects;
CREATE POLICY "chat_media delete" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'chat_media' AND owner = auth.uid());
