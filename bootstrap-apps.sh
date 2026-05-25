#!/usr/bin/env bash
# bootstrap-apps.sh — install role-based app bundles.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROLE="${1:-}"

log()  { printf '\033[1;34m[apps]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

[[ -n "$ROLE" ]] || die "usage: $0 <role> (browser|dev|media)"

PACLIST="$REPO_DIR/pkglists/apps-${ROLE}.txt"
AURLIST="$REPO_DIR/pkglists/apps-${ROLE}-aur.txt"

[[ -f "$PACLIST" ]] || [[ -f "$AURLIST" ]] || die "no list for role: $ROLE"

if [[ -f "$PACLIST" ]]; then
    mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$PACLIST")
    [[ ${#pkgs[@]} -gt 0 ]] && sudo pacman -S --needed --noconfirm "${pkgs[@]}"
fi

if [[ -f "$AURLIST" ]]; then
    command -v yay >/dev/null || die "yay not installed; run bootstrap-base.sh first"
    mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$AURLIST")
    [[ ${#pkgs[@]} -gt 0 ]] && yay -S --needed --noconfirm "${pkgs[@]}"
fi

log "done: $ROLE"
