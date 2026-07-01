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
success() { printf '%s[OK]%s %s\n' "$GREEN" "$RESET" "$*"; }
die() { error "$*"; exit 1; }

usage() {
  cat <<'USAGE'
Usage: serve.sh [--model alias] [-h|--help]

Start the Foundry Local service, optionally load a model, then print the
dynamic local endpoint and an OpenAI-compatible curl example.

Options:
  --model alias  Load a model before printing the endpoint.
  -h, --help     Show this help text.
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

MODEL=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --model)
      [ "$#" -ge 2 ] || die "--model requires an alias."
      MODEL="$2"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
  shift
done

[ -f "$CATALOG" ] || die "Model catalog not found at $CATALOG"
need_foundry

info "Starting Foundry Local service."
foundry service start

if [ -n "$MODEL" ]; then
  info "Loading model $MODEL."
  foundry model load "$MODEL"
else
  MODEL="$(default_model)"
  warn "No model was loaded by this script. Curl example uses default catalog alias: $MODEL"
fi

STATUS_OUTPUT="$(foundry service status 2>&1 || true)"
printf '%s\n' "$STATUS_OUTPUT"
ENDPOINT="$(extract_endpoint "$STATUS_OUTPUT")"

if [ -z "$ENDPOINT" ]; then
  die "Could not find an http endpoint in foundry service status output. The local port is dynamic, inspect the status above."
fi

success "Foundry Local endpoint: $ENDPOINT"
cat <<EOF_CURL

The Foundry Local port is dynamic. Use the endpoint printed by service status.

Ready-to-copy chat completion request:
curl -sS "$ENDPOINT/v1/chat/completions" \\
  -H "Authorization: Bearer local-placeholder-key" \\
  -H "Content-Type: application/json" \\
  -d '{
    "model": "$MODEL",
    "messages": [
      { "role": "user", "content": "Say hello from Foundry Local." }
    ],
    "max_tokens": 64
  }'
EOF_CURL
