#!/bin/bash

read -p "\nProceed with updating package list and installing dependencies? (y/n): " choice
if [[ $choice == 'y' ]]; then
    sudo apt-get update
    sudo apt-get install -y curl git build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev wget libffi-dev
fi

read -p "\nProceed with installing chezmoi? (y/n): " choice
if [[ $choice == 'y' ]]; then
    sh -c "$(curl -fsLS get.chezmoi.io/)" -- init --apply https://github.com/jamwil/dotfiles.git
fi

read -p "\nProceed with installing Rust and Cargo? (y/n): " choice
if [[ $choice == 'y' ]]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi

read -p "\nProceed with installing Atuin? (y/n): " choice
if [[ $choice == 'y' ]]; then
    cargo install atuin
fi

read -p "\nProceed with installing lsd? (y/n): " choice
if [[ $choice == 'y' ]]; then
    cargo install lsd
fi

read -p "\nProceed with installing pyenv? (y/n): " choice
if [[ $choice == 'y' ]]; then
    curl https://pyenv.run | bash
fi

read -p "\nProceed with installing direnv (y/n): " choice
if [[ $choice == 'y' ]]; then
    sudo apt-get install -y direnv
fi

read -p "\nProceed with installing cloc (y/n): " choice
if [[ $choice == 'y' ]]; then
    sudo apt-get install -y cloc
fi

read -p "\nProceed with cloning powerlevel10k into ~/powerlevel10k? (y/n): " choice
if [[ $choice == 'y' ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
fi

read -p "\nProceed with installing zsh and making it the default shell? (y/n): " choice
if [[ $choice == 'y' ]]; then
    sudo apt-get install -y zsh
fi

echo "\nInstallation complete. Launch zsh to test or change the default shell with chsh."
