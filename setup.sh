#!/bin/bash

CUR_DIR="$(cd "$(dirname "$0")"; pwd)"

ln -s "$CUR_DIR/.tmux.conf"  ~/.tmux.conf
ln -s "$CUR_DIR/.vimrc" ~/.vimrc
BASH_SETUP_FILE=". $CUR_DIR/bash_setup"

if ! grep -Fxq "$BASH_SETUP_FILE" ~/.bash_profile; then
    echo "$BASH_SETUP_FILE" >> ~/.bash_profile
fi
