# ancroo — Ecosystem Orchestration & Workflow Definitions

**Language:** Markdown, JSON
**License:** MIT

## Key Files

| File | Purpose |
|------|---------|
| `README.md` | Ecosystem documentation (architecture, services, ports) |
| `ROADMAP.md` | Security maturity roadmap (3 phases) |
| `SECURITY.md` | Vulnerability reporting policy |
| `workflows/` | Example workflow definitions (8 workflows) |
| `workflows/README.md` | Workflow format documentation |
| `assets/icons/` | Canonical brand assets (logos, favicons) |

## Purpose

This is **not** an installer or code repo. It is the canonical source of:
1. **Workflow definitions** — Example workflows importable into ancroo-backend
2. **Brand assets** — Logos/icons copied by other projects
3. **Ecosystem documentation** — Architecture overview, project links

The actual installer (`install.sh`) lives in `ancroo-stack/`.

## Workflow Definitions

8 example workflows in `workflows/`:

| Workflow | Type | Engine |
|----------|------|--------|
| `grammar-fix/` | `text_transformation` | LLM (Ollama) |
| `speech-to-text/` | `speech_to_text` | Whisper/Speaches |
| `html-to-markdown/` | `tool` | ancroo-runner plugin |
| `webpage-to-ebook/` | `tool` | ancroo-runner plugin |
| `contact-form-capture/` | `tool` | n8n webhook |
| `name-formatter/` | `tool` | n8n webhook |
| `freight-calculator/` | `tool` | n8n webhook |
| `patient-registration/` | `tool` | n8n webhook |

**Entity types:** `category`, `llm_model`, `stt_model`, `tool`, `workflow`
**Import order:** category → model/tool → workflow (dependency order)
**Import endpoint:** `POST http://localhost:8900/admin/api/import`

GPU variants: Some workflows have `-rocm` and `-cuda` variants for model definitions.

## Brand Assets

`assets/icons/` — Canonical source for Ancroo logos. Other projects copy from here:
- `ancroo.png` / `ancroo.jpg` — High-res logo
- `icon-{16,48,128}.png` — Favicons

## Ecosystem Map

| Project | Role | Port |
|---------|------|------|
| ancroo-stack | Docker infrastructure | 80 (dashboard) |
| ancroo-backend | Workflow execution API | 8900 |
| ancroo-runner | Deterministic script runner | 8510 |
| ancroo-web | Browser extension | — |
| ancroo-voice | Desktop STT client | — |
| ancroo (this) | Docs + workflow definitions | — |
