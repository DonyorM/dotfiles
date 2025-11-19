#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

is_windows() {
    [ "$OSTYPE" = "msys" ]
}

convert_path() {
    if is_windows; then
        echo "${1/\/c\//C:\/}"
    else
        echo "$1"
    fi
}

get_config_home() {
    local config_home=""

    if is_windows; then
        if [ -n "$APPDATA" ]; then
            config_home="$APPDATA"
        elif command_exists powershell.exe; then
            config_home="$(powershell.exe -NoProfile -Command "[Environment]::GetFolderPath('ApplicationData')" 2>/dev/null | tr -d '\r')"
        else
            config_home="$HOME/AppData/Roaming"
        fi

        if command_exists cygpath; then
            config_home="$(cygpath -u "$config_home")"
        else
            local normalized
            normalized="$(printf '%s' "$config_home" | sed 's#\\#/#g')"
            if [[ "$normalized" =~ ^([A-Za-z]):(.*)$ ]]; then
                local drive="${BASH_REMATCH[1]}"
                drive="$(printf '%s' "$drive" | tr '[:upper:]' '[:lower:]')"
                local rest="${BASH_REMATCH[2]}"
                normalized="/${drive}${rest}"
            fi
            config_home="$normalized"
        fi
    else
        if [ -n "$XDG_CONFIG_HOME" ]; then
            config_home="$XDG_CONFIG_HOME"
        else
            config_home="$HOME/.config"
        fi
    fi

    if [ -z "$config_home" ]; then
        config_home="$HOME/.config"
    fi

    echo "$config_home"
}

show_identity_banner() {
    local message_lines=(
        "Let's configure your Git and jj identity."
        "These defaults are stored globally for future commits."
    )

    if command_exists gum; then
        gum style \
            --border rounded \
            --margin "1 0" \
            --padding "1 2" \
            --border-foreground 212 \
            "${message_lines[@]}"
    else
        local border="============================================================"
        echo "$border"
        for line in "${message_lines[@]}"; do
            echo "  $line"
        done
        echo "$border"
    fi
}

prompt_identity_field() {
    local label="$1"
    local placeholder="$2"
    local default_value="$3"
    local value=""

    while [ -z "$value" ]; do
        if command_exists gum; then
            local gum_cmd=(gum input --prompt "$label: ")
            if [ -n "$placeholder" ]; then
                gum_cmd+=(--placeholder "$placeholder")
            fi
            if [ -n "$default_value" ]; then
                gum_cmd+=(--value "$default_value")
            fi
            value="$("${gum_cmd[@]}")"
        else
            if [ -n "$default_value" ]; then
                read -r -p "$label [$default_value]: " value
                value="${value:-$default_value}"
            else
                read -r -p "$label: " value
            fi
        fi

        value="$(printf '%s' "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

        if [ -z "$value" ]; then
            echo -e "${RED}$label cannot be empty. Please try again.${NC}"
        fi
    done

    echo "$value"
}

configure_vcs_identity() {
    local git_available=0
    local jj_available=0
    local git_name=""
    local git_email=""
    local jj_name=""
    local jj_email=""

    if command_exists git; then
        git_available=1
        git_name="$(git config --global user.name 2>/dev/null || true)"
        git_email="$(git config --global user.email 2>/dev/null || true)"
    fi

    if command_exists jj; then
        jj_available=1
        jj_name="$(jj config get user.name 2>/dev/null || true)"
        jj_email="$(jj config get user.email 2>/dev/null || true)"
    fi

    if [ "$git_available" -eq 0 ] && [ "$jj_available" -eq 0 ]; then
        return
    fi

    local needs_name_prompt=0
    local needs_email_prompt=0

    if [ "$git_available" -eq 1 ] && [ -z "$git_name" ]; then
        needs_name_prompt=1
    fi
    if [ "$jj_available" -eq 1 ] && [ -z "$jj_name" ]; then
        needs_name_prompt=1
    fi
    if [ "$git_available" -eq 1 ] && [ -z "$git_email" ]; then
        needs_email_prompt=1
    fi
    if [ "$jj_available" -eq 1 ] && [ -z "$jj_email" ]; then
        needs_email_prompt=1
    fi

    local configured_name="$git_name"
    if [ -z "$configured_name" ]; then
        configured_name="$jj_name"
    fi

    local configured_email="$git_email"
    if [ -z "$configured_email" ]; then
        configured_email="$jj_email"
    fi

    if [ "$needs_name_prompt" -eq 1 ] || [ "$needs_email_prompt" -eq 1 ]; then
        show_identity_banner
        if [ "$needs_name_prompt" -eq 1 ]; then
            configured_name="$(prompt_identity_field "Full Name" "Daniel Manila" "$configured_name")"
        fi
        if [ "$needs_email_prompt" -eq 1 ]; then
            configured_email="$(prompt_identity_field "Email Address" "ada@example.com" "$configured_email")"
        fi
    fi

    if [ "$git_available" -eq 1 ]; then
        if [ -z "$git_name" ] && [ -n "$configured_name" ]; then
            git config --global user.name "$configured_name"
            echo -e "${GREEN}Configured git user.name${NC}"
        fi
        if [ -z "$git_email" ] && [ -n "$configured_email" ]; then
            git config --global user.email "$configured_email"
            echo -e "${GREEN}Configured git user.email${NC}"
        fi
    fi

    if [ "$jj_available" -eq 1 ]; then
        if [ -z "$jj_name" ] && [ -n "$configured_name" ]; then
            jj config set --user user.name "$configured_name"
            echo -e "${GREEN}Configured jj user.name${NC}"
        fi
        if [ -z "$jj_email" ] && [ -n "$configured_email" ]; then
            jj config set --user user.email "$configured_email"
            echo -e "${GREEN}Configured jj user.email${NC}"
        fi
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

if command_exists git; then
    if ! grep -Exq "\s*path ?= ?$GIT_CONFIG_FILE" ~/.gitconfig 2>/dev/null; then
        git config --global --add include.path "$GIT_CONFIG_FILE"
    fi
else
    echo -e "${BLUE}git not found. Skipping git config include path setup.${NC}"
fi

if command_exists jj; then
    jj config set --user ui.editor vim

    JJ_CONFIG_SOURCE="$CUR_DIR/jj-config.toml"
    if [ -f "$JJ_CONFIG_SOURCE" ]; then
        JJ_CONF_DIR="$(get_config_home)/jj/conf.d"
        mkdir -p "$JJ_CONF_DIR"
        JJ_TARGET="$JJ_CONF_DIR/$(basename "$JJ_CONFIG_SOURCE")"
        if [ -e "$JJ_TARGET" ] && [ ! -L "$JJ_TARGET" ]; then
            mv "$JJ_TARGET" "$JJ_TARGET.$(date +%s).bak"
        fi
        ln -sfn "$JJ_CONFIG_SOURCE" "$JJ_TARGET"
    fi
else
    echo -e "${BLUE}jj not found. Skipping jj config setup.${NC}"
fi

configure_vcs_identity

if command_exists zsh; then
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
