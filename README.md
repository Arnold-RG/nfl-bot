# NFL BOT — AI Health Coach

Cross-platform Flutter app: **Glass AI Stage** voice coach + activity, training, nutrition, and recovery — with a FastAPI backend skeleton and Creator SOC console.

> Wellness guidance only — not medical diagnosis or treatment.  
> Trademark note: validate “NFL” branding before commercial launch.

## Product

| Area | What it does |
|------|----------------|
| **Home** | Glass AI Stage — live mic orb + frosted health cards |
| **Train** | Workouts, progressive overload, recovery map |
| **Nutrition** | Diary, macros, meal camera estimates |
| **Track** | Progress / challenges |
| **Coach** | Voice + chat AI (grounded Health Data Platform first) |

Docs: [`docs/PRODUCT_BLUEPRINT.md`](docs/PRODUCT_BLUEPRINT.md) · [`docs/PLAY_STORE_LAUNCH.md`](docs/PLAY_STORE_LAUNCH.md) · [`docs/IPHONE_AND_APP_STORE.md`](docs/IPHONE_AND_APP_STORE.md)

## Stack

- **Flutter** (iOS / Android / Web) — `lib/`
- **FastAPI** modular monolith — `backend/` (port **8000**)
- **Creator SOC** (static ops UI) — `creator_soc/` (port **9090**)

Package ID (Android): `com.nfbot.nfbot_app`  
Bundle ID (iOS): `com.nfbot.nfbotApp`

## Quick start (Flutter)

```bash
cd nfbot_app
flutter pub get
flutter analyze
flutter test
flutter run
```

### Web

```bash
flutter build web --release --no-wasm-dry-run
# serve build/web (e.g. python -m http.server 8080)
```

### Android (Play Store upload)

```bash
# Requires android/key.properties + upload-keystore.jks (local only — never commit)
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

See `android/key.properties.example` and `docs/PLAY_STORE_LAUNCH.md`.

### Backend

```bash
cd backend
python -m venv .venv
# Windows: .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

## Repository layout

```text
lib/            Flutter app
android/ ios/   Native projects
backend/        FastAPI API
creator_soc/    Creator ops console
docs/           Blueprint, store guides, privacy starter
codemagic.yaml  Optional iOS TestFlight CI
```

## Security — do not commit

- `android/key.properties`
- `android/*.jks` / `*.keystore`
- `.env` / API keys
- Desktop signing backup files

## CI

GitHub Actions runs `flutter analyze` + `flutter test` on push (see `.github/workflows/ci.yml`).

## License

Private / all rights reserved unless otherwise stated.
