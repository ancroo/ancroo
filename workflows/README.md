# Ancroo Workflows

This directory contains workflow definition files (`metadata.json`) that can be
imported into the Ancroo backend.  Each workflow lives in its own subdirectory.

---

## Table of Contents

- [How it works](#how-it-works)
- [Directory structure](#directory-structure)
- [metadata.json reference](#metadatajson-reference)
  - [Top-level fields](#top-level-fields)
  - [workflow\_type values](#workflow_type-values)
  - [input\_sources values](#input_sources-values)
  - [output\_action values](#output_action-values)
  - [requires values](#requires-values)
  - [LLM-specific fields](#llm-specific-fields)
  - [Audio-specific fields](#audio-specific-fields)
  - [n8n-specific fields](#n8n-specific-fields)
  - [Form fields](#form-fields)
- [Example workflows](#example-workflows)
  - [grammar-fix](#grammar-fix)
  - [speech-to-text](#speech-to-text)
  - [contact-form-capture](#contact-form-capture)
  - [name-formatter](#name-formatter)
  - [n8n-echo](#n8n-echo)
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
2. If the workflow `requires: ["llm"]`, a default Ollama LLM provider is
   created automatically if none exists.
3. If the workflow `requires: ["whisper"]`, a Whisper STT provider is created.
4. If the workflow `requires: ["n8n"]` **and** the n8n API key is configured,
   an n8n webhook flow is created and activated automatically.  The webhook
   URL is stored in `target_config`.

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
├── llm-cpu/
│   └── metadata.json
├── llm-cuda/
│   └── metadata.json
├── llm-rocm/
│   └── metadata.json
├── speech-to-text/
│   ├── metadata.json
│   └── demo.html
├── stt-cuda/
│   └── metadata.json
├── stt-rocm/
│   └── metadata.json
├── freight-calculator/
│   ├── metadata.json
│   ├── demo.html
│   └── n8n-workflow.json
├── contact-form-capture/
│   ├── metadata.json
│   └── demo.html
├── name-formatter/
│   ├── metadata.json
│   └── demo.html
├── html-to-markdown/
│   ├── metadata.json
│   └── demo.html
└── n8n-echo/
    ├── metadata.json
    └── demo.html
```

Each subdirectory contains a `metadata.json` with a unique `slug` field and
optionally a `demo.html` page for testing the workflow via the browser extension.
Import workflows via the Admin GUI (Import page) — drop the folder or select
both files. The `demo.html` is stored in the database and served at
`/admin/workflows/{slug}/demo`.

---

## metadata.json reference

### Top-level fields

| Field | Type | Required | Description |
|---|---|---|---|
| `slug` | string | **yes** | URL-safe identifier, unique across all workflows. Used as the primary key in the admin GUI and API (`/api/v1/workflows/{slug}`). |
| `name` | string | **yes** | Human-readable display name shown in the extension and admin GUI. |
| `description` | string | no | Short description shown in the admin GUI and extension tooltip. |
| `category` | string | no | Groups workflows in the admin GUI. Common values: `text`, `voice`, `automation`. Free-form. |
| `workflow_type` | string | no | Controls which admin GUI form is used for editing and which executor runs the workflow. See [workflow\_type values](#workflow_type-values). |
| `execution_type` | string | no | Defaults to `"tool"`. Other value: `"pipeline"`. |
| `input_type` | string | no | Hint for the extension UI. Common values: `text`, `audio`, `form`. |
| `output_type` | string | no | Hint for the extension UI. Common values: `text`, `notification`. |
| `output_action` | string | no | What the extension does with the result. See [output\_action values](#output_action-values). |
| `default_hotkey` | string | no | Pre-configured keyboard shortcut, e.g. `"Ctrl+Shift+G"`. Users can override per-device. |
| `input_sources` | array | no | What the extension collects before executing. Defaults to `["text_selection"]`. See [input\_sources values](#input_sources-values). |
| `requires` | array | no | External services needed. See [requires values](#requires-values). |

### workflow\_type values

| Value | Description |
|---|---|
| `text_transformation` | LLM-powered text editing. The extension sends selected text and replaces it with the LLM response. Executor: LLM provider pipeline. |
| `workflow_trigger` | Sends collected data to an external webhook (n8n). Good for automation flows that don't return text. |
| `speech_to_text` | Audio transcription via a Whisper-compatible STT server. The extension records audio and the backend returns the transcript. |
| `custom` | Anything that doesn't fit the above categories. |
| *(omitted)* | Legacy pipeline mode. The admin GUI falls back to the old form. |

### input\_sources values

The extension collects these inputs before calling the backend:

| Value | What is collected |
|---|---|
| `text_selection` | Currently selected text in the browser. |
| `clipboard` | Current clipboard content. |
| `page_context` | Current page URL and title. |
| `form_fields` | DOM values from CSS selectors defined in `form_fields`. |
| `audio` | Audio recording from the device microphone (file upload). |

Multiple sources can be combined in the array.

### output\_action values

| Value | What the extension does with the result |
|---|---|
| `replace_selection` | Replaces the selected text with the workflow output. |
| `copy_to_clipboard` | Copies the result to the clipboard. |
| `clipboard` | Alias for `copy_to_clipboard`. |
| `notification` | Shows a brief notification popup (result text or confirmation). |
| `fill_fields` | Writes result values back into form fields using `output_fields` selectors. |
| `download_file` | Decodes base64 result and triggers a browser file download. Requires `filename` and `mime_type` in the upstream response. |
| `none` | No client-side action; result is discarded (useful for fire-and-forget triggers). |

### requires values

| Value | What it triggers during import |
|---|---|
| `llm` | Creates a default Ollama LLM provider if none exists. Requires `llm_prompt` to be set. |
| `whisper` | Creates a Whisper STT provider pointing at `$WHISPER_BASE_URL`. |
| `n8n` | Creates and activates an n8n webhook flow automatically if `N8N_API_KEY` is configured. |

### LLM-specific fields

Used when `requires` contains `"llm"`:

| Field | Type | Default | Description |
|---|---|---|---|
| `llm_prompt` | string | — | **Required.** Jinja2 prompt template. Available variables: `{{ text }}` (selected text), `{{ url }}` (page URL), `{{ title }}` (page title). Return ONLY the output text — no explanations. |
| `llm_model` | string | provider default | Override the LLM model, e.g. `"mistral:7b"`. Falls back to the assigned provider's `default_model`. |
| `llm_temperature` | float | `0.3` | Sampling temperature `0.0–1.0`. Lower = more deterministic. |

**Example prompt template:**

```
Fix grammar and spelling in the following text.
Preserve the original meaning and language.
Return ONLY the corrected text.

Text:
{{ text }}

Corrected text:
```

### Audio-specific fields

Used when `input_sources` contains `"audio"`:

| Field | Type | Default | Description |
|---|---|---|---|
| `audio_accept` | string | `"audio/*"` | MIME type filter for the file picker, e.g. `"audio/webm,audio/ogg"`. |
| `audio_max_size_mb` | int | `50` | Maximum file size in MB. |
| `audio_label` | string | `"Audio recording"` | Label shown in the extension file picker. |

### n8n-specific fields

Used when `requires` contains `"n8n"`:

| Field | Type | Default | Description |
|---|---|---|---|
| `n8n_workflow_name` | string | workflow name | Display name for the auto-created n8n workflow. |
| `form_fields` | array | `[]` | See [Form fields](#form-fields) below. |
| `output_fields` | array | `[]` | See [Output fields](#output-fields) below. Used with `output_action: "fill_fields"`. |

### Form fields

Used when `input_sources` contains `"form_fields"`.  Each entry tells the
extension which DOM element to read:

```json
"form_fields": [
  { "name": "email",   "selector": "#field-email, input[type='email']" },
  { "name": "message", "selector": "#field-message, textarea[name='message']" }
]
```

| Key | Description |
|---|---|
| `name` | Key used in the payload sent to the backend / webhook. |
| `selector` | CSS selector (comma-separated fallback list). The extension tries each selector in order and uses the first match. |

### Output fields

Used when `output_action` is `"fill_fields"`.  Each entry tells the extension
which DOM element to write the result into:

```json
"output_fields": [
  { "name": "freight_cost", "selector": "#field-result, input[name='result']" }
]
```

| Key | Description |
|---|---|
| `name` | Key in the backend response to extract the value from. |
| `selector` | CSS selector for the target element. The extension sets its `value` (inputs) or `textContent`. |

### Demo page (demo.html)

Each workflow can include a `demo.html` file alongside `metadata.json`. This
is a standalone HTML page with form fields matching the workflow's CSS selectors.
It is imported into the database and served at `/admin/workflows/{slug}/demo`.

The demo page allows testing the workflow end-to-end: open the page, activate
the Ancroo extension, select the workflow, and click Execute.

---

## Example workflows

### grammar-fix

**File:** `grammar-fix/metadata.json`

Corrects grammar and spelling in selected text using an LLM.  The corrected
text directly replaces the selection in the browser.

| Property | Value |
|---|---|
| Requires | Ollama LLM (uses provider default model) |
| Input | Selected text |
| Output | Corrected text replaces selection |
| Hotkey | `Alt+Shift+G` |

**How it works:**
1. User selects text in the browser and presses the hotkey (or uses the
   extension popup).
2. The extension sends the selection to `/api/v1/workflows/grammar-fix/execute`.
3. The backend renders the LLM prompt with the selected text and calls the
   configured Ollama provider.
4. The response is returned and the extension replaces the selection.

**Environment variables needed:** `OLLAMA_BASE_URL` (default:
`http://ollama:11434`).  An Ollama instance with `mistral:7b` pulled must be
reachable.

---

### speech-to-text

**File:** `speech-to-text/metadata.json`

Records audio via the browser and transcribes it to text using a Whisper-
compatible server.  The transcript is copied to the clipboard.

| Property | Value |
|---|---|
| Requires | Whisper STT server |
| Input | Audio recording (file upload, max 50 MB) |
| Output | Transcript copied to clipboard |
| Hotkey | `Alt+Shift+R` |

**How it works:**
1. User triggers the workflow — the extension shows a microphone recording UI.
2. The recorded audio is uploaded as a multipart form to
   `/api/v1/workflows/speech-to-text/execute`.
3. The backend forwards the file to the Whisper server's
   `/v1/audio/transcriptions` endpoint.
4. The transcript is returned and copied to the clipboard.

**Environment variables needed:** `WHISPER_BASE_URL` (default:
`http://speaches:8100`) pointing at a Speaches or Whisper-ROCm
instance.  `WHISPER_MODEL` sets the model (default:
`Systran/faster-whisper-large-v3`).

---

### contact-form-capture

**File:** `contact-form-capture/metadata.json`

Reads contact form fields from the current page and forwards them to an
n8n webhook flow for further processing (e.g. sending an email,
writing to a spreadsheet, creating a CRM entry).

| Property | Value |
|---|---|
| Requires | n8n |
| Input | Form fields + page context |
| Output | Notification (confirmation) |
| Form fields | `name`, `email`, `subject`, `category`, `message` |

**How it works:**
1. User navigates to a page with a contact form.
2. The user opens the Ancroo extension and executes *Contact Form Capture*.
3. The extension reads the form field values using the configured CSS selectors.
4. The backend POSTs the collected data as JSON to the n8n webhook URL.
5. n8n processes the data (the workflow can be extended with any n8n
   nodes — email, sheets, CRM, etc.).
6. A notification confirms the submission.

**CSS selectors used:**

| Field | Selector |
|---|---|
| `name` | `#field-name, input[name='name'], input[name='fullname']` |
| `email` | `#field-email, input[name='email'], input[type='email']` |
| `subject` | `#field-subject, input[name='subject']` |
| `category` | `#field-category, select[name='category']` |
| `message` | `#field-message, textarea[name='message'], textarea[name='body']` |

Selectors are tried left-to-right; the first matching element wins.  You can
adapt these to match your own form by editing the workflow in the admin GUI
(**Admin → Workflows → Contact Form Capture → Edit Workflow**).

**Auto-provisioning:** During import, if `N8N_API_KEY` is configured, the
backend automatically creates an n8n workflow named *Contact Form → Ancroo*
with a Webhook trigger, activates it, and stores the webhook URL in
`target_config`.

---

### name-formatter

**File:** `name-formatter/metadata.json`

Reads name and email fields from a form, sends them to an n8n webhook
flow for formatting, and returns a greeting notification.

| Property | Value |
|---|---|
| Requires | n8n |
| Input | Form fields + page context |
| Output | Notification (greeting confirmation) |
| Form fields | `first_name`, `last_name`, `email` |

**How it works:**
1. User navigates to a page with a registration or name/email form.
2. The user opens the Ancroo extension and executes *Name Formatter*.
3. The extension reads the form field values using the configured CSS selectors.
4. The backend POSTs the collected data as JSON to the n8n webhook URL.
5. n8n processes the data (the workflow can be extended to send a welcome
   email, create a contact record, etc.).
6. A notification confirms the submission.

**CSS selectors used:**

| Field | Selector |
|---|---|
| `first_name` | `#field-first-name, input[name='first_name'], input[name='firstname']` |
| `last_name` | `#field-last-name, input[name='last_name'], input[name='lastname']` |
| `email` | `#field-email, input[name='email'], input[type='email']` |

Selectors are tried left-to-right; the first matching element wins.  You can
adapt these to match your own form by editing the workflow in the admin GUI
(**Admin → Workflows → Name Formatter → Edit Workflow**).

**Auto-provisioning:** During import, if `N8N_API_KEY` is configured, the
backend automatically creates an n8n workflow named *Name Formatter → Ancroo*
with a Webhook trigger, activates it, and stores the webhook URL in
`target_config`.

---

### n8n-echo

**File:** `n8n-echo/metadata.json`

Sends selected text to an n8n webhook and echoes it back.  A basic test to
verify the n8n integration is working end-to-end.

| Property | Value |
|---|---|
| Requires | n8n |
| Input | Selected text + page context |
| Output | Notification (echoed text) |

**How it works:**
1. User selects text in the browser and executes *n8n Echo*.
2. The extension sends the selection and page context to the backend.
3. The backend POSTs the data to the n8n webhook URL.
4. n8n echoes the payload back and a notification confirms the result.

**Auto-provisioning:** During import, if `N8N_API_KEY` is configured, the
backend automatically creates an n8n workflow named *Echo → Ancroo*
with a Webhook trigger, activates it, and stores the webhook URL in
`target_config`.

---

## Creating a new workflow

1. **Create a directory** under `workflows/` named after your slug:

   ```
   workflows/my-workflow/
   ```

2. **Write `metadata.json`** — minimal example for an LLM workflow:

   ```json
   {
     "slug": "my-workflow",
     "name": "My Workflow",
     "description": "Does something useful with selected text",
     "category": "text",

     "workflow_type": "text_transformation",
     "execution_type": "tool",
     "input_type": "text",
     "output_type": "text",
     "output_action": "replace_selection",
     "input_sources": ["text_selection"],

     "requires": ["llm"],
     "llm_model": "mistral:7b",
     "llm_temperature": 0.3,
     "llm_prompt": "Do something with the following text and return ONLY the result.\n\nText:\n{{ text }}\n\nResult:"
   }
   ```

3. **For a webhook workflow** (n8n), use `workflow_type:
   "workflow_trigger"` and `requires: ["n8n"]` or configure the
   webhook URL manually via the admin GUI.

4. **Import into the backend** — either upload via the admin GUI
   (**Admin → Import Workflow**) or use `curl`:

   ```bash
   curl -X POST http://localhost:8900/admin/api/import-workflow \
     -H "Content-Type: application/json" \
     -d @workflows/my-workflow/metadata.json
   ```

   You can also create workflows directly via the admin GUI at
   `/admin/workflows/new`.

---

## Environment variables

These variables are used by the backend when importing workflows that declare
`requires` dependencies.  They are not needed for the JSON files themselves.

| Variable | Default | Description |
|---|---|---|
| `OLLAMA_BASE_URL` | `http://ollama:11434` | Base URL of the Ollama API (for `requires: ["llm"]` workflows). |
| `WHISPER_BASE_URL` | `http://speaches:8100` | Base URL of the Whisper-compatible transcription server. |
| `WHISPER_MODEL` | `Systran/faster-whisper-large-v3` | Default Whisper model name. |
| `N8N_URL` | `http://n8n:5678` | Base URL of the n8n instance. |
| `N8N_API_KEY` | *(unset)* | n8n API key for auto-provisioning webhook workflows. |
