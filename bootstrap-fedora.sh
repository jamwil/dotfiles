#!/bin/bash

read -p "Proceed with updating package list and installing dependencies? (y/n): " choice
if [[ $choice == 'y' ]]; then
    sudo dnf update -y
    sudo dnf install -y @development-tools curl git util-linux-user openssl-devel \
        zlib-devel bzip2-devel readline-devel sqlite-devel wget libffi-devel \
        lsd fzf ripgrep
fi

read -p "Proceed with installing chezmoi? (y/n): " choice
if [[ $choice == 'y' ]]; then
    sh -c "$(curl -fsLS get.chezmoi.io/)" -- init --apply https://github.com/jamwil/dotfiles.git
fi

read -p "Proceed with installing Rust and Cargo? (y/n): " choice
if [[ $choice == 'y' ]]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi

read -p "Proceed with installing Atuin? (y/n): " choice
if [[ $choice == 'y' ]]; then
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi


read -p "Proceed with installing direnv (y/n): " choice
if [[ $choice == 'y' ]]; then
    sudo dnf install -y direnv
fi

read -p "Proceed with installing uv (y/n): " choice
if [[ $choice == 'y' ]]; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

read -p "Proceed with cloning powerlevel10k into ~/powerlevel10k? (y/n): " choice
if [[ $choice == 'y' ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
fi

read -p "Proceed with installing zsh? (y/n): " choice
if [[ $choice == 'y' ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    sudo dnf install -y zsh
fi

echo "Installation complete. Launch zsh to test or change the default shell with chsh."
