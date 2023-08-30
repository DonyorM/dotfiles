#!/bin/bash

CUR_DIR="$(cd "$(dirname "$0")"; pwd)"

ln -s "$CUR_DIR/.tmux.conf"  ~/.tmux.conf
ln -s "$CUR_DIR/.vimrc" ~/.vimrc
echo ". $CUR_DIR/bash_setup" >> ~/.bashrc
