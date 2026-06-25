function fish_user_key_bindings
    # Ctrl-J: fuzzy-jump to a bookmarked directory (see ~/.config/fish/bm_dirs).
    # Bound in both default and insert (vi) modes so it works regardless of mode.
    bind \cj __jump_bookmark
    bind -M insert \cj __jump_bookmark
end
