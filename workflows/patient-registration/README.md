# Patient Registration

**Type:** `tool` (n8n webhook)

Reads patient registration form fields (name, date of birth, insurance, phone, complaints, medical history) from a dental practice demo page and stores them in the `ancroo_demo` PostgreSQL database via n8n.

## Files

| File | Entity type | Purpose |
|------|-------------|---------|
| `workflow.json` | workflow | Workflow definition with form field selectors |
| `category.json` | category | Category "automation" |
| `tool.json` | tool | n8n webhook tool |
| `n8n-workflow.json` | — | n8n flow definition (import into n8n) |
| `demo.html` | — | Interactive demo page |

## Prerequisites

1. The `ancroo_demo` database must exist in PostgreSQL (created by the stack init script)
2. A PostgreSQL credential named "Ancroo Demo DB" must be configured in n8n pointing to the `ancroo_demo` database

## Import

```bash
# 1. Import into Ancroo Backend
curl -X POST http://localhost:8900/admin/api/import -H "Content-Type: application/json" -d @category.json
curl -X POST http://localhost:8900/admin/api/import -H "Content-Type: application/json" -d @tool.json
curl -X POST http://localhost:8900/admin/api/import -H "Content-Type: application/json" -d @workflow.json

# 2. Import n8n-workflow.json into n8n separately (via n8n UI or API)
```

Import order: category → tool → workflow (dependencies first).

## n8n Setup

After importing the n8n workflow:

1. Create a PostgreSQL credential in n8n named "Ancroo Demo DB" with:
   - Host: `postgres`
   - Port: `5432`
   - Database: `ancroo_demo`
   - User/Password: same as main database
2. Assign the credential to both PostgreSQL nodes in the workflow
3. Activate the workflow

The `patients` table is created automatically on first execution.

## Database Schema

```sql
CREATE TABLE patients (
  id SERIAL PRIMARY KEY,
  nachname VARCHAR(255) NOT NULL,
  vorname VARCHAR(255) NOT NULL,
  geburtsdatum DATE,
  versicherung VARCHAR(50),
  telefon VARCHAR(50),
  beschwerden TEXT,
  vorerkrankungen TEXT,
  source_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```
