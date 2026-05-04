-- [UPDATE #6] Add deleted_for_users column to group_messages for "delete for me" support
-- This stores a JSON array of user IDs who have deleted the message for themselves only.
-- The message remains visible to other group members.

ALTER TABLE public.group_messages
  ADD COLUMN IF NOT EXISTS deleted_for_users JSONB DEFAULT '[]';

-- Also ensure the messages table has proper columns for delete-for-me
-- (deleted_for_sender and deleted_for_receiver should already exist from previous migrations)
