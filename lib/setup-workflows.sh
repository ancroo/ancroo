#!/bin/bash
# setup-workflows.sh — Import example workflows via the admin API
#
# Called from install.sh after the stack is fully up, or standalone:
#   bash lib/setup-workflows.sh [HOST_IP]
#
# Imports all workflows/*/metadata.json files via the
# POST /admin/api/import-workflow endpoint. Retries n8n workflows
# after a delay if n8n is not ready yet.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Allow overrides from caller (install.sh sets these)
HOST_IP="${1:-${HOST_IP:-localhost}}"
BACKEND_PORT="${BACKEND_PORT:-8900}"
BASE_URL="http://${HOST_IP}:${BACKEND_PORT}"

WORKFLOWS_DIR="$SCRIPT_DIR/../workflows"

if [[ ! -d "$WORKFLOWS_DIR" ]]; then
    print_warning "Workflows directory not found: $WORKFLOWS_DIR"
    exit 0
fi

# --- Wait for backend health ---
print_step "Waiting for backend..."
_attempts=0
_max_attempts=30
while ! curl -sf "${BASE_URL}/health" > /dev/null 2>&1; do
    _attempts=$((_attempts + 1))
    if [[ $_attempts -ge $_max_attempts ]]; then
        print_error "Backend not reachable after ${_max_attempts} attempts"
        exit 1
    fi
    sleep 2
done
print_success "Backend is healthy"

# --- Import all workflow files ---
print_step "Importing example workflows..."

_imported=0
_skipped=0
_inactive=0
_failed=0
_inactive_files=()

for meta_file in "$WORKFLOWS_DIR"/*/metadata.json; do
    [[ -f "$meta_file" ]] || continue
    slug=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('slug',''))" "$meta_file" 2>/dev/null || true)
    [[ -z "$slug" ]] && continue

    # Merge n8n-workflow.json into metadata if present
    wf_dir="$(dirname "$meta_file")"
    n8n_wf_file="$wf_dir/n8n-workflow.json"
    if [[ -f "$n8n_wf_file" ]]; then
        payload=$(python3 -c "
import json, sys
meta = json.load(open(sys.argv[1]))
n8n_wf = json.load(open(sys.argv[2]))
meta['n8n_workflow_json'] = n8n_wf
json.dump(meta, sys.stdout)
" "$meta_file" "$n8n_wf_file" 2>/dev/null)
    else
        payload=$(cat "$meta_file")
    fi

    response=$(echo "$payload" | curl -sf --max-time 60 \
        -X POST "${BASE_URL}/admin/api/import-workflow" \
        -H "Content-Type: application/json" \
        -d @- 2>/dev/null || echo '{"status":"error","message":"request failed"}')

    status=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','error'))" 2>/dev/null || echo "error")

    case "$status" in
        created)
            print_success "$slug"
            _imported=$((_imported + 1))
            ;;
        already_exists)
            _skipped=$((_skipped + 1))
            ;;
        created_inactive)
            print_info "$slug (n8n not ready — will retry)"
            _inactive=$((_inactive + 1))
            _inactive_files+=("$meta_file")
            ;;
        reprovisioned)
            print_success "$slug (reprovisioned)"
            _imported=$((_imported + 1))
            ;;
        *)
            msg=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('message','unknown'))" 2>/dev/null || echo "unknown")
            print_warning "$slug: $msg"
            _failed=$((_failed + 1))
            ;;
    esac
done

# --- Retry inactive n8n workflows after delay ---
if [[ ${#_inactive_files[@]} -gt 0 ]]; then
    _max_retries=6
    _retry_wait=15
    _retry=0

    while [[ ${#_inactive_files[@]} -gt 0 && $_retry -lt $_max_retries ]]; do
        _retry=$((_retry + 1))
        print_step "Waiting for n8n (attempt ${_retry}/${_max_retries}, ${_retry_wait}s)..."
        sleep "$_retry_wait"

        print_step "Retrying n8n workflows..."
        _still_inactive=()
        for meta_file in "${_inactive_files[@]}"; do
            slug=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('slug',''))" "$meta_file" 2>/dev/null || true)

            # Merge n8n-workflow.json into metadata if present
            wf_dir="$(dirname "$meta_file")"
            n8n_wf_file="$wf_dir/n8n-workflow.json"
            if [[ -f "$n8n_wf_file" ]]; then
                payload=$(python3 -c "
import json, sys
meta = json.load(open(sys.argv[1]))
n8n_wf = json.load(open(sys.argv[2]))
meta['n8n_workflow_json'] = n8n_wf
json.dump(meta, sys.stdout)
" "$meta_file" "$n8n_wf_file" 2>/dev/null)
            else
                payload=$(cat "$meta_file")
            fi

            response=$(echo "$payload" | curl -sf --max-time 120 \
                -X POST "${BASE_URL}/admin/api/import-workflow" \
                -H "Content-Type: application/json" \
                -d @- 2>/dev/null || echo '{"status":"error"}')

            status=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','error'))" 2>/dev/null || echo "error")

            if [[ "$status" == "reprovisioned" || "$status" == "created" ]]; then
                print_success "$slug (provisioned)"
                _imported=$((_imported + 1))
                _inactive=$((_inactive - 1))
            else
                _still_inactive+=("$meta_file")
            fi
        done
        _inactive_files=("${_still_inactive[@]+"${_still_inactive[@]}"}")
    done

    # Report any remaining failures
    for meta_file in "${_inactive_files[@]+"${_inactive_files[@]}"}"; do
        [[ -z "$meta_file" ]] && continue
        slug=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('slug',''))" "$meta_file" 2>/dev/null || true)
        print_warning "$slug: n8n provisioning still pending after ${_max_retries} retries"
    done
fi

# --- Summary ---
echo ""
_total=$((_imported + _skipped + _inactive + _failed))
print_info "Workflows: ${_imported} imported, ${_skipped} skipped, ${_inactive} pending, ${_failed} failed (${_total} total)"
