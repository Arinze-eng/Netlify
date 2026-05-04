# Testing checklist (CDN-NETCHAT + Supabase)

## 1) Supabase DB reset status
This repo includes `supabase_schema.sql` which matches what was applied via Supabase MCP.

Quick verification (Supabase SQL editor):

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```
Expected: `messages`, `profiles`

## 2) Auth rules
### Duplicate signup prevention
- Supabase Auth prevents duplicate signups on the same **email** automatically.
- `profiles.email` and `profiles.username` are also `UNIQUE` as a second line of defense.

### Allow sign-in without email verification
App-side checks that blocked unverified users were removed.

Important: Supabase can still enforce confirmation at the server level depending on your Auth settings.

To guarantee *"can sign in even without email verification"*, disable email confirmation in your project:
- Dashboard → **Authentication** → **Providers** → **Email** → turn **Confirm email** OFF

## 3) Manual end-to-end flow (recommended)
### A. Signup
1. Open app → **Sign Up**
2. Create account with **name + email + password**
3. You should immediately be able to **Sign In** (no email verification gate in the app)

### B. Duplicate signup
1. Repeat signup with the same email
2. Expect an error toast/snackbar like: "This email is already registered. Please sign in."

### C. Create a 1:1 chat
You need **two accounts** (User A and User B):
1. Sign in as User A
2. Find User B in Discover users (UUID list)
3. Open chat room and send messages
4. Sign in as User B (on another device/emulator) and confirm messages arrive

### D. Realtime
While both accounts are online:
- Send messages back and forth
- Confirm the message list updates live without refresh (Supabase Realtime)

### E. In-app notifications (foreground)
When you are on the **Chat list** screen (not inside a chat room):
- Have User B send a message to User A
- User A should see a **SnackBar notification** like: `Name (or UUID): message...`
- Tap **Open** on the SnackBar to jump into the chat

### E. Presence (last_seen)
- The app periodically calls `touch_last_seen()`.
- In chat header, user shows **Online** when `now - last_seen < 2 minutes`.

## 4) Useful SQL for debugging
### Latest 20 messages
```sql
select * from public.messages order by created_at desc limit 20;
```

### Profiles
```sql
select id, email, username, last_seen, created_at
from public.profiles
order by created_at desc;
```
