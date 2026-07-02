# Greeting off
set -U fish_greeting

# Default editor: micro (modeless, nano-like). Drives yazi `e` + bulk-rename, git.
set -gx EDITOR micro

# Auto-launch Hyprland on tty1 only, login shells only
if status is-login
    if test -z "$DISPLAY"; and test "$XDG_VTNR" = "1"
        exec dbus-run-session Hyprland
    end
end

# Server hostname for waybar status module — edit once, applies everywhere
set -gx HOME_SERVER server.local

# Aliases — modern CLI tools aliased over the originals (installed via base.txt)
alias ls='eza --group-directories-first --icons=auto'
alias ll='eza -lah --group-directories-first --icons=auto --git'
alias cat='bat'
alias du='dust'
alias df='duf'
alias g='git'
alias y='yazi'

# zoxide: smarter cd. --cmd cd makes `cd` itself use zoxide (z/zi still work).
if command -q zoxide
    zoxide init fish --cmd cd | source
end

# ── What the interactive bits do (cheat-sheet) ────────────────────────────────
#   Up arrow    inline search of THIS shell's own fish history (fast, native)
#   Ctrl-R      atuin: fuzzy search of your FULL history (fish + imported bash)
#   Ctrl-T      fzf: pick a file and drop its path onto the command line
#   Alt-C       fzf: pick a subdirectory and cd into it
#   fo <query>  fzf: pick a file and open it in its default app (xdg-open)
#   Ctrl-J      fuzzy-jump to a bookmarked dir (list in ~/.config/fish/bm_dirs)
#   z <name>    zoxide: jump to a frequently-used dir by partial name (zi = pick)
#   yy          open yazi; on quit, cd to whatever directory you ended up in
#   Esc         vi mode: insert -> normal (block cursor); i / a re-enter insert
# ──────────────────────────────────────────────────────────────────────────────

# Vi key bindings + per-mode cursor shape (block = normal/command, beam = insert).
# Custom binds (e.g. Ctrl-J jump) live in functions/fish_user_key_bindings.fish.
set -g fish_key_bindings fish_vi_key_bindings
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore
set fish_cursor_visual block

# fzf: Ctrl-T (insert file path), Alt-C (cd into a subdir). Ctrl-R goes to atuin below.
# fd-backed listing (fast, respects .gitignore); bat preview pane on Ctrl-T.
# fo <query> (functions/fo.fish) fuzzy-picks a file and opens it via xdg-open.
if command -q fzf
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_CTRL_T_OPTS '--preview "bat --color=always --style=numbers --line-range=:200 {}"'
    fzf --fish | source
end

# atuin: SQLite shell history with a fuzzy Ctrl-R popup. Sourced after fzf so it
# wins the Ctrl-R binding. --disable-up-arrow keeps fish's native prefix search.
if command -q atuin
    atuin init fish --disable-up-arrow | source
end

# PATH additions
if test -d "$HOME/.local/bin"
    fish_add_path "$HOME/.local/bin"
end
