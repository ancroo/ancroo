# Roadmap

Ancroo is a side project under active development. This roadmap describes the security maturity path — not a timeline, but a structured direction.

## Phases

### Phase 0 — Functional *(current)*

Everything works, workflows run end-to-end, but there is no encryption or authentication. Intended for trusted local networks only.

| What's done | Status |
|-------------|--------|
| Docker stack with modular architecture | Beta |
| AI workflow engine (LLM, STT, n8n, custom) | Beta |
| Browser extension (text selection, hotkeys, push-to-talk) | Beta |
| Desktop push-to-talk STT client | Beta |
| Plugin-based script runner | Beta |
| Meta-installer (one command setup) | Beta |
| Example workflows (grammar fix, speech-to-text, form capture) | Working |

> **Use case:** Home labs, VPNs, local networks, single-user setups.

### Phase 1 — Encrypted

TLS everywhere. Internal services isolated from external access.

- HTTPS via Traefik reverse proxy with Let's Encrypt certificates
- DNS-01 validation (INWX, Cloudflare, Route53)
- Docker network isolation (internal services not exposed on host ports)
- Wildcard certificates for all subdomains

> **Status:** SSL module exists and is experimental. Not yet validated end-to-end.

### Phase 2 — Protected

API endpoints secured with tokens. Abuse protection in place.

- API keys / bearer tokens per service
- Rate limiting on public endpoints
- Input sanitization (prompt injection, XSS)
- Audit logging (who called what, when)

> **Status:** Backend supports `AUTH_ENABLED` and API keys. Rate limiting and input sanitization not yet implemented.

### Phase 3 — Multi-User

Central identity management. User-scoped data and permissions.

- SSO via Keycloak (OAuth2/OIDC)
- Single login across all services (Open WebUI, Backend, n8n, BookStack)
- Per-user workflow history and data isolation
- Role-based access (admin vs. user)
- OAuth2 PKCE for the browser extension

> **Status:** SSO module exists and is experimental. Backend has OIDC scaffolding, extension has PKCE flow. Not yet tested as a complete system.

## What's orthogonal

These improvements are not tied to a specific phase and will be addressed as needed:

- **Documentation** — user guides, API docs, deployment guides
- **CI/CD** — automated builds, tests, releases
- **Performance** — caching, connection pooling, async processing
- **New workflows** — community contributions, templates

## Non-goals

- Deadlines or release dates — this is an unpaid side project
- SaaS / hosted offering
- Supporting non-Docker deployments
