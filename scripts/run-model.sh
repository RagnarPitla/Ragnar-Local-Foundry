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
Usage: run-model.sh [alias] [-h|--help]

Start an interactive Foundry Local REPL with foundry model run.
If alias is omitted, default_model from config/models.json is used.
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

ensure_service() {
  info "Checking Foundry Local service."
  if ! foundry service status >/dev/null 2>&1; then
    warn "Service status check failed. Starting service."
    foundry service start >/dev/null
  fi
  foundry service status >/dev/null
}

MODEL=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      die "Unknown option: $1"
      ;;
    *)
      if [ -n "$MODEL" ]; then
        die "Only one model alias may be provided."
      fi
      MODEL="$1"
      ;;
  esac
  shift
done

[ -f "$CATALOG" ] || die "Model catalog not found at $CATALOG"
need_foundry
if [ -z "$MODEL" ]; then
  MODEL="$(default_model)"
fi
ensure_service
success "Starting interactive REPL for $MODEL."
foundry model run "$MODEL"
