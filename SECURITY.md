# Security Policy

## Scope

This policy covers the **archived self-hosted stack**: ancroo-stack, ancroo-backend,
ancroo-runner, ancroo-voice and ancroo-web-backend.

The active projects have their own security policies:

- [Ancroo Web](https://github.com/ancroo/ancroo-web/blob/main/SECURITY.md)
- [Ancroo Crew](https://github.com/ancroo/ancroo-crew/blob/main/SECURITY.md)

## Status of the archived stack

The stack's last state is Phase 0 — Functional: designed for **local and trusted
network use only**. Do not expose its services to the public internet without
additional security measures. The phase numbering matches the [Roadmap](ROADMAP.md).

## Phase 0 Limitations

The following limitations apply to the archived stack:

- **No TLS encryption by default** — Services communicate over HTTP on the local network. The SSL module exists but is experimental.
- **No authentication** — The backend runs without login (`AUTH_ENABLED=false`); every request is treated as a local admin. SSO/OIDC is not yet available.
- **No rate limiting** — API endpoints have no rate limiting or request throttling.
- **No input sanitization for LLM prompts** — User input is passed to LLMs without prompt injection protection.
- **Default credentials** — Some modules ship with placeholder credentials that must be changed during setup. Never deploy with `CHANGE_ME_*` / `changeme-*` values. (The installer auto-generates real secrets and regenerates placeholder values.)
- **No audit logging** — Execution logs exist but there is no security audit trail.
- **Docker socket access** — The stack requires Docker socket access on the host for service discovery.

## Security Roadmap (on hold)

| Phase | Features | Status |
|-------|----------|--------|
| Phase 0 | Local/trusted network, HTTP, no auth | **Last state** |
| Phase 1 | TLS via Traefik (SSL module) | Experimental |
| Phase 2 | API tokens, rate limiting, input sanitization | Planned |
| Phase 3 | OIDC authentication (SSO module), multi-user | Experimental / not hardened |

## Supported Versions

None. The stack repositories are archived and receive no fixes, including security
fixes.

## Reporting a Vulnerability

Please report security vulnerabilities through [GitHub's private vulnerability reporting](https://github.com/ancroo/ancroo/security/advisories/new).

Do not open a public issue for security vulnerabilities.

You can expect an initial response within a few days. Since the stack is archived, a confirmed vulnerability will not be fixed, but it may be documented here as a known issue.

## Per-Project Security Notes

| Project | Security Details |
|---------|-----------------|
| [ancroo-stack](https://github.com/ancroo/ancroo-stack) | Network exposure, credentials, firewall — see [Security Guide](https://github.com/ancroo/ancroo-stack/blob/main/docs/security.md) |
| [ancroo-backend](https://github.com/ancroo/ancroo-backend) | API security, auth configuration |
| [ancroo-voice](https://github.com/ancroo/ancroo-voice) | Desktop client, local config files |
