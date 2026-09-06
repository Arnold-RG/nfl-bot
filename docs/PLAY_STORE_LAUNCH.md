# Launch NFL BOT on Google Play (Android)

This is the **practical** store path from your Windows PC. Android SDK is already working on this machine.

## What you get
- Install from **Play Store** on any Android phone  
- Or sideload a release APK / internal testing track first  

Package ID: `com.nfbot.nfbot_app`  
App name on device: **NFL BOT**

---

## Step 1 — Google Play Developer account (you)

1. Open [https://play.google.com/console/signup](https://play.google.com/console/signup)  
2. Pay the **one-time** registration fee (Google’s current fee; historically ~$25)  
3. Complete identity verification (can take hours–days)

Without this, you cannot publish.

---

## Step 2 — Signing (already prepared in this project)

Release signing is configured:

| File | Purpose |
|------|---------|
| `android/upload-keystore.jks` | Upload keystore (**do not lose**) |
| `android/key.properties` | Passwords for local builds (**gitignored**) |
| Desktop `NFLBOT_PLAY_STORE_KEY_BACKUP.txt` | Password backup — store offline / password manager |

If you lose the keystore, you **cannot update** the same Play listing.

---

## Step 3 — Build the Play upload file (App Bundle)

On this PC, in `nfbot_app`:

```powershell
flutter pub get
flutter build appbundle --release
```

Output:

`build/app/outputs/bundle/release/app-release.aab`

That `.aab` is what you upload to Play Console.

Optional APK for direct install on your phone (not for Play upload):

```powershell
flutter build apk --release
```

Then copy `build/app/outputs/flutter-apk/app-release.apk` to the phone and open it (enable Install unknown apps if needed).

---

## Step 4 — Create the app in Play Console

1. Play Console → **Create app**  
2. App name: `NFL BOT`  
3. Default language, app/game = App, free/paid  
4. Accept declarations  

### Store listing (minimum)
- Short description (80 chars)  
- Full description  
- App icon 512×512  
- Feature graphic 1024×500  
- Phone screenshots (at least 2)  
- Privacy Policy URL (required for mic/camera/health-related permissions)  
- App category: Health & Fitness  

Draft copy: [`PLAY_STORE_LISTING_DRAFT.md`](PLAY_STORE_LISTING_DRAFT.md)

### Data safety
Declare: camera, mic, approximate activity, app interactions, etc. Be honest — you collect health/fitness style data on-device.

---

## Step 5 — Upload & test on your Android phone

1. Play Console → your app → **Testing** → **Internal testing**  
2. Create release → upload `app-release.aab`  
3. Add your Gmail as a tester  
4. Open the **join link** on the Android phone → install from Play  

Internal testing is the fastest way to install like a real store app before public release.

Then: **Closed / Open testing** → **Production**.

---

## Checklist

- [ ] Play Console account active  
- [ ] Privacy policy URL live  
- [ ] `flutter build appbundle --release` succeeds  
- [ ] Internal testing install on your phone works  
- [ ] Screenshots + listing complete  
- [ ] Production rollout  

---

## Commands cheat sheet

```powershell
cd c:\flutter_windows_3.29.3-stable\flutter\nfbot_app
flutter build appbundle --release
flutter build apk --release
```

---

## Note on “NFL” naming
Google may reject or flag trademarks. Consider renaming before production (e.g. **NFBot**, **NFit BOT**) if you do not own NFL rights.
