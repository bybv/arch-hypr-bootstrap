# Arch + Hyprland Bootstrap — X1 Carbon Daily Driver

A reproducible, lean Hyprland setup for ThinkPad X1 Carbon laptops. Two-stage:
**install** (archinstall + JSON) and **provisioning** (bootstrap script + dotfiles
from this repo).

---

## Design choices (and why)

| Decision | Choice | Reason |
|---|---|---|
| Distro | Raw Arch | Reproducible install via archinstall JSON in git |
| Init / login | TTY autostart on tty1 | One less moving part than a display manager |
| Compositor | Hyprland | Modern Wayland, animations off, large config corpus |
| Bar / launcher / notify | waybar / fuzzel / mako | Lightweight, Wayland-native |
| Terminal | foot | Wayland-native, fast, tiny |
| File manager | thunar (GUI) + yazi (TUI) | GTK-light + terminal-first daily driver |
| Shell | fish | Sensible defaults, good autocomplete, fewer footguns |
| Polkit agent | polkit-gnome | Pairs with thunar (GTK), avoids dragging in Qt for auth |
| Audio | PipeWire + WirePlumber | Standard modern stack |
| Bootloader | GRUB + grub-btrfs | Boot directly into snapshots — recovery without a live USB |
| Filesystem | Btrfs + snapper + snap-pac | Auto pre/post-pacman snapshots |
| Dotfiles | GNU Stow | Symlinks. Easy to inspect, easy to undo |
| AUR helper | yay | Familiar, well-documented, no reason to switch |
| Power mgmt | TLP | ThinkPad-tuned |
| Night light | hyprsunset | Hyprland-native, lightweight, simple config |
| Cursor theme | Bibata-Modern-Classic | High contrast, mature, easy to see |
| Disk encryption | LUKS on root | Set during archinstall, passphrase at boot |

**Things deliberately not included in v1:** display manager, custom theming
beyond defaults, IDE-specific configs, gaming stack, virt stack. Add later by
editing package lists and re-running.

---

## Repo structure

```text
arch-hypr-bootstrap/
├── README.md                         # this file
├── install/
│   └── archinstall.json              # OS install config
├── bootstrap-base.sh                 # post-install provisioning (idempotent)
├── bootstrap-apps.sh                 # role-based app bundles
├── pkglists/
│   ├── base.txt                      # pacman: desktop base
│   ├── hw-thinkpad.txt               # pacman: ThinkPad-specific
│   ├── aur-base.txt                  # AUR: base extras
│   ├── apps-browser.txt              # pacman: browsers
│   ├── apps-browser-aur.txt          # AUR: browsers (placeholder)
│   ├── apps-dev.txt                  # pacman: dev tools
│   ├── apps-dev-extras.txt           # pacman: dev extras (placeholder)
│   ├── apps-media.txt                # pacman: media tools
│   ├── apps-editor.txt               # pacman: editors
│   ├── apps-utils.txt                # pacman: utilities (keepassxc, syncthing)
│   └── apps-audio.txt                # pacman: audio production / DJ
├── dotfiles/                         # stow packages
│   ├── hypr/.config/hypr/
│   │   ├── hyprland.conf
│   │   ├── hyprpaper.conf
│   │   ├── hypridle.conf
│   │   └── hyprlock.conf
│   ├── waybar/.config/waybar/
│   │   ├── config.jsonc
│   │   └── style.css
│   ├── fish/.config/fish/
│   │   └── config.fish
│   ├── foot/.config/foot/
│   │   └── foot.ini
│   ├── fuzzel/.config/fuzzel/
│   │   └── fuzzel.ini
│   ├── mako/.config/mako/
│   │   └── config
│   ├── yazi/.config/yazi/
│   │   └── yazi.toml
│   └── scripts/.local/bin/
│       ├── power-menu
│       ├── bluetooth-menu
│       ├── wifi-menu
│       ├── screenshot-menu
│       ├── waybar-server-status
│       └── waybar-syncthing-status
└── host-overrides/                   # per-machine deltas (optional)
    └── x1c-gen<N>.env
```

---

## Phase 1: Install (archinstall)

### Boot the live USB

1. Get latest Arch ISO, write to USB (`dd` or Ventoy).
2. Boot, get networking (`iwctl` for wifi if needed).
3. Sync time: `timedatectl set-ntp true`.
4. Clone this repo: `pacman -Sy git && git clone <your-repo-url> /tmp/bootstrap`

### Run archinstall with the saved config

```bash
archinstall --config /tmp/bootstrap/install/archinstall.json
```

You'll still be prompted for: disk to wipe, root password, user password,
hostname, **and LUKS passphrase** (encryption is enabled — you'll type this
at every boot, before GRUB can read the kernel). Everything else is in the
JSON.

> **First-install note on encryption:** the JSON does not pre-specify
> encryption details because archinstall's encryption schema changes
> frequently between releases. On your *first* install, walk through
> archinstall's UI interactively and pick LUKS for the root partition.
> Then "Save configuration" and replace `archinstall.json` in this repo with
> the export. Subsequent installs on other machines reuse that working JSON.

### `install/archinstall.json`

> **Note:** archinstall's JSON schema changes between releases. This is the
> intent. After your first successful install, re-export the actual config from
> archinstall's "Save configuration" option and replace this file. That gives
> you a known-good baseline matched to your archinstall version.

**Fill in before use:** `hostname`, `timezone`. The disk gets selected
interactively; don't hardcode it.

### What you get after archinstall

A bootable Arch system with:

- Btrfs root with snapper-friendly subvolume layout (`@`, `@home`, `@.snapshots`,
  `@var_log`, `@var_cache`)
- GRUB + grub-btrfs
- NetworkManager active
- A user with sudo
- intel-ucode loaded
- Nothing else. No desktop yet.

Reboot, log in on the TTY, and continue to Phase 2.

---

## Phase 2: Provisioning (`bootstrap-base.sh`)

### What this does

1. Updates the system.
2. Installs the desktop base from `pkglists/base.txt`.
3. Installs ThinkPad hardware extras from `pkglists/hw-thinkpad.txt`.
4. Bootstraps `yay` (AUR helper).
5. Enables system services.
6. Symlinks dotfiles via `stow`.
7. Sets fish as login shell.
8. Configures snapper for root.

It's **idempotent**: safe to re-run after fixing a failure mid-way.

### How to run

**Get online first.** NetworkManager is running but not yet connected, and this
step needs the network. On the bare TTY the cleanest option is `nmtui` — an
arrow-key menu to pick your SSID and enter the password, no syntax to memorize.
(Ethernet or a USB-C dongle connects with nothing to type. Once Hyprland is up,
`Super+W` handles wifi from then on.)

```bash
git clone <your-repo-url> ~/repos/arch-hypr-bootstrap
cd ~/repos/arch-hypr-bootstrap
./bootstrap-base.sh
```

---

## Phase 3: Apps (`bootstrap-apps.sh`)

Same pattern, but installs role bundles. Run once per role you want.

```bash
./bootstrap-apps.sh browser
./bootstrap-apps.sh dev
./bootstrap-apps.sh media
```

Each role reads `pkglists/apps-<role>.txt` (pacman) and, if present,
`pkglists/apps-<role>-aur.txt` (AUR via yay).

---

## Package lists

All lists live under `pkglists/`. Lines starting with `#` and blank lines are
ignored. Highlights:

- `base.txt` — the desktop base (compositor, bar, audio, fonts, tooling).
- `hw-thinkpad.txt` — Intel graphics, TLP/thermald, fwupd.
- `aur-base.txt` — hyprshot, satty, Bibata cursor.
- `apps-*.txt` — role bundles (browser, dev, media, editor, utils, audio).

Post-install notes for a couple of lists:

- **apps-utils** (keepassxc, syncthing): after install, enable Syncthing as a
  user service — `systemctl --user enable --now syncthing.service`. Bitwarden is
  a browser extension, no desktop package needed.
- **apps-audio** (mixxx, JACK, plugins): add yourself to the realtime group and
  re-login — `sudo usermod -aG realtime $USER`.

---

## Configuration files

> All configs live under `dotfiles/<package>/.config/<app>/` so `stow` mirrors
> them into `~/.config/<app>/`. Do not edit `~/.config/*` directly — edit the
> repo, push, and re-run `stow --restow`.

### hyprsunset (night light)

No config file needed. Driven by command-line flags. The `exec-once` line in
`hyprland.conf` starts it at 4500K (mild warmth, all-day comfortable).

Common temperatures:
- `6500` — neutral / daylight (effectively off)
- `4500` — mild warmth (default here)
- `3500` — strong warmth (evening)
- `2700` — very warm (late night)

Adjust on the fly:

```bash
hyprctl hyprsunset temperature 3500   # set to 3500K
hyprctl hyprsunset gamma 80           # dim to 80% (0-100)
hyprctl hyprsunset identity           # reset (effectively off)
```

The `SUPER+N` bind in `hyprland.conf` toggles it on/off via signal. For
time-of-day automation (auto-warm at sunset), revisit later — for v1, manual
toggle is fine.

### Fuzzel-driven menu scripts

These live in `dotfiles/scripts/.local/bin/` so stow symlinks them into
`~/.local/bin/`. Make sure they're executable in the repo
(`chmod +x dotfiles/scripts/.local/bin/*`) — git tracks the executable bit.
The bootstrap script's `chmod +x` pass is a safety net.

The server-status script reads `$HOME_SERVER` if set, otherwise falls back to
`server.local`. Set `HOME_SERVER` in `~/.config/fish/config.fish` (or the
script itself) to your actual hostname. One edit, applies everywhere.

---

## X1 Carbon hardware notes

The `pkglists/hw-thinkpad.txt` covers nearly everything. A few things to verify
per machine:

**Per-generation differences**

- Gen 6 / Gen 7 (Intel 8th–10th gen): `intel-media-driver` works; verify with
  `vainfo`.
- Gen 9+ (Intel 11th gen+): same, plus may benefit from `linux-firmware` updates
  via `fwupdmgr update`.
- Fingerprint reader: model-dependent. Check `lsusb`. If supported, install
  `fprintd` and run `fprintd-enroll`.

**Power: TLP defaults are good**, but verify after first boot:

```bash
sudo tlp-stat -s     # status
sudo tlp-stat -b     # battery
```

**Suspend works out of the box** on modern X1 Carbons (s2idle). If it doesn't:

```bash
journalctl -b -g suspend
cat /sys/power/mem_sleep   # should show [s2idle]
```

**Per-machine overrides** go in `host-overrides/<hostname>.env`. Source from
`bootstrap-base.sh` if you need them. For most setups you won't.

**USB-C hubs and docks**

Almost always plug-and-play. The kernel handles USB hubs, USB ethernet
adapters, SD card readers, and DisplayPort-over-USB-C (the most common way
hubs drive external monitors). The X1 Carbon supports DP alt-mode natively.

The one exception: **DisplayLink** docks. These do USB-to-display conversion
in software, not real DisplayPort, and need the proprietary `displaylink`
driver from AUR plus the `evdi` kernel module. You'd know if you have one —
the box says "DisplayLink" and they're usually pricier "universal" docks
that work over plain USB-A. Cheap USB-C hubs are essentially never DisplayLink.

When you plug a hub in, verify with:

```bash
lsusb              # see if devices enumerated
hyprctl monitors   # see if external display appeared
ip link            # see if USB ethernet showed up
```

If a new monitor doesn't show, add an explicit `monitor=` line in
`hyprland.conf` using the name from `hyprctl monitors`.

---

## Btrfs + snapper rollback

After install you have:
- `@` mounted at `/`
- `@home` at `/home`
- `@.snapshots` at `/.snapshots`
- `@var_log`, `@var_cache` (excluded from root snapshots — good)

`snap-pac` takes pre/post snapshots automatically on every `pacman` transaction.
`grub-btrfs` watches `/.snapshots` and regenerates the GRUB menu whenever
snapshots change, so they always show up at boot.

**Manual snapshot:**

```bash
sudo snapper -c root create -d "before fiddling"
```

**List snapshots:**

```bash
sudo snapper -c root list
```

### Rolling back from a working system

If the system still boots:

```bash
sudo snapper -c root list                  # find the snapshot number
sudo snapper -c root rollback <number>     # roll back
sudo reboot
```

That's it. No live USB.

### Rolling back from a broken system (the reason we chose GRUB)

If a bad update or config leaves the system unbootable:

1. **Power on.** At the GRUB menu, scroll down to `Arch Linux snapshots`.
2. Pick a snapshot from before things broke (named by date and, for pacman
   snapshots, the command that triggered them).
3. The system boots into that snapshot **read-only**. This is by design —
   you're verifying it's the right one before committing.
4. Confirm the system works (try to reproduce the issue, log in, whatever).
5. From a terminal, run:
   ```bash
   sudo snapper -c root rollback
   ```
   With no number argument, snapper rolls back to the snapshot you're
   currently booted into.
6. Reboot. You're back on a working system, with the broken state itself
   preserved as a snapshot in case you want to inspect it later.

No live USB, no chroot, no syntax to memorize between rollbacks. The only
thing you need to remember is "boot the snapshot, run `snapper rollback`,
reboot."

### Snapshot retention

`snapper` defaults are sensible (a few hourly, daily, weekly, monthly). Edit
`/etc/snapper/configs/root` if you want to tune retention. The
`snapper-cleanup.timer` enforces it.

---

## First-time setup tasks (per machine)

Things that need ~5 minutes of manual work after `bootstrap-base.sh` and the
relevant `bootstrap-apps.sh` runs. Not scriptable cleanly; just do them once.

### Cloning the bootstrap repo (if it's private)

If the repo lives in a private GitHub account, the new machine has no auth yet.
Easiest path:

```bash
sudo pacman -S github-cli
gh auth login
# choose: GitHub.com → HTTPS → Yes (Git auth) → Login with web browser
# enter the one-time code shown at github.com/login/device
git clone https://github.com/<you>/arch-hypr-bootstrap ~/repos/arch-hypr-bootstrap
```

After this, all `git` operations on private repos work without SSH keys. SSH
keys can come later from your KeePassXC vault once Syncthing has pulled it
down.

If the bootstrap repo is public, skip this step entirely.

### SSH keys

Restored from your KeePassXC vault once it's available on the new machine
(via Syncthing — see below). Save them to `~/.ssh/`, set `chmod 600` on the
private key, and run `ssh-add` to load it.

### Syncthing — joining the existing mesh

There's no clean automation for this. Each Syncthing instance generates a
unique device ID at first start, so every new machine is a one-time handshake.

```bash
systemctl --user enable --now syncthing.service
xdg-open http://localhost:8384      # opens the web UI in your browser
```

Then:

1. In the web UI, **Actions → Show ID**. Copy it.
2. On your server's Syncthing, **Add Remote Device**, paste the ID, name it.
3. Server-side, share the relevant folders to the new device.
4. Back on the new machine, accept the share dialogs. For each, choose where
   the folder lives on disk (your convention).

After this, sync runs automatically forever. Keep a personal note in your
KeePassXC vault listing your device IDs and which folders are shared where —
saves time when you set up the next machine.

### KeePassXC — opening your vault

Your `.kdbx` file syncs in via Syncthing. Once it lands:

```bash
keepassxc &
# File → Open → point at the synced .kdbx
```

Set it to "Open last database on startup" in KeePassXC's settings if you want
it to auto-open.

### Browser sign-ins

Bitwarden extension → install from browser store → sign in with your master
password. Everything else (Firefox sync, etc.) follows from there.

### Per-machine Hyprland tweaks

Run `hyprctl monitors` to see your display names. If you have a multi-monitor
setup or want explicit refresh rate / scaling, add a `monitor=` line to a
machine-specific `~/.config/hypr/host.conf` (untracked) and add this near the
top of `hyprland.conf`:

```ini
source = ~/.config/hypr/host.conf
```

This keeps the dotfiles repo identical across machines — the per-machine
delta is one untracked file.

---

## Iteration workflow

This is the loop you'll actually live in:

1. **Add a package**: edit `pkglists/base.txt` (or apps), commit, push.
2. **On any machine**: `git pull && ./bootstrap-base.sh` — `--needed` skips
   already-installed, so this is fast.
3. **Tweak a config**: edit the file under `dotfiles/`, commit, push.
4. **Apply config**: `git pull` — symlinks already point into the repo, so
   changes are live. For Hyprland, reload with `hyprctl reload`. Some apps
   (waybar, mako) need a restart: `pkill -SIGUSR2 waybar` or `pkill mako && mako &`.
5. **Audit installed packages periodically:**
   ```bash
   pacman -Qqe > /tmp/explicit.txt
   diff <(sort pkglists/base.txt pkglists/hw-thinkpad.txt | grep -vE '^\s*(#|$)') \
        <(sort /tmp/explicit.txt)
   ```
   Anything in installed-but-not-in-lists is either drift (add it) or cruft
   (remove it).

---

## v1 milestone — sanity check after first boot

Don't perfect before first boot. Get to a daily-driveable state, then iterate.
Verify in this order — fastest feedback first, each step independent:

1. **TTY login → Hyprland starts.** If not, fish autostart didn't fire (see
   troubleshooting).
2. **Touchpad and keyboard work.** Move the mouse, type a key.
3. **Wifi works.** `Super+W` opens the wifi menu, you can connect.
4. **Sound works.** Tap volume up/down — swayosd overlay appears, level
   changes. Verify with `wpctl status` if no sound.
5. **Brightness keys work.** Same pattern — overlay should appear.
6. **Terminal opens** with `Super+Return`.
7. **Launcher opens** with `Super+D`. Type a few letters of an app name.
8. **Browser launches and renders pages.**
9. **Waybar toggles** with `Super+/`. Battery, clock, server status,
   syncthing icon all show.
10. **Plug in a USB stick.** Notification fires; thunar shows it
    automatically (`udiskie` did its job).
11. **Plug in your phone (MTP).** Thunar shows it after a second; you can
    browse files.
12. **Bluetooth menu** with `Super+B`. Pair or connect a device.
13. **Screenshot** — press Print, pick "region → clipboard", select an area,
    paste into a chat.
14. **Annotate** — Print → "region → annotate (satty)". Draw a circle, save.
15. **Lock screen** — `Super+Shift+L`. hyprlock appears, password unlocks.
16. **Lid close test** — close lid, wait 10 seconds, open. You should land
    on hyprlock, not the unlocked desktop. (`before_sleep_cmd` in
    hypridle.conf is what makes this work.)

Everything else (theming, fonts you actually like, neovim config, dev
workflow, fancier waybar) is iteration after you're daily-driving it.

If any step fails, that's the only thing to debug — the rest are
independent. See the failure points section below for common fixes.

---

## Failure points (troubleshooting)

### TTY autostart didn't fire after login

- Confirm shell: `echo $SHELL` — should be `/usr/bin/fish`. If not, `chsh -s
  /usr/bin/fish` and re-login.
- Confirm config exists: `ls -la ~/.config/fish/config.fish` — should be a
  symlink into the repo.
- Confirm you're on tty1: `tty` returns `/dev/tty1`.
- Test manually: `dbus-run-session Hyprland`.

### Hyprland starts then crashes

- Get the log: `~/.local/share/hyprland/hyprland.log` (or check
  `journalctl --user -b`).
- Most common: typo in `hyprland.conf`. Validate with `hyprctl reload` from a
  TTY (after starting hyprland from another tty).

### No sound

```bash
systemctl --user status pipewire wireplumber
wpctl status
pavucontrol      # set default device if multiple available
```

If still nothing: `systemctl --user restart pipewire pipewire-pulse wireplumber`.

### Brightness keys do nothing

- `brightnessctl` installed?
- User in `video` group? `groups` should list it. If not: `sudo usermod -aG video $USER` and re-login.
- Test bind: `wev` shows actual key events; check the symbol matches the bind.

### Polkit prompts never appear (USB drive won't mount in thunar)

- Agent running? `pgrep -af polkit-gnome-authentication-agent-1`
- If not, the `exec-once` line in `hyprland.conf` failed. Check the path:
  `pacman -Ql polkit-gnome | grep authentication-agent-1$`
- Re-login to ensure it starts cleanly.

### Screenshare / file picker broken

```bash
systemctl --user status xdg-desktop-portal xdg-desktop-portal-hyprland
```

If `xdg-desktop-portal-gnome` is also installed (pulled in by some app), it can
hijack the portal. Remove it: `sudo pacman -R xdg-desktop-portal-gnome`.

### Clipboard history empty

```bash
pgrep -af 'wl-paste.*cliphist'
```

Should show two processes (text + image watchers). If not, the `exec-once`
lines didn't run; restart Hyprland or run them manually.

### Bluetooth doesn't appear

```bash
systemctl status bluetooth
rfkill list
```

Unblock if needed: `rfkill unblock bluetooth`.

### Stow conflict (file already exists)

You ran the bootstrap and an app had already created a config file. Move it
aside and re-run:

```bash
mv ~/.config/foo/config ~/.config/foo/config.bak
cd ~/repos/arch-hypr-bootstrap/dotfiles && stow --restow --target="$HOME" foo
```

### Snapshot rollback didn't work

- If the GRUB menu shows no `Arch Linux snapshots` entry: confirm
  `grub-btrfsd.service` is running (`systemctl status grub-btrfsd`) and
  that snapshots exist (`sudo snapper -c root list`). Trigger a regen with
  `sudo grub-mkconfig -o /boot/grub/grub.cfg`.
- If you boot a snapshot but `snapper rollback` complains: confirm you
  actually booted into the snapshot (`findmnt /` should show a
  `.snapshots/<num>/snapshot` subvolume), not the live root.
- If GRUB itself is broken (won't boot at all): live-USB chroot is the
  fallback. Mount root with `-o subvol=@`, chroot in, run
  `grub-install` and `grub-mkconfig -o /boot/grub/grub.cfg`.

### Multi-monitor wrong

```bash
hyprctl monitors
```

Use the names shown to write explicit monitor lines in `hyprland.conf`. Put
machine-specific overrides in `host-overrides/<hostname>.env` and source from
the config (Hyprland supports `source = ` for that).

---

## Notes for future-you

- The first install will reveal at least one thing this doc gets wrong. When it
  does, fix the doc and the script in the same commit.
- Don't add a display manager unless you have a reason. The TTY path is fewer
  moving parts.
- Don't add animations or theming until everything else is rock-solid.
- Whenever you find yourself running a one-off command twice, put it in the
  bootstrap.
- When something stops working after a `pacman -Syu`, check `snap-pac` history
  — there's almost certainly a snapshot from right before the update.
