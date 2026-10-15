#!/usr/bin/env bash

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$UID" = 0 ]; then
  pacman -S --needed --noconfirm zsh git sudo openssh

  if ! [ -f /etc/sudoers.d/wheel ]; then
    echo '%wheel ALL=(ALL:ALL) ALL' >/etc/sudoers.d/wheel
    chmod 440 /etc/sudoers.d/wheel
  fi
  source "$DOTFILES_DIR/bootstrap.sh"
  bootstrap_user wheel
  exit 0
fi

mkdir -p ~/bin

SUDO=sudo
if [ -n "${http_proxy:-}" ]; then
  SUDO="sudo --preserve-env=http_proxy,https_proxy"
fi

$SUDO pacman -S --needed --noconfirm zsh neovim tmux mise git git-lfs gnupg openssl \
  jq fzf fd ripgrep bat eza lazygit starship uv bun typos gopass ctags \
  awesome-terminal-fonts ttf-meslo-nerd
