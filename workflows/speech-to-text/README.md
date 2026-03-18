# Speech to Text

**Type:** `speech_to_text` (STT)
**Hotkey:** `Alt+Shift+R`

Records audio and transcribes it to text using Whisper. The transcription is copied to clipboard.

## Files

| File | Entity type | Purpose |
|------|-------------|---------|
| `workflow.json` | workflow | Workflow definition |
| `category.json` | category | Category "voice" |
| `stt-model.json` | stt_model | Whisper-ROCm provider |
| `demo.html` | — | Interactive demo page |

## Import

```bash
curl -X POST http://localhost:8900/admin/api/import -H "Content-Type: application/json" -d @category.json
curl -X POST http://localhost:8900/admin/api/import -H "Content-Type: application/json" -d @stt-model.json
curl -X POST http://localhost:8900/admin/api/import -H "Content-Type: application/json" -d @workflow.json
```

Import order: category → stt-model → workflow (dependencies first).
