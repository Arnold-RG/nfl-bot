# NFL BOT — AI Health Coach

Cross-platform Flutter app with an AI coach named **Bot**.  
Say **“hey bot”** to activate voice coaching.

> Wellness guidance only — not medical diagnosis or treatment.  
> Trademark note: validate “NFL” branding before commercial launch.

## Product

| Area | What it does |
|------|----------------|
| **Today** | Dark bronze home — empty until you act |
| **Diary / Fuel** | Meal scan → analyze → confirm (no demo meals) |
| **Train** | Workouts when you start them |
| **Body** | Private check-ins (empty until you add them) |
| **Bot** | Voice + chat — wake with **hey bot** |
| **You** | Account, privacy, extras |

## Theme

Dark charcoal + bronze accents (`#0C0A09` / `#C4A484`).

## Stack

* **Flutter** (iOS / Android / Web) — `lib/`
* **FastAPI** — `backend/`
* **Marketing site** — `website/` (brown/dark, no concept-art screenshots)

Package ID (Android): `com.nfbot.nfbot_app`  
Bundle ID (iOS): `com.nfbot.nfbotApp`

## Quick start

```bash
flutter pub get
flutter run
```

### Website

```bash
cd website
python -m http.server 5500
# http://127.0.0.1:5500
```

## Security — do not commit

* `android/key.properties`, keystores
* `lib/config/local_secrets.dart` / API keys

## License

Private / all rights reserved unless otherwise stated.
