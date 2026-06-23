# Changelog

## June 2026

### 2026-06-23
- Yazi: add `glow` markdown opener (`o` views in glow pager, `O` chooser), wider preview ratio `[1,3,5]`, zoxide/fzf jump binds (`z`/`Z`, built-in plugins) plus `init.lua` `update_db`, and an `e` bind that edits in `$EDITOR`. Open rule matches by `url = "*.md"` (mime detects `.md` as text/plain). Set `EDITOR=micro` in fish `config.fish`. Add `glow`, `micro`, and `fzf` (moved from `apps-dev.txt`, needed by the jump binds) to `base.txt`.

### 2026-06-17
- Harden AUR exposure: install AUR with PKGBUILD/diff review on by default (no more blanket `--noconfirm`), `AUR_NOCONFIRM=1` to opt out; review yay-bin's PKGBUILD before the first build; add `--cleanafter`. Move satty + hyprshot out of the AUR list into base.txt (now in `extra`), leaving Bibata cursor as the only AUR package. Document AUR-minimization rationale and the vendored-tarball path to zero AUR in DECISIONS.md.

### 2026-06-07
- Add Super-based volume binds via swayosd as redundancy for keyboards without dedicated media keys: Super+= raise, Super+- lower, Super+0 mute-toggle.

### 2026-06-06
- Add window-fill-height script + Super+Shift+C bind: float the active window, expand it to full monitor height, and center it horizontally while keeping its current width (for centered columns on wide monitors).
- Add Super-based media binds via playerctl: Super+C play/pause, Super+[ previous, Super+] next.

### 2026-06-02
- Add modern CLI tools to base.txt (eza, bat, dust, duf, zoxide, git-delta, btop); alias eza/bat/dust/duf over ls/cat/du/df and zoxide over cd in fish; configure git to use delta as diff pager in bootstrap-base.sh.
