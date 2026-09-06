# NFL BOT · Creator SOC

Standalone **creator / admin ops console** for NFL BOT. This is a **separate product** from the Flutter member app — not embedded in Flutter UI, and not built with Flutter.

## What this is

- Static HTML/CSS/JS dashboard (`index.html` + `assets/`)
- Deep navy / electric green SaaS-style ops console
- Seeded mock KPIs, charts, live feed, users, food DB, exercises, AI, subscriptions, challenges, support flags
- Linked to the member app **only by URL** (and later by APIs)

## Serve separately

From this folder:

```bash
cd creator_soc
python -m http.server 9090
```

Open: [http://localhost:9090](http://localhost:9090)

### Member app (unchanged)

Keep the Flutter web member app on its own port, typically:

```bash
# from nfbot_app
flutter run -d chrome --web-port=8080
# or serve an existing build
# python -m http.server 8080   # from build/web
```

| Product        | Port | Path / URL                          |
|----------------|------|-------------------------------------|
| Member app     | 8080 | `http://localhost:8080`             |
| Creator SOC    | 9090 | `http://localhost:9090`             |

## Link between products

- Top bar: **Open member app →**
  - On `localhost` / `127.0.0.1` → `http://localhost:8080`
  - Otherwise → `../build/web/index.html`
- Override anytime before `assets/app.js`:

```html
<script>window.NFLBOT_MEMBER_APP_URL = 'http://localhost:8080';</script>
```

They share **no** Flutter widgets or build pipeline. Future production wiring should be HTTP APIs / auth for creators — not a shared UI shell.

## Layout

```
creator_soc/
  index.html
  README.md
  assets/
    style.css
    app.js
```

## Note

All numbers and tables are **mock operational snapshots** until backend APIs are connected. Do not treat them as live production metrics.
