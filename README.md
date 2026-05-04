# CDN-CHATROOM: Premium Offline Chatting App

A high-fidelity Flutter application featuring in-app VPN tunneling, Supabase real-time chatting, and a robust trial/subscription system.

## Key Features
- **Telegram-like UI**: Sleek chats list + Telegram-ish chat room.
- **Real-Time Chatting**: Powered by Supabase (messages only).
- **Reply / Edit / Delete**: Swipe-to-reply, edit text messages, delete for me / delete for everyone.
- **Disappearing messages**: Optional 24h / 7d self-destruct (client-side hide).
- **Animated emoji**: Emoji messages animate and re-animate on tap.
- **User block**: Block/unblock a user from messaging.
- **Local-only media**: Images + voice notes can be saved/viewed locally without using Supabase Storage.
- **Voice/Video calls**: WebRTC call UI + a lightweight self-hosted signaling server (no Supabase signaling).
- **Trial & Subscription**: 30-day free trial followed by a N5,000/month subscription lock.

## Technical Details

### 1. VPN Configuration
The app uses the following server details for the SSL/TLS WebSocket tunnel:
- **Server**: 172.67.187.6
- **Port**: 443
- **Username**: tnl-otm3uubm
- **Password**: 4UWTvugbWNRO
- **SNI**: ssh-de-2.optnl.com
- **Payload**: Configured as a WebSocket upgrade request in `lib/services/vpn_service.dart`.

### 2. Supabase Setup
- Run the SQL in `supabase_schema.sql` in your Supabase project.
- Update `lib/main.dart` with your project URL and Anon Key.

### 3. Android Build
Ensure the package name in `lib/services/vpn_service.dart` (`com.example.cdn_netshare`) matches your `AndroidManifest.xml`.

## Setup
```bash
flutter pub get
flutter run
```

## Voice/Video Calling (WebRTC)
This build includes a simple **self-hosted** WebSocket signaling server (no Supabase involvement):

```bash
cd signaling-server
npm install
npm run start
```

- Default server: `ws://0.0.0.0:8787`
- The app currently uses **Android emulator default**: `ws://10.0.2.2:8787`
  - For a real device, change it to your PC/LAN IP, e.g. `ws://192.168.1.10:8787`

> Note: WebRTC call reliability may require TURN for some networks.


## Media auto-delete (Supabase Storage)
Media (images/voice) are uploaded to the `chat_media` bucket but **auto-deleted after `expires_at`**.

This build ships an Edge Function `cleanup_media` (already deployed). You should schedule it (e.g. every 10 minutes) in Supabase Dashboard:
- **Edge Functions → cleanup_media → Schedules** (Cron)
- Suggested cron: `*/10 * * * *`

What it does:
- Finds messages where `media_path` is set and `expires_at < now()`.
- Deletes the object from Storage bucket `chat_media`.
- Sets `media_path/media_mime/media_duration_ms` to NULL so Storage stops being used.
- The message stays in chat; clients will show cached local copy if available.
