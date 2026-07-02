# Changelog

## July 2026

### 2026-07-02
- Fish/fzf: add `fo <query>` function (fuzzy-pick a file, open it in its default app via `xdg-open`, detached so the prompt returns immediately; Esc cancels cleanly). Set `FZF_DEFAULT_COMMAND`/`FZF_CTRL_T_COMMAND` to `fd --type f --hidden --exclude .git` (fast, gitignore-aware listing) and give Ctrl-T a `bat` preview pane. Move `fd` from `apps-dev.txt` to `base.txt` (now backs the shell's fzf integration — same precedent as fzf's earlier move) and add `xdg-utils` to `base.txt` (provides `xdg-open`; only the portals were listed before, which don't).

### 2026-07-01
- File picker: route the FileChooser portal to `xdg-desktop-portal-termfilechooser` (hunkyburrito fork, `aur-base.txt`) so browser upload/download dialogs open yazi in a foot terminal instead of the GTK dialog. New `xdg-portal` stow package carries `hyprland-portals.conf` (pins `org.freedesktop.impl.portal.FileChooser = termfilechooser`, keeps `default = hyprland;gtk`) and the termfilechooser `config` (yazi wrapper, `default_dir=$HOME`, `TERMCMD=foot`); added to `STOW_PACKAGES`. Covers both upload and download by design — see DECISIONS.md "File picker". Added a README troubleshooting entry for verifying the wrapper path/env on the machine.

## June 2026

### 2026-06-25
- Fish: port three workflow upgrades from the legacy-host cherry-pick backlog. Enable vi key bindings with per-mode cursor shape (block normal / beam insert); add `atuin` (base.txt) for a fuzzy Ctrl-R history popup, sourced with `--disable-up-arrow` after fzf so atuin owns Ctrl-R while fzf keeps Ctrl-T/Alt-C; add a `yy` function (yazi that cd's to its last dir on quit) and a Ctrl-J fuzzy directory jump (`__jump_bookmark` + `fish_user_key_bindings`) reading `~/.config/fish/bm_dirs`.

### 2026-06-24
- Docs: add "Possible additions (to consider)" section to README with a neomutt + offline Fastmail mail/contacts candidate (mbsync/msmtp/vdirsyncer/khard), its functionality tradeoffs vs webmail, and a hybrid recommendation. Not decided.
- Hypr: add window rule to open zathura (PDF viewer) fullscreen — `windowrule = fullscreen, class:^(org\.pwmt\.zathura)$`. It otherwise launches as a tiny floating window.

### 2026-06-23
- Yazi: add `glow` markdown opener (`o` views in glow pager, `O` chooser), wider preview ratio `[1,3,5]`, zoxide/fzf jump binds (`z`/`Z`, built-in plugins) plus `init.lua` `update_db`, and an `e` bind that edits in `$EDITOR`. Open rule matches by `url = "*.md"` (mime detects `.md` as text/plain). Set `EDITOR=micro` in fish `config.fish`. Add `glow`, `micro`, and `fzf` (moved from `apps-dev.txt`, needed by the jump binds) to `base.txt`.
### 2026-06-18
- Add `writing` app role (`apps-writing.txt`): Tectonic LaTeX engine plus repo fonts (Libertinus, Adobe Source Serif/Sans) for fontspec; add `docs/latex-writing.md` reference (classes, fonts, package toolkit). Tectonic auto-fetches LaTeX packages so only fonts are listed.

### 2026-06-17
- Harden AUR exposure: install AUR with PKGBUILD/diff review on by default (no more blanket `--noconfirm`), `AUR_NOCONFIRM=1` to opt out; review yay-bin's PKGBUILD before the first build; add `--cleanafter`. Move satty + hyprshot out of the AUR list into base.txt (now in `extra`), leaving Bibata cursor as the only AUR package. Document AUR-minimization rationale and the vendored-tarball path to zero AUR in DECISIONS.md.

### 2026-06-07
- Add Super-based volume binds via swayosd as redundancy for keyboards without dedicated media keys: Super+= raise, Super+- lower, Super+0 mute-toggle.

### 2026-06-06
- Add window-fill-height script + Super+Shift+C bind: float the active window, expand it to full monitor height, and center it horizontally while keeping its current width (for centered columns on wide monitors).
- Add Super-based media binds via playerctl: Super+C play/pause, Super+[ previous, Super+] next.

### 2026-06-02
- Add modern CLI tools to base.txt (eza, bat, dust, duf, zoxide, git-delta, btop); alias eza/bat/dust/duf over ls/cat/du/df and zoxide over cd in fish; configure git to use delta as diff pager in bootstrap-base.sh.
