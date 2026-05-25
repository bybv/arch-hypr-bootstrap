#!/usr/bin/env bash
# bootstrap-check.sh — post-provision health check.
# Read-only: asserts the things that make this a working, recoverable desktop.
# Run it after bootstrap-base.sh (a reboot first is fine too).
#
# Exit 0 if everything passes, 1 if anything failed.

pass=0; fail=0
ok()   { printf '\033[1;32m[ ok ]\033[0m %s\n' "$*"; pass=$((pass+1)); }
bad()  { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*"; fail=$((fail+1)); }
info() { printf '\033[1;34m[info]\033[0m %s\n' "$*"; }

have()        { command -v "$1" >/dev/null 2>&1; }
sys_enabled() { systemctl is-enabled "$1" >/dev/null 2>&1; }
usr_active()  { systemctl --user is-active "$1" >/dev/null 2>&1; }
installed()   { pacman -Q "$1" >/dev/null 2>&1; }

echo "── binaries ──────────────────────────────────────────"
for b in Hyprland waybar foot fish fuzzel mako yay stow wpctl hyprctl grim slurp; do
    if have "$b"; then ok "found $b"; else bad "missing $b"; fi
done

echo "── kernels (fallback safety net) ─────────────────────"
[[ -e /boot/vmlinuz-linux ]]     && ok "linux kernel present"       || bad "linux kernel missing"
[[ -e /boot/vmlinuz-linux-lts ]] && ok "linux-lts fallback present" || bad "linux-lts fallback missing"

echo "── audio firmware ────────────────────────────────────"
installed sof-firmware  && ok "sof-firmware installed"  || bad "sof-firmware missing (no speakers/mic on modern Intel)"
installed alsa-ucm-conf && ok "alsa-ucm-conf installed" || bad "alsa-ucm-conf missing (mixer routing may be wrong)"

echo "── system services ───────────────────────────────────"
for s in NetworkManager.service bluetooth.service tlp.service thermald.service grub-btrfsd.service; do
    sys_enabled "$s" && ok "enabled $s" || bad "not enabled $s"
done
for t in fstrim.timer snapper-timeline.timer snapper-cleanup.timer fwupd-refresh.timer; do
    sys_enabled "$t" && ok "enabled $t" || bad "not enabled $t"
done

echo "── audio session (only meaningful inside your user session) ──"
if usr_active pipewire.service; then ok "pipewire running"; else info "pipewire not active (expected from a bare TTY before login)"; fi

echo "── dotfiles (stow symlinks) ──────────────────────────"
for f in "$HOME/.config/hypr/hyprland.conf" "$HOME/.config/waybar/config.jsonc" "$HOME/.config/fish/config.fish" "$HOME/.local/bin/power-menu"; do
    if [[ -e "$f" ]]; then ok "linked ${f/#$HOME/\~}"; else bad "missing ${f/#$HOME/\~}"; fi
done
[[ -e "$HOME/.config/hypr/host.conf" ]] && ok "host.conf present (per-machine overrides)" || bad "host.conf missing"

echo "── login shell ───────────────────────────────────────"
[[ "$(getent passwd "$USER" | cut -d: -f7)" == "/usr/bin/fish" ]] && ok "fish is login shell" || bad "login shell is not fish"

echo "── GRUB snapshot recovery ────────────────────────────"
if [[ -r /boot/grub/grub.cfg ]]; then
    grep -qi 'snapshot' /boot/grub/grub.cfg \
        && ok "GRUB has snapshot entries" \
        || bad "no snapshot entries in grub.cfg (run: sudo grub-mkconfig -o /boot/grub/grub.cfg)"
else
    info "can't read /boot/grub/grub.cfg without sudo — skipping snapshot check"
fi

echo "──────────────────────────────────────────────────────"
printf 'passed: %d   failed: %d\n' "$pass" "$fail"
if [[ "$fail" -eq 0 ]]; then echo "all good."; exit 0; else echo "review the FAILs above."; exit 1; fi
