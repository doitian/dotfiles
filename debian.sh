#!/usr/bin/env bash

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

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
    git clone --depth 1 git@github.com:doitian/dotfiles.git .dotfiles
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

CUSTOM_PKGS="libssl1.0-dev"
IS_UBUNTU=
if uname -a | grep -q Ubuntu; then
  IS_UBUNTU=true
  CUSTOM_PKGS="libssl-dev"
fi

INSTALL_APT=
while [ "$#" != 0 ]; do
  case "$1" in
    --apt)
      INSTALL_APT=true
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
  $SUDO apt-get install -y unzip vim tmux build-essential autoconf flex bison texinfo libtool libreadline-dev zlib1g-dev fd fasd ripgrep fzf $CUSTOM_PKGS
  $SUDO update-alternatives --install /usr/bin/editor editor /usr/bin/vim 100
fi

pushd repos

WATCHEXEC_VERSION=1.19.0
if ! [ -f "$HOME/.dotfiles/repos/watchexec-$WATCHEXEC_VERSION-x86_64-unknown-linux-gnu/watchexec" ]; then
  curl -LO https://github.com/watchexec/watchexec/releases/download/cli-v$WATCHEXEC_VERSION/watchexec-$WATCHEXEC_VERSION-x86_64-unknown-linux-gnu.tar.xz
  tar -xJf watchexec-$WATCHEXEC_VERSION-x86_64-unknown-linux-gnu.tar.xz
  ln -snf "$HOME/.dotfiles/repos/watchexec-$WATCHEXEC_VERSION-x86_64-unknown-linux-gnu/watchexec" ~/bin/watchexec
  rm -f watchexec-$WATCHEXEC_VERSION-x86_64-unknown-linux-gnu.tar.gz
fi

popd # repos
