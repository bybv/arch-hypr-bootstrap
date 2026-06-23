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

# PATH additions
if test -d "$HOME/.local/bin"
    fish_add_path "$HOME/.local/bin"
end
