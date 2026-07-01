#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CATALOG="$REPO_ROOT/config/models.json"

if [ -t 1 ]; then
  RED="$(printf '\033[31m')"
  GREEN="$(printf '\033[32m')"
  YELLOW="$(printf '\033[33m')"
  BLUE="$(printf '\033[34m')"
  RESET="$(printf '\033[0m')"
else
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  RESET=""
fi

info() { printf '%s[INFO]%s %s\n' "$BLUE" "$RESET" "$*"; }
warn() { printf '%s[WARN]%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
error() { printf '%s[ERROR]%s %s\n' "$RED" "$RESET" "$*" >&2; }
success() { printf '%s[PASS]%s %s\n' "$GREEN" "$RESET" "$*"; }
fail() { printf '%s[FAIL]%s %s\n' "$RED" "$RESET" "$*" >&2; }
die() { error "$*"; exit 1; }

usage() {
  cat <<'USAGE'
Usage: health-check.sh [-h|--help]

Run local acceptance checks for Azure AI Foundry Local:
  1. foundry is installed and reports a version.
  2. service status is available.
  3. the dynamic endpoint can be extracted.
  4. GET /v1/models responds when curl is available.
  5. POST /v1/chat/completions responds when curl and a model are available.
USAGE
}

need_python() {
  command -v python3 >/dev/null 2>&1 || die "python3 is required to read $CATALOG."
}

need_foundry() {
  if ! command -v foundry >/dev/null 2>&1; then
    die "foundry is not installed. Run: bash \"$REPO_ROOT/scripts/install-mac.sh\""
  fi
}

default_model() {
  need_python
  python3 - "$CATALOG" <<'PY'
import json
import sys

try:
    with open(sys.argv[1], "r", encoding="utf-8") as handle:
        data = json.load(handle)
except Exception as exc:
    raise SystemExit(f"Failed to read catalog: {exc}")
model = data.get("default_model", "")
if not model:
    raise SystemExit("default_model is missing from catalog")
print(model)
PY
}

extract_endpoint() {
  printf '%s\n' "$1" | grep -Eo 'https?://[^[:space:])",;]+' | head -n 1 || true
}

record_pass() {
  PASSES=$((PASSES + 1))
  success "$1"
}

record_fail() {
  FAILURES=$((FAILURES + 1))
  fail "$1"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[ -f "$CATALOG" ] || die "Model catalog not found at $CATALOG"
need_foundry

PASSES=0
FAILURES=0
ENDPOINT=""

info "Checking foundry version."
if VERSION_OUTPUT="$(foundry --version 2>&1)"; then
  printf '%s\n' "$VERSION_OUTPUT"
  record_pass "foundry --version"
else
  printf '%s\n' "$VERSION_OUTPUT" >&2
  record_fail "foundry --version"
fi

info "Checking Foundry Local service status."
if STATUS_OUTPUT="$(foundry service status 2>&1)"; then
  printf '%s\n' "$STATUS_OUTPUT"
  record_pass "foundry service status"
  ENDPOINT="$(extract_endpoint "$STATUS_OUTPUT")"
  if [ -n "$ENDPOINT" ]; then
    record_pass "endpoint discovered: $ENDPOINT"
  else
    record_fail "endpoint discovery"
  fi
else
  printf '%s\n' "$STATUS_OUTPUT" >&2
  record_fail "foundry service status"
fi

if ! command -v curl >/dev/null 2>&1; then
  warn "curl is not available. Skipping REST smoke tests."
elif [ -z "$ENDPOINT" ]; then
  warn "Endpoint is unavailable. Skipping REST smoke tests."
else
  info "Checking GET /v1/models."
  if curl -fsS "$ENDPOINT/v1/models" >/dev/null; then
    record_pass "GET /v1/models"
  else
    record_fail "GET /v1/models"
  fi

  MODEL="$(default_model)"
  info "Checking POST /v1/chat/completions with model $MODEL."
  if curl -fsS "$ENDPOINT/v1/chat/completions" \
    -H "Authorization: Bearer local-placeholder-key" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with ok.\"}],\"max_tokens\":8}" >/dev/null; then
    record_pass "POST /v1/chat/completions"
  else
    record_fail "POST /v1/chat/completions"
  fi
fi

printf '\nHealth summary: %s passed, %s failed.\n' "$PASSES" "$FAILURES"
if [ "$FAILURES" -gt 0 ]; then
  exit 1
fi
success "Foundry Local health check passed."
