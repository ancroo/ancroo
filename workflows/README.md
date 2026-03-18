# Ancroo Workflows

This directory contains workflow definition files (`metadata.json`) that can be
imported into the Ancroo backend.  Each workflow lives in its own subdirectory.

The metadata format maps directly to the **Three-Area database schema** (Migration
015): workflows reference LLM models, STT models, or tools as their execution
target.

---

## Table of Contents

- [How it works](#how-it-works)
- [Directory structure](#directory-structure)
- [metadata.json reference](#metadatajson-reference)
  - [Top-level fields](#top-level-fields)
  - [workflow\_type values](#workflow_type-values)
  - [output\_action values](#output_action-values)
  - [recipe object](#recipe-object)
  - [LLM-specific fields](#llm-specific-fields)
  - [tool object](#tool-object)
- [Example workflows](#example-workflows)
  - [grammar-fix](#grammar-fix)
  - [speech-to-text](#speech-to-text)
  - [html-to-markdown](#html-to-markdown)
  - [contact-form-capture](#contact-form-capture)
- [Creating a new workflow](#creating-a-new-workflow)
- [Environment variables](#environment-variables)

---

## How it works

Workflows are imported into the backend via the admin API:

1. **Via the admin GUI:** Upload a `metadata.json` at
   **Admin → Import Workflow**.
2. **Via script:** Run `bash lib/setup-workflows.sh [HOST_IP]` to import all
   workflows at once.  The script POSTs each `metadata.json` to
   `POST /admin/api/import-workflow`.
3. **Via curl:**
   ```bash
   curl -X POST http://localhost:8900/admin/api/import-workflow \
     -H "Content-Type: application/json" \
     -d @workflows/grammar-fix/metadata.json
   ```

The import endpoint is **idempotent** — importing the same file twice results
in `already_exists` (no duplicate created).

**What happens during import:**

1. The JSON file is parsed and a `Workflow` record is created in the database
   with `execute` permissions for `standard-users` and `admin-users`.
2. For `text_transformation` workflows: a default LLM model entry is created
   if none exists.
3. For `speech_to_text` workflows: a default STT model entry is created.
4. For `tool` workflows with `tool.tool_type: "n8n_webhook"`: an n8n webhook
   flow is created and activated automatically (if `N8N_API_KEY` is configured).
   A `tools` table entry is created with the webhook URL.
5. For `tool` workflows with `tool.tool_type: "ar_plugin"`: a `tools` table
   entry is created with the endpoint URL.

After import, all workflow data lives exclusively in the database.  The JSON
files are only needed for the initial import — they are not read at runtime.

---

## Directory structure

```
workflows/
├── README.md                      ← this file
├── grammar-fix/
│   ├── metadata.json
│   └── demo.html
├── speech-to-text/
│   ├── metadata.json
│   └── demo.html
├── html-to-markdown/
│   ├── metadata.json
│   └── demo.html
├── webpage-to-ebook/
│   └── metadata.json
├── contact-form-capture/
│   ├── metadata.json
│   └── demo.html
├── name-formatter/
│   ├── metadata.json
│   ├── demo.html
│   └── n8n-workflow.json
└── freight-calculator/
    ├── metadata.json
    ├── demo.html
    └── n8n-workflow.json
```

Each subdirectory contains a `metadata.json` with a unique `slug` field and
optionally a `demo.html` page for testing the workflow via the browser extension.
Import workflows via the Admin GUI (Import page) — drop the folder or select
both files. The `demo.html` is stored in the database and served at
`/admin/workflows/{slug}/demo`.

---

## metadata.json reference

### Top-level fields

| Field | Type | Required | DB column | Description |
|---|---|---|---|---|
| `slug` | string | **yes** | `workflows.slug` | URL-safe identifier, unique across all workflows. |
| `name` | string | **yes** | `workflows.name` | Human-readable display name. |
| `description` | string | no | `workflows.description` | Short description shown in admin GUI and extension tooltip. |
| `category` | string | no | `workflows.category` | Groups workflows. Common values: `text`, `voice`, `automation`. |
| `workflow_type` | string | **yes** | `workflows.workflow_type` | Determines execution target. See [workflow\_type values](#workflow_type-values). |
| `output_action` | string | no | `workflows.output_action` | What the extension does with the result. See [output\_action values](#output_action-values). |
| `default_hotkey` | string | no | `workflows.default_hotkey` | Pre-configured keyboard shortcut, e.g. `"Alt+Shift+G"`. |
| `timeout_seconds` | int | no | `workflows.timeout_seconds` | Execution timeout (default: 60). |
| `demo_url` | string | no | `workflows.demo_url` | Relative path to demo page (usually `"demo.html"`). |
| `is_example` | bool | no | *(import only)* | Marks example workflows shipped with the installer. |
| `recipe` | object | no | `workflows.recipe` | Input collection spec. See [recipe object](#recipe-object). |
| `prompt_template` | string | no | `workflows.prompt_template` | Jinja2 prompt template (LLM workflows only). |
| `temperature` | float | no | `workflows.temperature` | Sampling temperature 0.0–1.0 (LLM workflows only). |
| `tool` | object | no | → `tools` table | Tool definition (tool workflows only). See [tool object](#tool-object). |

### workflow\_type values

Each workflow has exactly one execution target, enforced by a CHECK constraint
in the database (`num_nonnulls(llm_model_id, stt_model_id, tool_id) <= 1`).

| Value | Execution target | Description |
|---|---|---|
| `text_transformation` | LLM model | LLM-powered text editing. Extension sends text, gets transformed text back. |
| `speech_to_text` | STT model | Audio transcription via Whisper-compatible server. |
| `tool` | Tool (AR plugin, n8n webhook, custom API) | Delegates to an external tool. |

### output\_action values

| Value | What the extension does with the result |
|---|---|
| `replace_selection` | Replaces the selected text with the workflow output. |
| `clipboard` | Copies the result to the clipboard. |
| `notification` | Shows a brief notification popup. |
| `fill_fields` | Writes result values back into form fields using `recipe.output_fields` selectors. |
| `download_file` | Decodes base64 result and triggers a browser file download. |
| `none` | No client-side action (fire-and-forget). |

### recipe object

The `recipe` defines what the extension collects before executing the workflow.
Stored as JSONB in `workflows.recipe`.

| Field | Type | Description |
|---|---|---|
| `collect` | array | What to collect. Values: `text_selection`, `clipboard`, `page_context`, `page_html`, `form_fields`, `audio`. |
| `form_fields` | array | CSS selector definitions for form input. Each entry: `{"name": "...", "selector": "..."}`. |
| `output_fields` | array | CSS selector definitions for result output (used with `fill_fields`). Same format. |
| `audio_accept` | string | MIME type filter for audio input (default: `"audio/*"`). |
| `audio_max_size_mb` | int | Maximum audio file size in MB (default: 50). |

**collect values:**

| Value | What is collected |
|---|---|
| `text_selection` | Currently selected text in the browser. |
| `clipboard` | Current clipboard content. |
| `page_context` | Current page URL and title. |
| `page_html` | Full page HTML. |
| `form_fields` | DOM values from CSS selectors defined in `form_fields`. |
| `audio` | Audio recording from the device microphone. |

Multiple sources can be combined in the array.

### LLM-specific fields

Used when `workflow_type` is `"text_transformation"`:

| Field | Type | Default | DB column | Description |
|---|---|---|---|---|
| `prompt_template` | string | — | `workflows.prompt_template` | **Required.** Jinja2 template. Variables: `{{ text }}`, `{{ url }}`, `{{ title }}`, `{{ clipboard }}`, `{{ fields }}`. |
| `temperature` | float | `0.3` | `workflows.temperature` | Sampling temperature 0.0–1.0. Lower = more deterministic. |

The LLM model is assigned during import (or via admin GUI), not in the metadata
file. The workflow references `llm_model_id` in the database.

### tool object

Used when `workflow_type` is `"tool"`. Creates an entry in the `tools` database
table and links it via `workflows.tool_id`.

**For AR plugins / custom APIs:**

| Field | Type | Required | DB column | Description |
|---|---|---|---|---|
| `name` | string | **yes** | `tools.name` | Display name. |
| `tool_type` | string | **yes** | `tools.tool_type` | `"ar_plugin"`, `"n8n_webhook"`, or `"custom_api"`. |
| `endpoint_url` | string | **yes** | `tools.endpoint_url` | Full URL of the tool endpoint. |
| `http_method` | string | no | `tools.http_method` | HTTP method (default: `"POST"`). |
| `headers` | object | no | `tools.headers` | HTTP headers. |
| `payload_template` | string | no | `tools.payload_template` | Jinja2 template for JSON body. Variables: `{{ text }}`, `{{ html }}`, `{{ url }}`, `{{ title }}`, `{{ fields }}`, `{{ clipboard }}`. |
| `response_mapping` | string | no | `tools.response_mapping` | JSONPath for result extraction (e.g. `"$.result"`). |
| `timeout` | int | no | `tools.timeout` | Request timeout in seconds (default: 120). |

**For n8n webhooks:**

| Field | Type | Required | DB column | Description |
|---|---|---|---|---|
| `name` | string | **yes** | `tools.name` | Display name. |
| `tool_type` | string | **yes** | `tools.tool_type` | Must be `"n8n_webhook"`. |
| `n8n_workflow_name` | string | no | *(import only)* | Display name for the auto-created n8n workflow. |

The `endpoint_url` and `n8n_flow_id` are set automatically during import when
the n8n webhook flow is provisioned.

### Demo page (demo.html)

Each workflow can include a `demo.html` file alongside `metadata.json`. This
is a standalone HTML page with form fields matching the workflow's CSS selectors.
It is imported into the database and served at `/admin/workflows/{slug}/demo`.

The demo page allows testing the workflow end-to-end: open the page, activate
the Ancroo extension, select the workflow, and click Execute.

---

## Example workflows

### grammar-fix

**Type:** `text_transformation` (LLM)

Corrects grammar and spelling in selected text using an LLM.  The corrected
text directly replaces the selection in the browser.

| Property | Value |
|---|---|
| Input | `recipe.collect: ["text_selection"]` |
| Output | `replace_selection` |
| Hotkey | `Alt+Shift+G` |

### speech-to-text

**Type:** `speech_to_text` (STT)

Records audio via the browser and transcribes it to text using a Whisper-
compatible server.  The transcript is copied to the clipboard.

| Property | Value |
|---|---|
| Input | `recipe.collect: ["audio"]` |
| Output | `clipboard` |
| Hotkey | `Alt+Shift+R` |

### html-to-markdown

**Type:** `tool` (AR plugin)

Converts selected HTML to clean Markdown using the Ancroo Runner
`html-to-markdown` plugin.

| Property | Value |
|---|---|
| Input | `recipe.collect: ["text_selection"]` |
| Output | `clipboard` |
| Tool | `ar_plugin` → `http://ancroo-runner:8000/convert/html-to-markdown` |

### contact-form-capture

**Type:** `tool` (n8n webhook)

Reads contact form fields from the current page and forwards them to an
n8n webhook flow for further processing.

| Property | Value |
|---|---|
| Input | `recipe.collect: ["form_fields", "page_context"]` |
| Output | `notification` |
| Tool | `n8n_webhook` (auto-provisioned) |
| Form fields | `name`, `email`, `subject`, `category`, `message` |

---

## Creating a new workflow

1. **Create a directory** under `workflows/` named after your slug:

   ```
   workflows/my-workflow/
   ```

2. **Write `metadata.json`** — example for each workflow type:

   **LLM workflow (text_transformation):**

   ```json
   {
     "slug": "my-text-workflow",
     "name": "My Text Workflow",
     "description": "Does something useful with selected text",
     "category": "text",
     "workflow_type": "text_transformation",
     "output_action": "replace_selection",
     "recipe": {
       "collect": ["text_selection"]
     },
     "prompt_template": "Do something with this text.\n\nText:\n{{ text }}\n\nResult:",
     "temperature": 0.3
   }
   ```

   **Tool workflow (AR plugin):**

   ```json
   {
     "slug": "my-tool-workflow",
     "name": "My Tool Workflow",
     "description": "Runs a script via Ancroo Runner",
     "category": "text",
     "workflow_type": "tool",
     "output_action": "clipboard",
     "recipe": {
       "collect": ["text_selection"]
     },
     "tool": {
       "name": "My Tool",
       "tool_type": "ar_plugin",
       "endpoint_url": "http://ancroo-runner:8000/my-plugin/run",
       "http_method": "POST",
       "payload_template": "{\"text\": \"{{ text }}\"}",
       "response_mapping": "$.result",
       "timeout": 30
     }
   }
   ```

   **n8n webhook workflow:**

   ```json
   {
     "slug": "my-n8n-workflow",
     "name": "My n8n Workflow",
     "description": "Sends data to n8n for processing",
     "category": "automation",
     "workflow_type": "tool",
     "output_action": "notification",
     "recipe": {
       "collect": ["text_selection", "page_context"]
     },
     "tool": {
       "name": "My Flow → Ancroo",
       "tool_type": "n8n_webhook",
       "n8n_workflow_name": "My Flow → Ancroo"
     }
   }
   ```

3. **Import into the backend** — either upload via the admin GUI
   (**Admin → Import Workflow**) or use `curl`:

   ```bash
   curl -X POST http://localhost:8900/admin/api/import-workflow \
     -H "Content-Type: application/json" \
     -d @workflows/my-workflow/metadata.json
   ```

---

## Environment variables

These variables are used by the backend when importing workflows.  They are
not needed for the JSON files themselves.

| Variable | Default | Description |
|---|---|---|
| `OLLAMA_BASE_URL` | `http://ollama:11434` | Base URL of the Ollama API (for `text_transformation` workflows). |
| `WHISPER_BASE_URL` | `http://speaches:8100` | Base URL of the Whisper-compatible STT server. |
| `WHISPER_MODEL` | `Systran/faster-whisper-large-v3` | Default Whisper model name. |
| `N8N_URL` | `http://n8n:5678` | Base URL of the n8n instance. |
| `N8N_API_KEY` | *(unset)* | n8n API key for auto-provisioning webhook workflows. |
