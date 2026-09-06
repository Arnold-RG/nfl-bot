# Play Console — do this now (Internal testing)

Browser should be open at Play Console signup. Follow in order.

## A. Account (once)
1. Finish Google Play Console signup + payment + identity verification  
2. Wait until Console home loads without “complete registration” blockers  

## B. Create the app
1. **Create app**  
2. Name: `NFL BOT`  
3. Language: English (or your default)  
4. App / Free  
5. Accept declarations → Create  

## C. Upload build (Internal testing — fastest install)
1. Left menu → **Test and release** → **Testing** → **Internal testing**  
2. **Create new release**  
3. Upload this file:

`c:\flutter_windows_3.29.3-stable\flutter\nfbot_app\build\app\outputs\bundle\release\app-release.aab`

4. Release name: `1.0.0 (1)`  
5. Save → Review → Start rollout to Internal testing  

## D. Add yourself as tester
1. Internal testing → **Testers** → create email list  
2. Add the Gmail on your Android phone  
3. Copy the **join link** → open on phone → Accept → Install from Play  

## E. Required before Production (can do after Internal works)
- Store listing (see `PLAY_STORE_LISTING_DRAFT.md`)  
- Privacy policy URL — starter file: `docs/privacy_policy.html` (host on HTTPS, put your email in it)  
- Data safety form  
- App content / IARC rating  
- Target audience  

## Sideload while waiting for Console
When APK finishes:

`build\app\outputs\flutter-apk\app-release.apk`

Copy to phone → open → allow Install unknown apps → Install.
