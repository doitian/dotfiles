#!/usr/bin/env bash

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$UID" = 0 ]; then
  apt-get update -y
  apt-get install -y git zsh dirmngr direnv

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
    echo 'debian.sh [--apt]' >&2
    exit 1
    ;;
  esac
done

if [ -n "$INSTALL_APT" ]; then
  $SUDO apt-get update -y
  $SUDO apt-get install -y unzip vim direnv tmux build-essential autoconf flex bison texinfo libtool libreadline-dev zlib1g-dev libssl-dev python3 python3-pip bat \
    fonts-noto fonts-lato fonts-jetbrains-mono fonts-noto-cjk
  $SUDO update-alternatives --install /usr/bin/editor editor /usr/bin/vim 100
  if [ -z "$INSTALL_BREW" ]; then
    $SUDO apt-get install -y fd-find zoxide ripgrep fzf
    $SUDO update-alternatives --install /usr/bin/fd fd /usr/bin/fdfind 100
  fi

  if [ -f /usr/bin/batcat ]; then
    ln -snf /usr/bin/batcat "$HOME/bat"
  fi
fi

if [ -n "$INSTALL_BREW" ]; then
  brew install fd zoxide ripgrep fzf watchexec
fi
