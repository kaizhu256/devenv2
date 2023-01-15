#!/bin/sh

# sh one-liner
# (curl -o /tmp/devenv.sh -s https://raw.githubusercontent.com/kaizhu256/devenv2/alpha/devenv.sh && sh /tmp/devenv.sh shDevenvVmInit force)

shDevenvInit() {(set -e
# this function will init devenv in current environment
    local FILE
    local MODE_FORCE
    if [ "$1" = force ]
    then
        MODE_FORCE=1
        shift
    fi
    cd "$HOME"
    # init jslint_ci.sh
    for FILE in .screenrc .vimrc jslint_ci.sh
    do
        if [ ! -f "$FILE" ] || [ "$MODE_FORCE" ]
        then
            curl -s -o "$FILE" \
"https://raw.githubusercontent.com/kaizhu256/devenv2/alpha/$FILE"
        fi
    done
    . ./jslint_ci.sh
    # init devenv
    if (git --version >/dev/null 2>&1)
    then
        if [ ! -d devenv2 ] || [ "$MODE_FORCE" ]
        then
            rm -rf devenv2
            git clone https://github.com/kaizhu256/devenv2 \
                --branch=alpha --single-branch
            . devenv2/devenv.sh
            shDevenvUpdate
        fi
    fi
    # init .bashrc
    if [ ! -f .bashrc ]
    then
        touch .bashrc
    fi
    for FILE in jslint_ci.sh devenv2/devenv.sh
    do
        if [ -f "$FILE" ] && ! (grep -q "^. $FILE$" .bashrc)
        then
            printf "\n. $FILE\n" >> .bashrc
        fi
    done
)}

shDevenvUpdate() {(set -e
# this function will sync devenv in current dir
    if [ ! -d .git ]
    then
        return
    fi
    local FILE
    local FILE_DEVENV
    local FILE_HOME
    # ln file
    mkdir -p "$HOME/.vim"
    for FILE in \
        .vimrc \
        jslint.mjs \
        jslint_ci.sh \
        jslint_wrapper_vim.vim
    do
        FILE_DEVENV="$HOME/devenv2/$FILE"
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
        if [ -f "$FILE" ] && [ "$PWD" != "$HOME/devenv2" ]
        then
            ln -f "$FILE_DEVENV" "$FILE" || true
        fi
    done
    ln -f "$HOME/jslint.mjs" "$HOME/.vim/jslint.mjs"
    # detect nodejs
    if ! ( node --version >/dev/null 2>&1 \
        || node.exe --version >/dev/null 2>&1)
    then
        git --no-pager diff
        return
    fi
    # sync .gitignore
    if [ ! -f .gitignore ]
    then
        touch .gitignore
    fi
    node --eval '
(async function () {
    let data1;
    let data2;
    let file1 = process.argv[1];
    let file2 = process.argv[2];
    let moduleFs = require("fs");
    data1 = await moduleFs.promises.readFile(file1, "utf8");
    data2 = await moduleFs.promises.readFile(file2, "utf8");
    data2 = data2.replace((
        /[\S\s]*?\n# jslint .gitignore end\n|^/m
    ), data1.replace((
        /\$/g
    ), "$$"));
    await moduleFs.promises.writeFile(file2, data2);
}());
' "$HOME/devenv2/.gitignore" .gitignore # '
    #
    git --no-pager diff
)}

shSshKeygen() {(set -e
# this function will generate generic ssh key
    rm -f ~/.ssh/id_ed25519
    rm -f ~/.ssh/id_ed25519.pub
    ssh-keygen \
        -C "your_email@example.com" \
        -N "" \
        -f ~/.ssh/id_ed25519 \
        -t ed25519 \
        >/dev/null 2>&1
)}

shSshReverseTunnelClient() {(set -e
# this function will client-login to ssh-reverse-tunnel
# example use:
# shSshReverseTunnelClient user@localhost:53735 -t bash
    local REMOTE_HOST="$1"
    shift
    local REMOTE_PORT="$(printf $REMOTE_HOST | sed "s/.*://")"
    local REMOTE_HOST="$(printf $REMOTE_HOST | sed "s/:.*//")"
    ssh \
        -oStrictHostKeyChecking=no \
        -oUserKnownHostsFile=/dev/null \
        -p "$REMOTE_PORT" \
        "$REMOTE_HOST" "$@"
)}

shSshReverseTunnelClient2() {(set -e
# this function will client-login to ssh-reverse-tunnel
# example use:
# shSshReverseTunnelClient2 user@proxy:22 user@localhost:53735 -t bash
    local PROXY_HOST="$1"
    shift
    local HOST="$1"
    shift
    local PORT_OFFSET="${1:-0}"
    shift
    if ! (printf "$PROXY" | grep -q ":")
    then
        PROXY="$PROXY:22"
    fi
    local PROXY_PORT="$(printf $PROXY | sed "s/.*://")"
    PROXY="$(printf $PROXY | sed "s/:.*//")"
    ssh \
        -p "$PROXY_PORT" \
        -t \
        "$PROXY" \
        ssh \
            -p "$((53735+"$PORT_OFFSET"))" \
            "$HOST" "$@"
)}

shSshReverseTunnelServer() {(set -e
# this function will create ssh-reverse-tunnel on server
    shSecretCryptoDecrypt
    shSecretVarExport
    local FILE
    local PROXY_HOST="$(printf $SSH_REVERSE_PROXY | sed "s/:.*//")"
    local PROXY_PORT="$(printf $SSH_REVERSE_PROXY | sed "s/.*://")"
    local REMOTE_PORT="$(printf $SSH_REVERSE_REMOTE | sed "s/:.*//")"
    if [ "$REMOTE_PORT" = random ]
    then
        REMOTE_PORT="$(shuf -i 32768-65535 -n 1)"
        SSH_REVERSE_REMOTE=\
"$REMOTE_PORT:$(printf "$SSH_REVERSE_REMOTE" | sed "s/random://")"
    fi
    # init dir .ssh/
    for FILE in authorized_keys id_ed25519 known_hosts
    do
        shSecretFileGet ".ssh/$FILE" "$HOME/.ssh/$FILE"
    done
    # copy private-key to local
    scp \
        -P "$PROXY_PORT" \
        "$HOME/.ssh/id_ed25519" "$PROXY_HOST:~/.ssh/" >/dev/null 2>&1
    ssh \
        -p "$PROXY_PORT" \
        "$PROXY_HOST" "chmod 600 ~/.ssh/id_ed25519" >/dev/null 2>&1
    # create ssh-reverse-tunnel from remote to local
    ssh \
        -N \
        -R"$SSH_REVERSE_REMOTE" \
        -T \
        -f \
        -p "$PROXY_PORT" \
        "$PROXY_HOST" >/dev/null 2>&1
    # loop-print to keep ci awake
    printf "$(whoami)@localhost:$REMOTE_PORT\n"
    while [ 1 ]
    do
        printf "$(whoami)@localhost:$REMOTE_PORT\n"
        date
        sleep 60
    done
)}

"$@"
