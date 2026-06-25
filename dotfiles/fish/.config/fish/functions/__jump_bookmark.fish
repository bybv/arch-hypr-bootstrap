function __jump_bookmark --description 'fzf-pick a bookmarked dir and cd into it'
    set -l bm_file "$HOME/.config/fish/bm_dirs"
    test -f "$bm_file"; or return
    set -l dir (
        command grep -vE '^[[:space:]]*(#|$)' "$bm_file" \
        | string replace -- '~' "$HOME" \
        | fzf --height 40% --reverse --prompt 'jump> '
    )
    if test -n "$dir"
        builtin cd -- "$dir"
        commandline -f repaint
    end
end
