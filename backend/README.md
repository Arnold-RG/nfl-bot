# NFL BOT Backend

Python **FastAPI modular monolith** for the NFL BOT member app. Modules live in one deployable service (Auth, Users, Nutrition, Training, Activity, Recovery, AI, Social, Billing) — not a microservice mesh.

Docs: [`../docs/PRODUCT_BLUEPRINT.md`](../docs/PRODUCT_BLUEPRINT.md) · [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) · [`../docs/API_CONTRACT.md`](../docs/API_CONTRACT.md)

## Quick start

```bash
cd backend
python -m venv .venv

# Windows PowerShell
.\.venv\Scripts\Activate.ps1

# macOS / Linux
# source .venv/bin/activate

pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

- API: [http://localhost:8000](http://localhost:8000)  
- OpenAPI UI: [http://localhost:8000/docs](http://localhost:8000/docs)  
- Health: [http://localhost:8000/health](http://localhost:8000/health)

## How this links to the Flutter member app and Creator SOC

| Product | Port | Role |
|---------|------|------|
| **Backend (this)** | **8000** | Health Data Platform + engine APIs |
| **Flutter member app** | **8080** | End-user product (`flutter run -d chrome --web-port=8080`) |
| **Creator SOC** | **9090** | Separate ops console (`cd creator_soc && python -m http.server 9090`) |

- The member app should call `http://localhost:8000` (or your deployed API base URL) for profile, nutrition, training, activity, recovery, AI, social, and billing.  
- Creator SOC is **not** embedded in Flutter. It links to the member app by URL only today; later it will call **ops/admin** APIs on this same backend (or a dedicated ops router) with separate creator auth.  
- See `../creator_soc/README.md`.

## Layout

```text
backend/
  README.md
  requirements.txt
  app/
    main.py              # FastAPI app + CORS + /health
    config.py
    api/
      router.py          # mounts all modules
      auth.py
      users.py
      nutrition.py
      training.py
      activity.py
      recovery.py
      ai.py
      social.py
      billing.py
    core/
      health_profile.py  # central HealthProfile models
      events.py          # HealthEvent + source priority
      safety.py          # medical boundary helpers
    services/
      orchestrator.py    # intent → engine stub
```

## Design notes

- Stub endpoints return JSON placeholders with `"meta": {"stub": true}`.  
- `HealthProfile` is the canonical “central brain” schema.  
- AI routes go through the orchestrator + safety helpers (no medical diagnosis).  
- Free vs Pro: do not paywall core health data ownership — see billing entitlements stub.  
