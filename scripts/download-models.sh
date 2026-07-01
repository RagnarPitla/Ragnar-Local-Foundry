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
Usage: download-models.sh [--profile starter|balanced|power] [--yes] [alias ...] [-h|--help]

Download models by curated profile or explicit aliases.

Examples:
  download-models.sh
  download-models.sh --profile balanced
  download-models.sh --yes qwen2.5-0.5b phi-4-mini-instruct

If no profile or aliases are provided, the starter profile is used.
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

catalog_aliases_for_profile() {
  need_python
  python3 - "$CATALOG" "$1" <<'PY'
import json
import sys

catalog_path = sys.argv[1]
profile = sys.argv[2]
try:
    with open(catalog_path, "r", encoding="utf-8") as handle:
        data = json.load(handle)
except Exception as exc:
    raise SystemExit(f"Failed to read catalog: {exc}")

profiles = data.get("profiles", {})
if profile not in profiles:
    raise SystemExit(f"Unknown profile: {profile}")
for alias in profiles[profile].get("models", []):
    print(alias)
PY
}

catalog_size_for_aliases() {
  need_python
  python3 - "$CATALOG" "$@" <<'PY'
import json
import sys

catalog_path = sys.argv[1]
aliases = sys.argv[2:]
try:
    with open(catalog_path, "r", encoding="utf-8") as handle:
        data = json.load(handle)
except Exception as exc:
    raise SystemExit(f"Failed to read catalog: {exc}")

sizes = {model.get("alias"): float(model.get("approx_size_gb", 0)) for model in data.get("models", [])}
missing = [alias for alias in aliases if alias not in sizes]
total = sum(sizes.get(alias, 0.0) for alias in aliases)
print(f"{total:.2f}")
if missing:
    print("Unknown catalog aliases, size not counted: " + ", ".join(missing), file=sys.stderr)
PY
}

PROFILE=""
YES=0
ALIASES=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile)
      [ "$#" -ge 2 ] || die "--profile requires a name."
      PROFILE="$2"
      shift
      ;;
    --yes|-y)
      YES=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        ALIASES+=("$1")
        shift
      done
      break
      ;;
    -*)
      die "Unknown option: $1"
      ;;
    *)
      ALIASES+=("$1")
      ;;
  esac
  shift
done

[ -f "$CATALOG" ] || die "Model catalog not found at $CATALOG"
need_foundry

if [ "${#ALIASES[@]}" -eq 0 ]; then
  if [ -z "$PROFILE" ]; then
    PROFILE="starter"
  fi
  while IFS= read -r alias; do
    [ -n "$alias" ] && ALIASES+=("$alias")
  done <<EOF_ALIASES
$(catalog_aliases_for_profile "$PROFILE")
EOF_ALIASES
fi

[ "${#ALIASES[@]}" -gt 0 ] || die "No models selected."

TOTAL_SIZE="$(catalog_size_for_aliases "${ALIASES[@]}")"

info "Selected models:"
for alias in "${ALIASES[@]}"; do
  printf '  %s\n' "$alias"
done
info "Approximate total download size: ${TOTAL_SIZE} GB"

if [ "$YES" -ne 1 ]; then
  printf 'Continue with download? [y/N] '
  read -r answer
  case "$answer" in
    y|Y|yes|YES)
      ;;
    *)
      die "Download cancelled."
      ;;
  esac
fi

SUCCEEDED=()
FAILED=()
COUNT="${#ALIASES[@]}"
INDEX=1
for alias in "${ALIASES[@]}"; do
  info "Downloading $alias ($INDEX of $COUNT)."
  if foundry model download "$alias"; then
    success "Downloaded $alias."
    SUCCEEDED+=("$alias")
  else
    warn "Failed to download $alias. Continuing."
    FAILED+=("$alias")
  fi
  INDEX=$((INDEX + 1))
done

printf '\nDownload summary:\n'
printf '  Succeeded: %s\n' "${#SUCCEEDED[@]}"
for alias in "${SUCCEEDED[@]}"; do
  printf '    %s\n' "$alias"
done
printf '  Failed: %s\n' "${#FAILED[@]}"
for alias in "${FAILED[@]}"; do
  printf '    %s\n' "$alias"
done

if [ "${#FAILED[@]}" -gt 0 ]; then
  exit 1
fi
success "All downloads completed."
