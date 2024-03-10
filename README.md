# dotfiles

I'm clearly a minimalist ⚫️🗃. These are managed using the amazing
[chezmoi](https://www.chezmoi.io).

## Essential software

The following is required for these dotfiles to work properly (including
aliases):

- atuin
- chezmoi
- cloc
- direnv
- git
- homebrew (on mac)
- lsd
- powerlevel10k
- pyenv
- sqlite3
- vim

### Ubuntu setup script

Run this command on a fresh ubuntu install:

```bash
bash <(curl https://raw.githubusercontent.com/jamwil/dotfiles/main/bootstrap-ubuntu.sh)
```

or this command on a fresh fedora install:

```bash
bash <(curl https://raw.githubusercontent.com/jamwil/dotfiles/main/bootstrap-fedora.sh)
```

Test zsh and if everything looks good, change the default shell with
`chsh -s $(which zsh)`. You'll need a nerd font installed on your client
machine: https://github.com/romkatv/powerlevel10k#manual-font-installation

Then, set up Atuin sync and proceed to the non-mandatory apps below.

```bash
atuin login -u <USERNAME>
```

## Other applications

The following is not mandatory for dotfiles but is a helpful checklist when
setting up a new mac:

- 1Password
- AlDente
- Amphetamine
- anki
- dash
- docker (OrbStack on mac)
- exiftool
- gnupg
- hex-fiend
- iTerm2
- just
- lunar
- mas
- mimestream
- netnewswire
- neovim (with nvchad 2.0)
- Parallels Desktop
- Sparrow
- pipx
- signal
- Tailscale
- tealdeer
- tmux
- wget
