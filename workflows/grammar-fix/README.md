# Grammar & Spelling

**Type:** `text_transformation` (LLM)
**Hotkey:** `Alt+Shift+G`

Corrects grammar and spelling errors in selected text using an LLM. The corrected text replaces the selection.

## Files

| File | Entity type | Purpose |
|------|-------------|---------|
| `workflow.json` | workflow | Workflow definition |
| `category.json` | category | Category "text" |
| `llm-model.json` | llm_model | Ollama-ROCm provider |
| `demo.html` | — | Interactive demo page |

## Import

```bash
curl -X POST http://localhost:8900/admin/api/import -H "Content-Type: application/json" -d @category.json
curl -X POST http://localhost:8900/admin/api/import -H "Content-Type: application/json" -d @llm-model.json
curl -X POST http://localhost:8900/admin/api/import -H "Content-Type: application/json" -d @workflow.json
```

Import order: category → llm-model → workflow (dependencies first).
