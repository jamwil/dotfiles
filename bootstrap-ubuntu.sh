#!/bin/bash

read -p "Proceed with updating package list and installing dependencies? (y/n): " choice
if [[ $choice == 'y' ]]; then
    sudo apt-get update
    sudo apt-get install -y curl git build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev wget libffi-dev
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

read -p "Proceed with installing lsd? (y/n): " choice
if [[ $choice == 'y' ]]; then
    sudo apt-get install -y lsd
fi

read -p "Proceed with installing pyenv? (y/n): " choice
if [[ $choice == 'y' ]]; then
    curl https://pyenv.run | bash
fi

read -p "Proceed with installing direnv (y/n): " choice
if [[ $choice == 'y' ]]; then
    sudo apt-get install -y direnv
fi

read -p "Proceed with cloning powerlevel10k into ~/powerlevel10k? (y/n): " choice
if [[ $choice == 'y' ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
fi

read -p "Proceed with installing zsh? (y/n): " choice
if [[ $choice == 'y' ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    sudo apt-get install -y zsh
fi

echo "Installation complete. Launch zsh to test or change the default shell with chsh."
