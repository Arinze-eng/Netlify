# CDN-NETCHAT VPN Module (separate build)

This is a **separate Flutter project** meant to isolate native VPN core integration from your main CDN-NETCHAT app.

## What it does
- Uses **`flutter_v2ray_client`** (V2Ray/Xray core, v2rayNG-like)
- Lets you paste a **vless:// or vmess://** link and connect/disconnect
- Shows core state updates and has a simple internet test

## Why separate
If your main app has Gradle/JVM/native build issues, keeping VPN in this separate project lets:
- your **main app** build cleanly (UI-only, no native VPN)
- your **VPN module** handle all native stuff

## Run
```bash
flutter pub get
flutter run
```

## Build APK
```bash
flutter build apk
```

## Integrating later
Two stable paths:
1) Keep this as a separate app, and control it via Android intents/Binder.
2) Convert this into a federated plugin once build settings are stable.
