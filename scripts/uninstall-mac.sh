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
Usage: uninstall-mac.sh [--purge-cache] [-h|--help]

Uninstall Azure AI Foundry Local from macOS using Homebrew.

Options:
  --purge-cache  After uninstall, ask for confirmation and remove cached models.
  -h, --help     Show this help text.

Cache cleanup is conservative. Nothing is deleted unless --purge-cache is
provided and you confirm the prompt.
USAGE
}

PURGE_CACHE=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --purge-cache)
      PURGE_CACHE=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
  shift
done

[ -f "$CATALOG" ] || warn "Model catalog not found at $CATALOG. Continuing uninstall."

CACHE_LOCATION=""
if command -v foundry >/dev/null 2>&1; then
  info "Reading Foundry Local cache location."
  CACHE_LOCATION="$(foundry cache location 2>/dev/null || true)"
  if [ -n "$CACHE_LOCATION" ]; then
    printf 'Foundry cache location:\n%s\n' "$CACHE_LOCATION"
  else
    warn "Could not read cache location."
  fi

  info "Stopping Foundry Local service."
  foundry service stop || warn "Service stop failed or service was not running."
else
  warn "foundry is not installed or not on PATH. To install later, run: bash \"$REPO_ROOT/scripts/install-mac.sh\""
fi

if ! command -v brew >/dev/null 2>&1; then
  die "Homebrew is missing, cannot uninstall foundrylocal with brew."
fi

info "Uninstalling foundrylocal."
brew uninstall foundrylocal || warn "brew uninstall foundrylocal failed or package was not installed."

info "Untapping microsoft/foundrylocal if present."
brew untap microsoft/foundrylocal || warn "brew untap microsoft/foundrylocal failed or tap was not present."

if [ "$PURGE_CACHE" -eq 1 ]; then
  if [ -z "$CACHE_LOCATION" ]; then
    warn "No cache location was discovered. Skipping cache purge."
  else
    printf '\nCache purge requested.\n'
    printf 'This will remove the Foundry Local cache shown above if it is a local path.\n'
    printf 'Type PURGE to confirm cache deletion: '
    read -r answer
    if [ "$answer" = "PURGE" ]; then
      while IFS= read -r cache_path; do
        [ -n "$cache_path" ] || continue
        case "$cache_path" in
          /*)
            if [ -e "$cache_path" ]; then
              info "Removing cache path: $cache_path"
              rm -rf -- "$cache_path"
            else
              warn "Cache path does not exist: $cache_path"
            fi
            ;;
          *)
            warn "Skipping non-absolute cache line: $cache_path"
            ;;
        esac
      done <<EOF_CACHE
$CACHE_LOCATION
EOF_CACHE
    else
      warn "Cache purge not confirmed. Cache left intact."
    fi
  fi
else
  info "Cache left intact. Rerun with --purge-cache to request cache cleanup."
fi

success "Uninstall flow complete."
