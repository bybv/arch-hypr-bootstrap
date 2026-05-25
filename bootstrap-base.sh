#!/usr/bin/env bash
# bootstrap-base.sh — post-install provisioning for Arch + Hyprland.
# Idempotent. Safe to re-run.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$REPO_DIR/dotfiles"
STOW_PACKAGES=(hypr waybar fish foot fuzzel mako yazi scripts)

log()  { printf '\033[1;34m[bootstrap]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

require_user() {
    [[ $EUID -ne 0 ]] || die "do not run as root; sudo is invoked where needed"
    [[ -f /etc/arch-release ]] || die "this targets Arch Linux"
    command -v sudo >/dev/null || die "sudo not installed"
}

install_pkglist() {
    local list="$1"
    [[ -f "$list" ]] || { warn "missing $list, skipping"; return; }
    mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$list")
    [[ ${#pkgs[@]} -gt 0 ]] || { warn "no pkgs in $list"; return; }
    log "installing from $(basename "$list"): ${#pkgs[@]} packages"
    sudo pacman -S --needed --noconfirm "${pkgs[@]}"
}

bootstrap_yay() {
    if command -v yay &>/dev/null; then
        log "yay already installed"
        return
    fi
    log "bootstrapping yay"
    sudo pacman -S --needed --noconfirm base-devel git
    local tmp; tmp=$(mktemp -d)
    git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
}

install_aur() {
    local list="$1"
    [[ -f "$list" ]] || return
    mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$list")
    [[ ${#pkgs[@]} -gt 0 ]] || return
    log "installing AUR: ${#pkgs[@]} packages"
    yay -S --needed --noconfirm "${pkgs[@]}"
}

enable_services() {
    log "enabling system services"
    local services=(
        NetworkManager.service
        bluetooth.service
        tlp.service
        fstrim.timer
        fwupd-refresh.timer
        snapper-timeline.timer
        snapper-cleanup.timer
        grub-btrfsd.service
    )
    for svc in "${services[@]}"; do
        if ! systemctl is-enabled "$svc" &>/dev/null; then
            sudo systemctl enable --now "$svc" 2>/dev/null \
                || warn "could not enable $svc (may not be installed yet)"
        fi
    done
}

set_fish_shell() {
    local current; current=$(getent passwd "$USER" | cut -d: -f7)
    if [[ "$current" == "/usr/bin/fish" ]]; then
        log "fish already default shell"
        return
    fi
    log "setting fish as default shell"
    chsh -s /usr/bin/fish
}

deploy_dotfiles() {
    [[ -d "$DOTFILES_DIR" ]] || die "no dotfiles dir at $DOTFILES_DIR"
    command -v stow >/dev/null || die "stow not installed"
    log "deploying dotfiles via stow"
    cd "$DOTFILES_DIR"
    for pkg in "${STOW_PACKAGES[@]}"; do
        if [[ ! -d "$pkg" ]]; then
            warn "no stow package: $pkg"
            continue
        fi
        # --restow handles re-runs cleanly: removes then re-adds links
        stow --restow --target="$HOME" "$pkg" \
            || warn "stow conflict for $pkg — resolve and re-run"
    done
    # Ensure scripts are executable (stow preserves perms but git can lose them)
    if [[ -d "$HOME/.local/bin" ]]; then
        find "$HOME/.local/bin" -maxdepth 1 -type l -exec chmod +x {} \;
    fi
}

setup_snapper_home() {
    if sudo snapper -c home list &>/dev/null; then
        log "snapper home config exists"
        return
    fi
    if mountpoint -q /home; then
        log "creating snapper config for /home"
        sudo snapper -c home create-config /home || warn "snapper home failed"
    fi
}

summary() {
    cat <<'EOF'

[bootstrap] complete.

next:
  1. reboot
  2. log in on tty1 — fish autostart will launch Hyprland
  3. verify:
       hyprctl monitors
       wpctl status
       systemctl --user status xdg-desktop-portal
  4. if anything is wrong, see the troubleshooting section in README.md

EOF
}

main() {
    require_user
    log "syncing and updating"
    sudo pacman -Syu --noconfirm
    install_pkglist "$REPO_DIR/pkglists/base.txt"
    install_pkglist "$REPO_DIR/pkglists/hw-thinkpad.txt"
    bootstrap_yay
    install_aur "$REPO_DIR/pkglists/aur-base.txt"
    enable_services
    set_fish_shell
    deploy_dotfiles
    setup_snapper_home
    summary
}

main "$@"
