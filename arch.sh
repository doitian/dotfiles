#!/usr/bin/env bash

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$UID" = 0 ]; then
  pacman -S --noconfirm zsh

  if ! id ian; then
    useradd -s /usr/bin/zsh -m ian
  fi

  pushd /home/ian
  if ! [ -d .ssh ]; then
    sudo -H -u ian mkdir -p .ssh
    sudo -H -u ian tee .ssh/authorized_keys <<"SSH"
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO+Gm8XO6FLDbmYjaFfHoFMtAe/YvkTycV/Sj/uXH6sp ian
SSH
    ssh-keyscan -H github.com | sudo -H -u ian tee .ssh/known_hosts
    sudo chmod o-rw,g-w .ssh/authorized_keys .ssh/known_hosts
  fi
  if ! [ -d .dotfiles ]; then
    git clone --filter=blob:none git@github.com:doitian/dotfiles.git .dotfiles
    chown -R ian:ian .dotfiles
  fi
  popd # /home/ian
  exit 0
fi

mkdir -p ~/bin repos

SUDO=sudo
if [ -n "${http_proxy:-}" ]; then
  SUDO="sudo --preserve-env=http_proxy,https_proxy"
fi

$SUDO pacman -S --noconfirm zsh neovim-git tmux mise
