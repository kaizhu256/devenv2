#!/bin/sh
# sh ~/Documents/devenv/lnsync.sh
{(set -e
    # [ -d "$HOME/Documents/devenv" ] && cd "$HOME/Documents/devenv"
    DIR_DEVENV="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
    FILE=""
    FILE_DEVENV=""
    FILE_HOME=""
    mkdir -p "$HOME/.vim"
    # ln ~
    for FILE in \
        .vimrc \
        jslint.mjs \
        jslint_ci.sh \
        jslint_wrapper_vim.vim
    do
        FILE_DEVENV="$DIR_DEVENV/$FILE"
        FILE_HOME="$HOME/$FILE"
        case "$FILE" in
        jslint_wrapper_vim.vim)
            FILE_HOME="$HOME/.vim/$FILE"
            ;;
        esac
        if [ -f "$FILE_HOME" ]
        then
            ln -f "$FILE_HOME" "$FILE_DEVENV"
        else
            ln -f "$FILE_DEVENV" "$FILE_HOME"
        fi
        if [ -f "$FILE" ]
        then
            ln -f "$FILE_DEVENV" "$FILE" || true
        fi
    done
    ln -f "$HOME/jslint.mjs" "$HOME/.vim/jslint.mjs"
    git diff
)}
