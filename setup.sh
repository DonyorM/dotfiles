#!/bin/bash

convert_path() {
    if [ "$OSTYPE" = "msys" ]; then
        echo "${1/\/c\//C:\/}"
    else
        echo "$1"
    fi
}

CUR_DIR="$(cd "$(dirname "$0")"; pwd)"

ln -s "$CUR_DIR/.tmux.conf"  ~/.tmux.conf
ln -s "$CUR_DIR/.vimrc" ~/.vimrc
BASH_SETUP_FILE=". $CUR_DIR/bash_setup"

if ! grep -Fxq "$BASH_SETUP_FILE" ~/.bash_profile; then
    echo "$BASH_SETUP_FILE" >> ~/.bash_profile
fi

GIT_CONFIG_FILE=`convert_path "$CUR_DIR/git.config"`

if ! grep -Exq "\s*path ?= ?$GIT_CONFIG_FILE" ~/.gitconfig; then
    git config --global --add include.path "$GIT_CONFIG_FILE"
fi

