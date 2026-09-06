# Contributing to NFL BOT

Thanks for your interest in improving NFL BOT.

## Ways to help
- Open an **Issue** for bugs or feature ideas
- Submit a **Pull Request** with a clear description and screenshots when UI changes
- Keep PRs focused (one concern per PR)

## Dev setup
```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Guidelines
- Match existing architecture (Health Data Platform + engines; don’t invent parallel data silos)
- Prefer grounded AI answers over unconstrained LLM replies for health topics
- Never commit secrets (`key.properties`, keystores, `.env`, API keys)
- Wellness copy only — no medical diagnosis claims

## Code of conduct
Be respectful. Harassment or spam will be removed.
