# Codebase-only rule (READ FIRST)

This repo is a bootstrap/config **archive** that has NEVER been deployed to bare
metal. The owner's live machine (kitsune) runs **KDE Plasma** and does NOT run
Hyprland, waybar, or anything else configured here. Nothing in this repo is stowed
or symlinked anywhere — any similar files under ~/.config (e.g. yazi) are
independent hand-maintained copies, not links into this repo. Never run stow to
"sync" them; when the owner authorizes a live change, edit the live file directly.

**Work on the files in this repo only.** Never touch the live system:

- No package installs (pacman/yay/AUR), no builds installed outside the repo
- No stow, no symlinking or copying dotfiles into ~/.config, ~/.local, etc.
- No service/system state changes: systemctl, tailscale set/up/down, nmcli, sysctl
- No "testing" a config or script by activating it on the machine
- No sudo, ever (failed attempts trip faillock and lock the owner out)

The ONLY exception: the owner explicitly says **"do it to my machine"** (or equally
explicit wording) and names the live machine. A request to add or fix something in
this repo is never, by itself, permission to apply it.

Verifying work = reading files, shellcheck/linting, dry runs that write nothing
outside the repo or the scratchpad.
