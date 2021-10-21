#!/bin/sh
# sh ~/Documents/devenv/lnsync.sh
{(set -e
    # [ -d "$HOME/Documents/devenv" ] && cd "$HOME/Documents/devenv"
    cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
    # ln ~
    for FILE in \
        .vimrc \
        jslint.mjs \
        jslint_ci.sh
    do
        FILE2="$HOME/$FILE"
        if [ -f "$FILE2" ]
        then
            ln -f "$FILE2" "$FILE"
        else
            ln -f "$FILE" "$FILE2"
        fi
    done
    # ln ~/.vim
    mkdir -p "$HOME/.vim"
    ln -f "$HOME/jslint.mjs" "$HOME/.vim/jslint.mjs"
    for FILE in jslint.vim
    do
        FILE2="$HOME/.vim/$FILE"
        if [ -f "$FILE2" ]
        then
            ln -f "$FILE2" "$FILE"
        else
            ln -f "$FILE" "$FILE2"
        fi
    done
    # ln ~/Documents/jslint
    if [ -d "$HOME/Documents/jslint" ]
    then
        ln -f "$HOME/jslint.mjs" "$HOME/Documents/jslint/jslint.mjs"
        ln -f "$HOME/.vim/jslint.vim" "$HOME/Documents/jslint/jslint.vim"
        ln -f "$HOME/jslint_ci.sh" "$HOME/Documents/jslint/jslint_ci.sh"
    fi
    git diff
)}
