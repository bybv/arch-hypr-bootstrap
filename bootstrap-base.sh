#!/usr/bin/env bash
# bootstrap-base.sh — post-install provisioning for Arch + Hyprland.
# Idempotent. Safe to re-run.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$REPO_DIR/dotfiles"
STOW_PACKAGES=(hypr waybar fish foot fuzzel mako yazi scripts)

# AUR is unvetted, user-submitted build scripts. Default: review every PKGBUILD
# (and diff on upgrades) interactively before building. Set AUR_NOCONFIRM=1 only
# for unattended re-runs once you already trust the pinned sources.
AUR_NOCONFIRM="${AUR_NOCONFIRM:-0}"

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
    log "bootstrapping yay (AUR helper)"
    sudo pacman -S --needed --noconfirm base-devel git
    local tmp; tmp=$(mktemp -d)
    git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    if [[ "$AUR_NOCONFIRM" != "1" ]]; then
        if [[ -t 0 ]]; then
            log "review the yay-bin PKGBUILD before building (q to quit pager):"
            "${PAGER:-less}" "$tmp/yay-bin/PKGBUILD"
            read -rp "build and install yay-bin from this PKGBUILD? [y/N] " ans
            [[ "$ans" =~ ^[Yy] ]] || { rm -rf "$tmp"; die "yay bootstrap aborted by user"; }
        else
            rm -rf "$tmp"
            die "non-interactive shell and AUR_NOCONFIRM unset — cannot review yay-bin PKGBUILD. Re-run in a terminal, or set AUR_NOCONFIRM=1 to trust it."
        fi
    fi
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
}

install_aur() {
    local list="$1"
    [[ -f "$list" ]] || return
    mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$list")
    [[ ${#pkgs[@]} -gt 0 ]] || return
    local flags=(-S --needed --cleanafter)
    if [[ "$AUR_NOCONFIRM" == "1" ]]; then
        warn "AUR_NOCONFIRM=1 — installing ${#pkgs[@]} AUR package(s) WITHOUT PKGBUILD review"
        flags+=(--noconfirm)
    else
        log "installing ${#pkgs[@]} AUR package(s) — yay shows each PKGBUILD/diff; read before accepting"
    fi
    yay "${flags[@]}" "${pkgs[@]}"
}

enable_services() {
    log "enabling system services"
    local services=(
        NetworkManager.service
        bluetooth.service
        tlp.service
        thermald.service
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

regenerate_grub() {
    if [[ -d /boot/grub ]]; then
        log "regenerating GRUB config (picks up grub-btrfs snapshot entries)"
        sudo grub-mkconfig -o /boot/grub/grub.cfg || warn "grub-mkconfig failed"
    else
        warn "/boot/grub missing — not a GRUB system? skipping grub-mkconfig"
    fi
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

configure_git_delta() {
    command -v delta >/dev/null || { warn "delta not installed, skipping git pager config"; return; }
    log "configuring git to use delta as diff pager"
    # Only sets delta-related keys; leaves user identity and everything else alone.
    git config --global core.pager delta
    git config --global interactive.diffFilter 'delta --color-only'
    git config --global delta.navigate true
    git config --global delta.line-numbers true
    git config --global merge.conflictStyle zdiff3
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
        # --no-folding keeps target dirs real (symlinks per file), so a new
        # per-machine file like hypr/host.conf can't accidentally land in the
        # repo via a folded directory symlink. --restow makes re-runs clean.
        stow --no-folding --restow --target="$HOME" "$pkg" \
            || warn "stow conflict for $pkg — resolve and re-run"
    done
    # Ensure scripts are executable (stow preserves perms but git can lose them)
    if [[ -d "$HOME/.local/bin" ]]; then
        find "$HOME/.local/bin" -maxdepth 1 -type l -exec chmod +x {} \;
    fi
    # Per-machine Hyprland overrides live outside git; create the empty file so
    # the `source` line in hyprland.conf doesn't warn on a fresh machine.
    mkdir -p "$HOME/.config/hypr"
    touch "$HOME/.config/hypr/host.conf"
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
    regenerate_grub
    set_fish_shell
    configure_git_delta
    deploy_dotfiles
    setup_snapper_home
    summary
}

main "$@"
