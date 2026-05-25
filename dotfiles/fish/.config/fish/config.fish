# Greeting off
set -U fish_greeting

# Auto-launch Hyprland on tty1 only, login shells only
if status is-login
    if test -z "$DISPLAY"; and test "$XDG_VTNR" = "1"
        exec dbus-run-session Hyprland
    end
end

# Server hostname for waybar status module — edit once, applies everywhere
set -gx HOME_SERVER server.local

# Aliases
alias ls='ls --color=auto'
alias ll='ls -alh'
alias g='git'
alias y='yazi'

# PATH additions
if test -d "$HOME/.local/bin"
    fish_add_path "$HOME/.local/bin"
end
