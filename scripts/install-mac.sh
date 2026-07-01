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
Usage: install-mac.sh [--force] [-h|--help]

Install Azure AI Foundry Local on macOS Apple Silicon.

Options:
  --force       Reinstall foundrylocal even if foundry is already present.
  -h, --help    Show this help text.

This script requires Xcode Command Line Tools and Homebrew.
USAGE
}

FORCE=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      FORCE=1
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

[ -f "$CATALOG" ] || die "Model catalog not found at $CATALOG"

if [ "$(uname -s)" != "Darwin" ]; then
  die "This installer targets macOS. Use the alternate installer if needed: https://aka.ms/foundry-local-installer"
fi

ARCH="$(uname -m)"
if [ "$ARCH" != "arm64" ]; then
  warn "This Mac is $ARCH, not arm64. Foundry Local works best on Apple Silicon."
fi

if ! xcode-select -p >/dev/null 2>&1; then
  die "Xcode Command Line Tools are missing. Run: xcode-select --install"
fi
success "Xcode Command Line Tools found."

if ! command -v brew >/dev/null 2>&1; then
  die "Homebrew is missing. Install it from https://brew.sh, then rerun this script."
fi
success "Homebrew found at $(command -v brew)."

if command -v foundry >/dev/null 2>&1 && [ "$FORCE" -eq 0 ]; then
  info "foundry is already installed. Use --force to reinstall."
else
  info "Tapping microsoft/foundrylocal."
  brew tap microsoft/foundrylocal
  if command -v foundry >/dev/null 2>&1 && [ "$FORCE" -eq 1 ]; then
    info "Reinstalling foundrylocal."
    brew reinstall foundrylocal || brew install foundrylocal
  else
    info "Installing foundrylocal."
    brew install foundrylocal
  fi
fi

if ! command -v foundry >/dev/null 2>&1; then
  die "foundry was not found after install. Check Homebrew output above."
fi

info "Verifying foundry."
foundry --version

info "Starting Foundry Local service."
if ! SERVICE_OUTPUT="$(foundry service start 2>&1)"; then
  printf '%s\n' "$SERVICE_OUTPUT" >&2
  if printf '%s\n' "$SERVICE_OUTPUT" | grep -qi 'Request to local service failed'; then
    warn "Local service request failed. Restarting service."
    foundry service restart
  else
    die "Failed to start Foundry Local service."
  fi
else
  printf '%s\n' "$SERVICE_OUTPUT"
fi

info "Service status."
if ! STATUS_OUTPUT="$(foundry service status 2>&1)"; then
  printf '%s\n' "$STATUS_OUTPUT" >&2
  if printf '%s\n' "$STATUS_OUTPUT" | grep -qi 'Request to local service failed'; then
    warn "Local service request failed. Restarting service."
    foundry service restart
    foundry service status
  else
    die "Failed to read Foundry Local service status."
  fi
else
  printf '%s\n' "$STATUS_OUTPUT"
fi

success "Azure AI Foundry Local is installed."
cat <<'NEXT'

Next steps:
  List available Foundry models: bash scripts/list-models.sh
  View curated catalog: bash scripts/list-models.sh --catalog
  Download starter profile: bash scripts/download-models.sh --profile starter
  Print local endpoint and curl example: bash scripts/serve.sh
NEXT
