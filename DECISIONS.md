# Design decisions

Why the non-obvious choices are the way they are. Read this before "simplifying"
something — most of these were deliberate.

## Bootloader: GRUB, not systemd-boot
systemd-boot is simpler, but has no menu-driven snapshot rollback. GRUB +
grub-btrfs gives a boot menu entry listing every snapshot, so a broken system
recovers without a live USB. The recovery use case won over the simplicity.

## grub-btrfs lives in base.txt, not archinstall.json
grub-btrfs installs a pacman hook and the grub-btrfsd daemon that watch the
running system's /.snapshots and regenerate the live GRUB config. Installing it
during archinstall's minimal phase is pointless — it belongs on the provisioned
system. The JSON carries only the snapshot primitives (snapper, snap-pac).

## Audio/brightness keys: swayosd, not raw wpctl/brightnessctl
The bar is hidden by default (start_hidden), so without an OSD there'd be no
visual feedback when changing volume or brightness. swayosd-client shows a brief
overlay on each change regardless of bar state. Worth the extra daemon.

## No system tray
Replaced by fuzzel-driven menus: Super+W (wifi), Super+B (bluetooth),
Super+Shift+X (power). Keyboard-driven, no tray applets to run, no duplicate
paths to the same actions. blueman stays installed as a GUI escape hatch for
first-time device pairing only.

## AUR helper: yay, not paru
Functionally equivalent. yay was already familiar; switching for marginal
cosmetic gains would only add unfamiliar variables during bring-up.

## AUR exposure: minimize, and review by default
The AUR is unvetted, user-submitted PKGBUILDs — periodic malware/typosquat
waves are a known risk. Switching distro is the wrong fix: the Arch-family
siblings (EndeavourOS, CachyOS, Manjaro) all share the *same* AUR, and a real
escape (Fedora/openSUSE) means rewriting the whole bootstrap for worse Hyprland
support. Instead we shrink the attack surface and review what's left:
- Prefer official-repo packages. satty and hyprshot graduated to `extra` and
  were moved out of the AUR list; only the cursor theme is AUR-only now.
- bootstrap installs AUR with PKGBUILD/diff review **on by default** (no
  `--noconfirm`). `AUR_NOCONFIRM=1` restores unattended behavior once trusted.
- `yay-bin` itself is reviewed the same way before the first build.

## Cursor theme: AUR vs vendored tarball
Bibata is the one package with no official-repo equivalent, so it's the lone
AUR entry. It's pure data (no compiled code), which makes it the easiest thing
to de-AUR entirely: fetch a pinned upstream release tarball, verify its
checksum, and unpack into `~/.local/share/icons`. That removes the last AUR
dependency (and the need for yay at all on a base install). Kept on AUR for now
because review-by-default already covers it and vendoring needs a pinned
version+hash to be maintained on each bump; the migration is a deliberate
follow-up, not a default. Repo-only fallback if you don't care about Bibata
specifically: the Adwaita cursor ships by default.

## File manager: thunar + yazi, not Dolphin
Dolphin drags in a lot of Qt. thunar is GTK-light for the GUI case; yazi covers
the terminal-first workflow. polkit-gnome (not polkit-kde) pairs with the GTK
choice.

## Login: TTY autostart, not a display manager
Single-user laptop. fish on tty1 execs Hyprland directly. One fewer moving part
than ly/greetd/sddm, and a working shell to debug from if the compositor fails.

## Compositor: Hyprland (with the young-software caveat)
Chosen for active development and large config/LLM corpus. It's the least-Lindy
piece in the stack. If it ever destabilizes, the migration path is Sway — same
ecosystem, mechanical config translation; everything else (dotfiles, audio,
file manager, install flow) stays put.

## Snapshots are not backups
Btrfs snapshots live on the same disk and protect against bad updates/configs,
not drive failure or data loss. Real backups go through the separate
Syncthing → server → restic (local + Backblaze B2) flow.

## Syncthing mesh-join is manual on purpose
Each instance generates a unique device ID at first start, so joining a new
machine is an inherent per-machine handshake (~5 min). Scripting it means
fragile config-file munging that breaks on updates. Accepted as manual.
