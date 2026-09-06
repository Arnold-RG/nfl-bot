# Get NFL BOT on your iPhone 15 (App Store / TestFlight)

Goal: open the **App Store** (or TestFlight), tap **Get**, install on iPhone 15.

You **cannot** finish this from Windows alone. Apple requires a Developer account + a Mac build (Codemagic provides the Mac in the cloud).

---

## Your path (recommended): TestFlight first → App Store

```text
1. Pay Apple Developer ($99/year)
2. Create app in App Store Connect
3. Connect this project to Codemagic (cloud Mac)
4. Codemagic builds → uploads to TestFlight
5. Install on iPhone 15 via TestFlight (easy, private)
6. Finish store listing → Submit for App Store review
7. After approval → public App Store install
```

TestFlight is the **same install experience** on iPhone 15, just private until Apple approves the public listing.

---

## Step 1 — Apple Developer (you must do this)

1. On any browser: [https://developer.apple.com/programs/](https://developer.apple.com/programs/)  
2. Enroll with the **Apple ID** you use on your iPhone 15  
3. Pay and wait until status is **Active** (can take hours–2 days)

Without this, App Store / TestFlight is impossible.

---

## Step 2 — Create the app in App Store Connect

1. Open [https://appstoreconnect.apple.com](https://appstoreconnect.apple.com)  
2. **My Apps** → **+** → New App  
3. Platforms: **iOS**  
4. Name: e.g. `NFL BOT` (check trademark risk for “NFL”)  
5. Bundle ID: register `com.nfbot.nfbotApp` under Certificates, Identifiers & Profiles if needed  
6. SKU: `nflbot001`  
7. Copy the numeric **Apple ID** of the app (App Information) → put it in `codemagic.yaml` as `APP_STORE_APPLE_ID`

---

## Step 3 — App Store Connect API key (for Codemagic)

1. App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API**  
2. Generate a key with **App Manager** access  
3. Download the `.p8` file **once**  
4. Note **Key ID** + **Issuer ID**

---

## Step 4 — Codemagic (builds on a Mac for you)

1. Sign up: [https://codemagic.io](https://codemagic.io)  
2. Push `nfbot_app` to **GitHub** (or GitLab) if it isn’t already  
3. Codemagic → Add application → select the repo  
4. Team settings → **Integrations** → **Developer Portal** → add API key  
   - Name it exactly: `NFLBOT_ASC` (matches `codemagic.yaml`)  
5. Enable **code signing** / fetch certificates for bundle `com.nfbot.nfbotApp`  
6. Start workflow **NFL BOT — iOS TestFlight**  
7. Wait for green build → IPA uploaded to TestFlight  

Config file in this repo: [`codemagic.yaml`](../codemagic.yaml)

---

## Step 5 — Install on iPhone 15 (TestFlight)

1. iPhone 15 → install **TestFlight** from the App Store  
2. Use the **same Apple ID** as your Developer account (or add yourself as Internal Tester)  
3. Open the TestFlight email/invite → **Install NFL BOT**  
4. App appears on home screen like any store app  

This is the easy install you want — before public App Store approval.

---

## Step 6 — Public App Store (after TestFlight feels good)

In App Store Connect, complete:

- [ ] Privacy Policy URL (required for mic/camera/health-style apps)  
- [ ] Support URL  
- [ ] Description + keywords  
- [ ] Screenshots for **iPhone 6.7"** (iPhone 15 Pro Max size) and **6.1"** (iPhone 15)  
- [ ] App Privacy nutrition labels  
- [ ] Age rating  
- [ ] Review notes (demo account if login is required)  

Then submit **for App Store review**. When **Ready for Sale**, anyone (including you) installs from the public App Store with **Get**.

Optional: in `codemagic.yaml` set `submit_to_app_store: true` only after the listing is complete.

---

## What you do vs what I can do

| You | Me / project |
|-----|----------------|
| Pay Apple Developer | `codemagic.yaml` already added |
| Create App Store Connect app | Bundle ID already `com.nfbot.nfbotApp` |
| Add API key to Codemagic | Permission strings already in `Info.plist` |
| Run Codemagic build | Help fix build errors when logs appear |
| Install via TestFlight on iPhone 15 | Prepare screenshots / store copy on request |

---

## Until Apple is set up — use the web app on iPhone 15

Same Wi‑Fi as your PC:

1. Safari → `http://192.168.0.107:8080`  
2. Share → **Add to Home Screen**  

That is **not** the App Store, but you can use Glass AI Stage today while Developer enrollment + Codemagic run.

---

## Reply when ready

Send me:

1. “Developer account is **Active**” (or “still pending”)  
2. Whether the project is on **GitHub** (repo URL)  
3. When Codemagic fails, paste the **build log error**

Then I’ll walk you through the next click until TestFlight shows **Install** on your iPhone 15.
