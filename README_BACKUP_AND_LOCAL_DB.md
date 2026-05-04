# Legio / CDN-NETCHAT

## New: WhatsApp-like local storage + Google Drive backup

This version adds:
- **Local message storage (Isar)** for WhatsApp-like offline chat history.
- **Media transfer-only** via Supabase Storage (receiver auto-downloads; server object deleted best-effort).
- **Google Drive backup/restore** (Drive `appDataFolder`).
- **Privacy settings**: hide last seen, hide read receipts.

### Important (Isar code generation)
Isar requires generated files (`*.g.dart`). Run these commands in your Flutter environment:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

Then build/run as normal.

### Google Drive configuration
To use Google Sign-In + Drive:
- Configure **Android** OAuth client (SHA-1) in Google Cloud Console.
- Add the correct `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the project.

This app uses Drive scope: `drive.appdata`.
