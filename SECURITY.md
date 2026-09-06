# Security Policy

## Supported versions
The `main` branch of [Arnold-RG/nfl-bot](https://github.com/Arnold-RG/nfl-bot) is the supported line for fixes.

## Reporting a vulnerability
Please **do not** open a public issue for security-sensitive reports.

Contact the maintainer privately via GitHub: https://github.com/Arnold-RG

Include:
- Description of the issue
- Steps to reproduce
- Impact assessment (if known)

## Secrets
Never commit:
- Android signing keys / `key.properties`
- Cloud API keys
- OAuth client secrets

If a secret is accidentally committed, rotate it immediately and contact the maintainer.
