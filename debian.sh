#!/usr/bin/env bash

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$UID" = 0 ]; then
  apt-get update -y
  apt-get install -y git zsh dirmngr sudo openssh-client

  source "$DOTFILES_DIR/bootstrap.sh"
  bootstrap_user sudo
  exit 0
fi

mkdir -p ~/bin

SUDO=sudo
if [ -n "${http_proxy:-}" ]; then
  SUDO="sudo --preserve-env=http_proxy,https_proxy"
fi

INSTALL_APT=
INSTALL_BREW=
while [ "$#" != 0 ]; do
  case "$1" in
  --apt)
    INSTALL_APT=true
    shift
    ;;
  --brew)
    INSTALL_BREW=true
    shift
    ;;
  *)
    echo 'debian.sh [--apt] [--brew]' >&2
    exit 1
    ;;
  esac
done

if [ -n "$INSTALL_APT" ]; then
  $SUDO apt-get update -y
  $SUDO apt-get install -y unzip vim tmux build-essential autoconf flex bison texinfo libtool libreadline-dev zlib1g-dev libssl-dev \
    python3 python3-pip bat
  $SUDO update-alternatives --install /usr/bin/editor editor /usr/bin/vim 100
  if [ -z "$INSTALL_BREW" ]; then
    $SUDO apt-get install -y fd-find ripgrep fzf
    $SUDO update-alternatives --install /usr/bin/fd fd /usr/bin/fdfind 100
  fi
  if [ -n "${WSLENV:-}" ]; then
    $SUDO apt-get install -y wslu
  fi

  if [ -f /usr/bin/batcat ]; then
    mkdir -p "$HOME/bin"
    ln -snf /usr/bin/batcat "$HOME/bin/bat"
  fi
fi

if [ -n "$INSTALL_BREW" ]; then
  brew install fd ripgrep fzf watchexec mise
fi
