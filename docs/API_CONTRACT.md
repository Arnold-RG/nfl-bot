# NFL BOT — API Contract (MVP)

REST-ish surface for the FastAPI modular monolith in `backend/`.  
All endpoints below are **stubs** in the skeleton unless noted; shapes are stable enough for Flutter client scaffolding.

**Base URL (local):** `http://localhost:8000`  
**Auth (MVP stub):** `Authorization: Bearer <token>` where indicated; stubs may accept missing tokens and return demo payloads.

Response convention:

```json
{
  "ok": true,
  "data": { },
  "meta": { "stub": true }
}
```

Errors:

```json
{
  "ok": false,
  "error": { "code": "string", "message": "string" }
}
```

---

## System

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/health` | Liveness / version for app and SOC probes |
| GET | `/` | Service metadata + links to OpenAPI |

---

## Auth — `/auth`

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/auth/register` | Email/password registration |
| POST | `/auth/login` | Issue access + refresh tokens (stub) |
| POST | `/auth/refresh` | Refresh access token |
| POST | `/auth/logout` | Invalidate refresh token (stub) |
| POST | `/auth/oauth/{provider}` | Apple / Google / Facebook start or code exchange (stub) |

---

## Users — `/users`

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/users/me` | Current user account summary |
| GET | `/users/me/profile` | Full `HealthProfile` (central brain) |
| PUT | `/users/me/profile` | Replace/update profile sections |
| PATCH | `/users/me/goals` | Update goals only |
| GET | `/users/me/consents` | Consent category flags |
| PUT | `/users/me/consents` | Update consents |
| DELETE | `/users/me` | Account deletion request (stub) |

---

## Nutrition — `/nutrition`

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/nutrition/today` | Today’s diary summary (calories/macros/water) |
| GET | `/nutrition/diary` | Diary by `?date=YYYY-MM-DD` |
| POST | `/nutrition/meals` | Log a meal / food entry |
| PATCH | `/nutrition/meals/{meal_id}` | Edit quantities (incl. vision estimate correction) |
| DELETE | `/nutrition/meals/{meal_id}` | Remove meal |
| POST | `/nutrition/water` | Add water intake |
| GET | `/nutrition/targets` | Daily calorie/macro targets |
| POST | `/nutrition/vision` | Submit food image metadata → estimate stub |
| GET | `/nutrition/foods/search` | Search food DB stub `?q=` |
| GET | `/nutrition/barcode/{code}` | Barcode lookup stub |

---

## Training — `/training`

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/training/today` | Today’s workout plan |
| POST | `/training/sessions` | Start / complete a session payload |
| GET | `/training/sessions` | Session history |
| GET | `/training/sessions/{session_id}` | Session detail |
| POST | `/training/overload` | Deterministic progressive-overload suggestion |
| GET | `/training/prs` | Personal records stub |
| POST | `/training/substitute` | Exercise substitution stub |

---

## Activity — `/activity`

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/activity/today` | Steps, distance, calories estimate |
| POST | `/activity/steps` | Ingest step sample / daily total |
| POST | `/activity/sessions` | Log GPS or manual activity session |
| GET | `/activity/sessions` | List recent activity sessions |
| POST | `/activity/events` | Batch wearable/HealthKit/Health Connect events |
| POST | `/activity/dedupe/preview` | Preview merge candidates (stub) |

---

## Recovery — `/recovery`

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/recovery/today` | Recovery %, readiness, sleep summary |
| POST | `/recovery/sleep` | Ingest sleep session |
| GET | `/recovery/muscle-map` | Per-muscle recovery stub |
| POST | `/recovery/vitals` | HR / HRV samples stub |

---

## AI — `/ai`

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/ai/orchestrate` | Route intent → engine / LLM stub |
| GET | `/ai/morning` | Morning AI briefing |
| POST | `/ai/now` | “What should I do now?” |
| GET | `/ai/daily-plan` | Timed day plan stub |
| POST | `/ai/chat` | Coach chat turn (safety-wrapped stub) |
| GET | `/ai/weekly-review` | Weekly review stub |

---

## Social — `/social` (MVP stubs; full product in v2)

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/social/friends` | Friend list stub |
| POST | `/social/friends/request` | Friend request stub |
| GET | `/social/challenges` | Active challenges stub |
| POST | `/social/challenges/{id}/join` | Join challenge stub |
| POST | `/social/share-cards` | Generate share-card payload stub |

---

## Billing — `/billing`

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/billing/plan` | Free vs Pro entitlements |
| POST | `/billing/checkout` | Start checkout (stub) |
| POST | `/billing/webhook` | Provider webhook placeholder |
| GET | `/billing/entitlements` | Feature flags for client gating |

**Entitlement rule:** core health data (steps, meals, workouts, weight history) remains readable on Free; Pro gates advanced intelligence features.

---

## Creator SOC (ops) — future, not in member MVP routers

Linked by URL today (`http://localhost:9090`). Future ops routes may live under `/ops/*` with separate auth — **not** exposed to the member app binary.

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/ops/health` | SOC-facing API health (future) |
| GET | `/ops/metrics/summary` | Aggregate KPIs (future) |

---

## Versioning

- MVP: unversioned paths as above.  
- When breaking: introduce `/v1/` prefix and freeze this document as `v0` stubs.  
