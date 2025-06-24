#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m' 
NC='\033[0m'

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

if ! grep -Fxq "$BASH_SETUP_FILE" ~/.bashrc; then
    echo "$BASH_SETUP_FILE" >> ~/.bashrc
fi

GIT_CONFIG_FILE=`convert_path "$CUR_DIR/git.config"`

if ! grep -Exq "\s*path ?= ?$GIT_CONFIG_FILE" ~/.gitconfig; then
    git config --global --add include.path "$GIT_CONFIG_FILE"
fi

if which zsh; then
    if [ ! -d ~/.oh-my-zsh ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    if [ ! -d ~/.oh-my-zsh/custom/themes/powerlevel10k/ ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    fi

    ZSHRC_FILE="$CUR_DIR/.zshrc"
    if [[ `readlink ~/.zshrc` != "$ZSHRC_FILE" ]]; then
        mv ~/.zshrc ~/.zshrc.setup.bak || true
        ln -s "$ZSHRC_FILE" ~/.zshrc
    fi

    P10K_FILE="$CUR_DIR/.p10k.zsh"
    if [[ `readlink ~/.p10k` != "$P10K_FILE" ]]; then
        mv ~/.p10k.zsh ~/.p10k.zsh.bak || true
        ln -s "$P10K_FILE" ~/.p10k.zsh
    fi

    echo -e "${BLUE}Machine specific zsh configuration goes in ~/.zsh-custom${NC}"
fi

echo -e "${GREEN}Setup complete!${NC}"
