function fo --description 'fuzzy-find a file and open it with its default app'
    set -l file (fzf --query "$argv" --preview 'bat --color=always --style=numbers --line-range=:200 {}')
    if test -n "$file"
        xdg-open $file &
        disown
    end
end
