# Emergent AI + Apple App Store (NFL BOT)

## Short answer

**Emergent cannot publish this NFL BOT Flutter project to the App Store as-is.**

| Fact | Detail |
|------|--------|
| Your app | **Flutter** (`nfbot_app`) |
| Emergent mobile | **Expo / React Native only** ([docs](https://help.emergent.sh/mobile-app-development)) |
| Not supported in Emergent | Flutter, native Swift, native Kotlin |
| Apple still requires | Your **Apple Developer** account ($99/yr) |

Emergent is an AI app *builder*. Apple still owns App Store review. Connecting a developer account in Emergent does **not** bypass enrollment or review.

---

## Three realistic options

### Option 1 — Keep Flutter (recommended for *this* codebase)
Use **Codemagic** (already set up in `codemagic.yaml`) → TestFlight → App Store.  
This ships the Glass AI Stage app you already built.

### Option 2 — Rebuild inside Emergent (new Expo app)
1. Go to [emergent.sh](https://emergent.sh) (paid plan for Mobile Agent)  
2. Choose **Mobile app**  
3. Paste a product prompt (see below)  
4. Emergent generates **React Native + Expo** (not your Flutter code)  
5. Connect Apple Developer → use **EAS** (`eas build` / `eas submit`) per Emergent help  
6. TestFlight → App Store  

**Cost:** You rebuild features; Flutter work is a *spec*, not the binary Apple installs.

### Option 3 — Wrap a deployed web URL (Median / similar)
1. Host NFL BOT web (`build/web`) on HTTPS  
2. Use a wrapper (e.g. Median) to make a native shell and upload IPA  
3. Still need Apple Developer + store listing  

Good for “get something on device fast,” weaker for mic / Health / deep native features.

---

## If you still want Emergent — copy/paste prompt

Use this in Emergent **Mobile app** mode:

```text
Build NFL BOT — Glass AI Stage, an AI health & fitness coach for iPhone.

Visual style (exact): dark glassmorphism, neon electric green #22E38A on near-black #05070D.
Center: photoreal studio condenser microphone in a glowing green glass orb (live AI).
Around mic: frosted glass cards — Health Score, Steps, Protein, Upper Body Ready.
Bottom: frosted coach bubble “What should I do now?” and glass tab bar: Home, Train, Add, Track, Coach.

Features:
- Activity / steps dashboard
- Strength training with progressive overload
- Nutrition diary + meal photo estimate
- Recovery / readiness
- Voice AI coach (mic + speech)
- Onboarding: goals, body profile, training experience
- Privacy: wellness only, not medical diagnosis
- Free vs Pro subscription placeholders

Stack: Expo React Native + TypeScript. Prepare for EAS Build and App Store Connect
with bundle id com.nfbot.nfbotApp. Include camera, mic, motion permission strings.
```

Then follow Emergent’s guide:  
[Mobile App Development](https://help.emergent.sh/mobile-app-development) → EAS submit to Apple.

---

## What I recommend for *your* iPhone 15

1. **Keep building NFL BOT in Flutter** (this repo)  
2. Enroll **Apple Developer**  
3. Run **Codemagic** → **TestFlight** → install on iPhone 15  
4. Submit App Store when listing is ready  

Use Emergent only if you accept a **full rebuild** in Expo.

---

## I cannot do from Cursor

- Log into your Emergent account  
- Click “Publish to App Store” on their site  
- Pay Apple or Emergent for you  

I *can* keep preparing Flutter + Codemagic, or draft the Emergent rebuild prompt / store listing.
