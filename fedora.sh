#!/usr/bin/env bash

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$UID" = 0 ]; then
  dnf install -y zsh glibc-langpack-en findutils git fzf sudo openssh-clients

  source "$DOTFILES_DIR/bootstrap.sh"
  bootstrap_user wheel
  exit 0
fi

SUDO=sudo
if [ -n "${http_proxy:-}" ]; then
  SUDO="sudo --preserve-env=http_proxy,https_proxy"
fi

mkdir -p ~/bin

$SUDO dnf install -y vim-enhanced ripgrep fd-find make tar openssl
