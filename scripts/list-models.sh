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
Usage: list-models.sh [--catalog] [--profile NAME] [--filter key=value] [-h|--help]

List Azure AI Foundry Local models.

Modes:
  default            Run foundry model list.
  --catalog          Print the curated catalog from config/models.json.
  --profile NAME     Print only models in a curated profile: starter, balanced, power.

Foundry filters:
  --filter key=value Pass one filter to foundry model list.
                     Supported keys include device, provider, task, and alias.
                     Examples: --filter task=chat-completion, --filter alias=qwen*

Alias vs model ID:
  The curated catalog uses aliases, such as qwen2.5-0.5b. Foundry may show
  hardware-specific model IDs in model list output. Use aliases when this repo
  asks for a model name unless Foundry tells you a specific ID is required.
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

print_catalog() {
  need_python
  [ -f "$CATALOG" ] || die "Model catalog not found at $CATALOG"
  python3 - "$CATALOG" "${1:-}" <<'PY'
import json
import sys

catalog_path = sys.argv[1]
profile = sys.argv[2] if len(sys.argv) > 2 else ""
try:
    with open(catalog_path, "r", encoding="utf-8") as handle:
        data = json.load(handle)
except Exception as exc:
    raise SystemExit(f"Failed to read catalog: {exc}")

models = data.get("models", [])
if profile:
    profiles = data.get("profiles", {})
    if profile not in profiles:
        raise SystemExit(f"Unknown profile: {profile}")
    wanted = set(profiles[profile].get("models", []))
    models = [model for model in models if model.get("alias") in wanted]
    print(f"Profile: {profile}")
    print(f"Description: {profiles[profile].get('description', '')}")
    print()

headers = ["alias", "family", "params", "size", "min RAM", "task", "use case"]
rows = []
for model in models:
    rows.append([
        str(model.get("alias", "")),
        str(model.get("family", "")),
        str(model.get("params", "")),
        f"{model.get('approx_size_gb', '')} GB",
        f"{model.get('min_ram_gb', '')} GB",
        str(model.get("task", "")),
        str(model.get("use_case", "")),
    ])

widths = [len(header) for header in headers]
for row in rows:
    for index, value in enumerate(row):
        widths[index] = max(widths[index], len(value))

def print_row(values):
    print("  ".join(value.ljust(widths[index]) for index, value in enumerate(values)))

print_row(headers)
print_row(["-" * width for width in widths])
for row in rows:
    print_row(row)
PY
}

MODE="foundry"
PROFILE=""
FOUNDRY_ARGS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --catalog)
      MODE="catalog"
      ;;
    --profile)
      [ "$#" -ge 2 ] || die "--profile requires a name."
      PROFILE="$2"
      MODE="catalog"
      shift
      ;;
    --filter)
      [ "$#" -ge 2 ] || die "--filter requires key=value."
      FOUNDRY_ARGS+=("--filter" "$2")
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

if [ "$MODE" = "catalog" ]; then
  print_catalog "$PROFILE"
else
  need_foundry
  info "Running foundry model list."
  foundry model list "${FOUNDRY_ARGS[@]}"
  success "Model list complete."
fi
