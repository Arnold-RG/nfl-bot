# NFL BOT — Product Development Blueprint

**Product name:** NFL BOT — AI Health Coach  
**Working tagline:** *Given everything about me today, what should I do next?*  
**Audience:** Product, engineering, design, and early investors  
**Status:** Implementation-ready blueprint (vision sections 98–197, organized as build chapters)

> **Trademark note:** Before commercial launch, run trademark/confusion checks on the “NFL” branding. Do not imply affiliation with the National Football League.

---

## 0. Golden rule

**Build the data architecture before fancy AI.**

The AI is only as good as the clean, unified health data underneath it. If steps are duplicated, workouts are not tied to recovery, food quantities are unreliable, or wearable streams are fragmented, even a strong LLM will recommend poorly. The **Health Data Platform** is the company foundation; models and chat are layers on top.

---

## 1. One-sentence investor description

> **NFL BOT is a cross-platform AI health and fitness platform that combines activity tracking, GPS, strength training, progressive overload, nutrition and calorie tracking, AI food recognition, recovery monitoring, wearable data and personalized coaching into one continuously adaptive health system.**

---

## 2. Product architecture (7 engines + Health Data Platform)

At the highest level:

```text
                    NFL BOT
                       │
        ┌──────────────┼──────────────┐
        │              │              │
   ACTIVITY         TRAINING       NUTRITION
    ENGINE           ENGINE          ENGINE
        │              │              │
        └──────────────┼──────────────┘
                       │
                 RECOVERY ENGINE
                       │
                 AI INTELLIGENCE
                       │
              PERSONALIZATION ENGINE
                       │
                 USER EXPERIENCE
```

All engines read/write through a central **NFL BOT Health Data Platform** (not per-feature silos).

| Engine | Job | Inspired by (problem, not UI clone) |
|--------|-----|-------------------------------------|
| Activity | Steps, distance, GPS sessions, NEAT load | “How active am I?” (Pacer-class) |
| Training | Plans, sets/reps/load, RPE, progressive overload | “How should I train?” (Gravl-class) |
| Nutrition | Calories, macros, diary, scanner, barcode | “What am I eating?” (YAZIO-class) |
| Recovery | Sleep, HR/HRV, training load, muscle recovery | Whoop/Oura-class signals |
| AI Intelligence | Orchestrates engines + LLM/vision for coaching | Cross-domain reasoning |
| Personalization | Goals, preferences, failure feedback, adaptive targets | Behavior → better plans |
| UX | Screens, notifications, share cards, retention loops | Habit formation |

**Competitive wedge:** not “we have a chatbot,” but *understanding relationships between behaviors* (e.g. high steps + hard legs yesterday + short sleep + low calories → do not prescribe another hard leg day).

---

## 3. Central user health profile (the brain schema)

Every feature feeds one profile. Do not give each feature its own isolated source of truth.

```text
USER PROFILE
│
├── Personal — age, sex, height, weight, locale
├── Goals — fat loss / muscle / strength / fitness / health / maintain
├── Activity — steps, distance, running, walking, cycling, GPS sessions
├── Nutrition — calories, protein, carbs, fat, water, allergies, preferences
├── Training — exercises, sets, reps, weight, RPE, equipment, experience
├── Recovery — sleep, HR, HRV, training load, muscle recovery map
└── AI Profile — preferences, behavior signals, recommendations, feedback
```

Canonical backend model: `backend/app/core/health_profile.py` (`HealthProfile`). Flutter should eventually mirror this shape in sync payloads.

---

## 4. The NFL BOT data loop

Every user action must produce useful, joinable data:

```text
+4,000 steps
    → Activity Engine (progress toward step goal)
    → Calories / energy context updates
    → Recovery Engine receives activity load
    → Nutrition Engine adjusts daily energy context
    → Training Engine sees today’s NEAT / fatigue
    → AI Coach makes a better next recommendation
```

**Complete product loop:**

```text
USER → AI BRAIN → ACTIVITY / NUTRITION / TRAINING
                 → RECOVERY (sleep / HR / load)
                 → AI DECISION → PERSONALIZED PLAN → USER
```

**MVP core loop (must work end-to-end before feature sprawl):**

```text
Wake → health import → AI status → calorie target → log food
    → train → record workout → steps import → recovery update → AI daily summary
```

---

## 5. Onboarding, permissions, medical boundary

### Registration
- Email/password
- Continue with Apple / Google (Facebook optional)
- Minimize forms before first useful Home experience

### First ~5 minutes
1. Main goal (single): lose fat / build muscle / get stronger / healthier / fitness / maintain  
2. Multi-select: what NFL BOT should help with  
3. Body profile: sex, age, height, weight  
4. Training profile: experience, equipment, days/week  
5. Realistic goals (conservative rate of change)  
6. Connect devices (skippable)  
7. Permission Center (explain *why* before OS prompts)

### Permission categories
| Category | Examples | Principle |
|----------|----------|-----------|
| Motion / health | steps, workouts, sleep, HR | Just-in-time; show value first |
| Location | GPS runs/walks | Only when starting a GPS session |
| Camera | food photo | Explicit per-use |
| Notifications | plans, reminders | Preference + quiet hours |
| Bluetooth / wearables | watch pairing | Optional; estimates labeled until linked |

### Medical boundary (non-negotiable)
> NFL BOT provides wellness and fitness guidance and is **not** a substitute for professional medical advice, diagnosis, or treatment.

- No diagnosis language  
- Serious symptoms → redirect to appropriate medical care  
- Allergies are **high-priority programmatic restrictions**, not LLM-only checks  
- UI must label estimates when no wearable / incomplete data  

---

## 6. Screen-by-screen UX

### Home (most important screen)
Greeting, Health/Wellness Score, recovery, sleep, steps, calories burned/remaining, readiness, water, streak, today’s AI plan, nutrition bars, coach brief, **What should I do now?**, water quick-add.  
Interactive cards deep-link into Activity / Nutrition / Train / Recovery.

### Train
Today’s plan, muscle recovery map, equipment/experience context, start workout.  
Before workout: readiness + plan rationale.  
During: sets/reps/load/RPE, substitution, injury/pain safety (reduce/stop guidance).  
After: auto-progression preview (deterministic), history, PRs.

### Nutrition
Diary, macros, remaining energy, water, fasting (optional).  
Add food: search / recent / favorites / camera / barcode.  
AI camera = **editable estimates**. Restaurant mode and meal planner are later-tier.

### Recovery
Sleep summary, HR/HRV trends (when available), training load, muscle recovery map, recovery % and readiness. Soft guidance only.

### Activity / GPS
Steps goal, distance, activity list, GPS session (walk/run/cycle), post-activity analysis (pace, elevation, HR if available).

### Social (v2+)
Friends, challenges, leaderboards, friend profiles (consent-scoped). Share cards for PRs and streaks (viral loop).

### AI Coach
Chat + voice entry points; Morning AI briefing; daily plan; weekly/monthly reviews that **explain themselves** (why this recommendation). Memory is profile-backed, not opaque chat history alone.

---

## 7. AI architecture

```text
USER QUESTION
     ↓
SAFETY FILTER
     ↓
DATA RETRIEVAL (Health Data Platform)
     ↓
RULE / DETERMINISTIC ENGINES
     ↓
LLM / VISION (when needed)
     ↓
SAFETY CHECK + MEDICAL BOUNDARY
     ↓
USER
```

### Orchestrator
Routes intent to the right system:

| Intent | Handler |
|--------|---------|
| “What’s in this food?” | Vision (+ nutrition DB) |
| “What should I eat?” | Nutrition engine + LLM |
| “What should I bench next week?” | Training algorithm (deterministic) |
| “Explain my progress.” | Analytics + LLM |
| “What should I do now?” | Orchestrator over full day state |

### Deterministic vs LLM
- **Deterministic first:** calorie targets, progressive overload from RPE/recovery, allergy blocks, source priority, dedupe, readiness scores  
- **LLM second:** natural language coaching, explanations, meal ideas within safe bounds  
- **Learn from failure:** store Recommended vs Actual (e.g. 60×10 prescribed → 60×7 @ RPE 10) and adjust next plan  

Signature features: **Morning AI**, **What should I do now?**, adaptive calories (multi-week weight trend, not noisy daily swings), adaptive training.

---

## 8. Deduplication and source priority

Every health event carries: **source**, **timestamp**, **confidence**, **processing status**.

### Source priority (example order — tune per metric)
1. Direct wearable (Apple Watch / Wear OS / Garmin, etc.)  
2. Platform store (HealthKit / Health Connect)  
3. GPS session logged in-app  
4. Manual entry  
5. Estimate / model inference  

### Deduplication
Same activity from Watch + Strava (or HealthKit + in-app) → merge by time window, type, duration, distance, HR, source IDs. Never double-count calories/steps.

---

## 9. Backend stack recommendation

**Start: modular monolith** (not 50 microservices).

```text
NFL BOT Backend
├── Auth
├── Users
├── Nutrition
├── Training
├── Activity
├── Recovery
├── AI
├── Social
└── Billing
```

| Layer | Choice (v1) |
|-------|-------------|
| API | Python FastAPI (`backend/`) |
| Primary DB | PostgreSQL |
| Cache / queues | Redis |
| Media | Object storage + CDN (food images, progress photos, exercise video) |
| Search (later) | OpenSearch / Elasticsearch (foods, exercises, recipes) |
| AI | Orchestrator service inside monolith initially; extract under load |

Split services only when a module proves high-load or independent scaling needs.

**Creator SOC** (`creator_soc/`, port **9090**) is a **separate ops console** — linked by URL/API only, never embedded in the Flutter member shell.

---

## 10. Flutter + native bridges

**App:** Flutter (one codebase for iOS/Android/web).

**Native bridges (platform channels / plugins):**

| Platform | Native | Responsibilities |
|----------|--------|------------------|
| iOS | Swift | HealthKit, Apple Watch, Core Motion, Core Location |
| Android | Kotlin | Health Connect, Wear OS, activity recognition, location |

Flutter owns UX and engines; native owns sensor accuracy and OS health permissions.

Current app module map lives under `lib/` (see [ARCHITECTURE.md](./ARCHITECTURE.md)).

---

## 11. Offline and sync

- **Offline mode:** log food, complete workouts, track steps locally; queue mutations  
- **Sync engine:** conflict rules favor higher-priority source + newer verified timestamp; never silently drop user-owned diary/workout entries  
- Label “pending sync” in UI; Health Data Platform is the merge authority on reconnect  

---

## 12. Free vs Pro (do not paywall core health data)

| Always free (user-owned) | Pro / advanced intelligence |
|--------------------------|-----------------------------|
| Steps, logged meals, workouts, weight history | Unlimited AI coaching |
| Basic diary & basic workouts | AI food scanner, advanced overload |
| Basic progress & limited AI Q&A | Deep recovery analytics, recipes, advanced personalization, multi-wearable polish |

**Rule:** Charge for advanced intelligence and convenience — **never** for ownership of the user’s own steps, meals, workouts, or weight history.

### Revenue (later)
Subscriptions (primary), trainer accounts, gym partnerships, corporate wellness, premium AI, optional marketplace — all with privacy-first B2B dashboards (no raw individual health to employers without explicit appropriate consent).

---

## 13. Team and 12-month timeline

### Team (~7–8, combinable early)
1 PM · 1 UI/UX · 2 Flutter · 1 Backend · 1 AI/ML · 1 QA · 1 DevOps

### Timeline

| Months | Focus |
|--------|--------|
| 1–2 | Product design, architecture, DB, auth, UI system |
| 3–4 | Activity, nutrition, food DB, workout logging |
| 5–6 | AI orchestrator stubs, HealthKit/Health Connect, camera, barcode |
| 7–8 | Recovery, progressive overload, analytics, notifications |
| 9–10 | Testing, security, performance, store prep |
| 11–12 | Beta, bugfix, launch |

Why this long: you are shipping a **health-data platform** + fitness app + nutrition DB + AI + wearables + (later) social + subscription business — not a single-screen calorie counter.

---

## 14. Roadmap: MVP → v4

| Version | Scope |
|---------|--------|
| **MVP 1.0** | Activity + nutrition + workout + AI coach + basic health import — **perfect the core loop** |
| **1.5** | AI food recognition, barcode, GPS, progressive overload, better recovery, Watch / Wear OS |
| **2.0** | Social, challenges, leaderboards, recipes, grocery list, strength score, advanced reports |
| **3.0** | Form analysis, trainer marketplace, gym partnerships, corporate wellness, more wearables |
| **4.0 / “NFL BOT OS”** | Platform where food, exercise, movement, recovery, wearables, AI, goals, and social all meet |

---

## 15. Retention loop, viral loop, share cards

### Retention
```text
Morning → recovery → today’s plan → eat/log → train → activity
       → AI feedback → weekly progress → return tomorrow
```

**North-star metric:** weekly active users who complete **meaningful health actions** (e.g. log food + walk + train) — not downloads alone.

### Viral
PR / streak / challenge finish → **premium minimal share card** → Instagram / TikTok / WhatsApp / X → friend downloads.

### Share card example
```text
NFL BOT
NEW PERSONAL RECORD
BENCH PRESS · 80 KG · +5 KG
6 SEPTEMBER 2026
KEEP BUILDING.
```

---

## 16. Trainer / Gym / Corporate (later)

| Mode | Value | Constraint |
|------|-------|------------|
| Trainer | Client workouts, nutrition compliance, recovery, program builder | Client consent, role-based access |
| Gym | Club profile, equipment, member challenges | Aggregate-first dashboards |
| Corporate | Company wellness KPIs | **No raw individual health** without explicit, appropriate consent |

---

## 17. What “done” looks like for the full product

One app delivering: movement, nutrition, training, recovery, body metrics, AI coaching, gamification, social, wearables, analytics, and privacy controls — **all feeding one adaptive brain**.

**Build order reminder:** Health Data Platform → deterministic engines → sync/dedupe → then rich AI UX.

---

## Related docs

- [ARCHITECTURE.md](./ARCHITECTURE.md) — system design for engineers  
- [API_CONTRACT.md](./API_CONTRACT.md) — MVP REST surface  
- `../backend/README.md` — run the modular FastAPI skeleton  
- `../creator_soc/README.md` — separate Creator SOC on port 9090  
