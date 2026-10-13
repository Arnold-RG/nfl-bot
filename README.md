<p align="center">
  <img src="docs/screenshots/00-banner.png" alt="Elvora — Say hey elvora" width="920"/>
</p>

<h1 align="center">ELVORA</h1>

<p align="center">
  <strong>Premium AI fitness & nutrition.</strong><br/>
  A personal trainer, nutritionist, wellness assistant, and health dashboard — simple enough for every day.
</p>

<p align="center">
  <a href="https://arnold-rg.github.io/nfl-bot/"><img src="https://img.shields.io/badge/Live_site-GitHub_Pages-C9A27A?style=for-the-badge&logo=github" alt="Live site"/></a>
  <a href="https://arnold-rg.github.io/nfl-bot/app/"><img src="https://img.shields.io/badge/Try_web_app-Open-E08A45?style=for-the-badge&logo=flutter" alt="Web app"/></a>
  <a href="https://github.com/Arnold-RG/nfl-bot"><img src="https://img.shields.io/badge/Repo-Public-0A0908?style=for-the-badge&logo=github" alt="Public repo"/></a>
</p>

<p align="center">
  <img src="https://img.shields.io/github/actions/workflow/status/Arnold-RG/nfl-bot/deploy-pages.yml?label=Pages%20deploy&style=flat-square" alt="CI"/>
  <img src="https://img.shields.io/badge/Flutter-iOS%20%7C%20Android%20%7C%20Web-02569B?style=flat-square&logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Wake%20phrase-hey%20elvora-E08A45?style=flat-square" alt="Wake"/>
</p>

---

## Product

Elvora is not a calorie counter with extra screens. It is a connected health and performance platform:

| Pillar | What you get |
|--------|----------------|
| **Fitness intelligence** | Adaptive workouts, logging, GPS, form demos |
| **Smart nutrition** | Diary, plate scan (confirm before save), meal plans |
| **Personal AI coach** | Voice + chat — wake with **hey elvora** |
| **Health insights** | Sleep, hydration, readiness, progress |

**Product rule:** if a number is on screen, you put it there — or a connected sensor did.

> Wellness guidance only — not medical diagnosis or treatment.

---

## Try it

| | Link |
|---|---|
| **Marketing site** | https://arnold-rg.github.io/nfl-bot/ |
| **Web app** | https://arnold-rg.github.io/nfl-bot/app/ |
| **Privacy** | https://arnold-rg.github.io/nfl-bot/privacy.html |
| **Source** | https://github.com/Arnold-RG/nfl-bot |

---

## App structure

Five destinations so the product stays simple as it grows:

```text
Home      Daily overview, next best action, quick log
Train     Plans, library, GPS, session history
Nutrition Diary, macros, meals, recipes, water
Coach     Voice, chat, plans you can edit
Progress  Analytics, photos, recovery, export
```

Profile, devices, privacy, and subscriptions live under You / Account.

Wake the coach with **“hey elvora”**. The geometric signal mark reacts while listening, thinking, and speaking.

---

## What’s in this repository

```text
lib/                 Flutter app
website/             Marketing site (GitHub Pages)
docs/                Architecture, store drafts, screenshots
backend/             FastAPI companion (optional)
.github/workflows/   Pages deploy (site + Flutter web)
```

Full visual index → **[docs/SHOWCASE.md](docs/SHOWCASE.md)**

---

## Disclaimer

Elvora is a wellness / fitness product. It is not intended for medical diagnosis or treatment.
