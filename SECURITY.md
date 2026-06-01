# Security Policy

## Project Status

Ancroo is in early-stage development. The current release (Phase 0 — Functional)
is designed for **local and trusted network use only**. Do not expose Ancroo
services to the public internet without additional security measures.

The phase numbering here matches the [Roadmap](ROADMAP.md).

## Phase 0 Limitations

The following limitations apply to the current release:

- **No TLS encryption by default** — Services communicate over HTTP on the local network. The SSL module exists but is experimental.
- **No authentication** — The backend runs without login (`AUTH_ENABLED=false`); every request is treated as a local admin. SSO/OIDC is not yet available.
- **No rate limiting** — API endpoints have no rate limiting or request throttling.
- **No input sanitization for LLM prompts** — User input is passed to LLMs without prompt injection protection.
- **Default credentials** — Some modules ship with placeholder credentials that must be changed during setup. Never deploy with `CHANGE_ME_*` / `changeme-*` values. (The installer auto-generates real secrets and regenerates placeholder values.)
- **No audit logging** — Execution logs exist but there is no security audit trail.
- **Docker socket access** — The stack requires Docker socket access on the host for service discovery.

## Security Roadmap

| Phase | Features | Status |
|-------|----------|--------|
| Phase 0 | Local/trusted network, HTTP, no auth | **Current** |
| Phase 1 | TLS via Traefik (SSL module) | Experimental |
| Phase 2 | API tokens, rate limiting, input sanitization | Planned |
| Phase 3 | OIDC authentication (SSO module), multi-user | Experimental / not hardened |

## Supported Versions

Security fixes are applied to the latest version on the `main` branch only. There are no LTS or backport branches.

## Reporting a Vulnerability

Please report security vulnerabilities through [GitHub's private vulnerability reporting](https://github.com/ancroo/ancroo/security/advisories/new).

Do not open a public issue for security vulnerabilities.

You can expect an initial response within a few days. If the vulnerability is confirmed, a fix will be released as soon as possible.

## Per-Project Security Notes

| Project | Security Details |
|---------|-----------------|
| [ancroo-stack](https://github.com/ancroo/ancroo-stack) | Network exposure, credentials, firewall — see [Security Guide](https://github.com/ancroo/ancroo-stack/blob/main/docs/security.md) |
| [ancroo-backend](https://github.com/ancroo/ancroo-backend) | API security, auth configuration |
| [ancroo-web](https://github.com/ancroo/ancroo-web) | Browser extension permissions, CSP |
| [ancroo-voice](https://github.com/ancroo/ancroo-voice) | Desktop client, local config files |
