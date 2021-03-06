#!/usr/bin/env bash

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

if [ "$UID" = 0 ]; then
  sudo dnf install -y zsh glibc-langpack-en findutils

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

SUDO=sudo
if [ -n "${http_proxy:-}" ]; then
  SUDO="sudo --preserve-env=http_proxy,https_proxy"
fi

mkdir -p ~/bin repos

$SUDO dnf install -y vim-enhanced ripgrep make

pushd repos

if ! command -v fasd &> /dev/null; then
  git clone --depth 1 https://github.com/clvv/fasd.git
  pushd fasd
  $SUDO make install
  popd # fasd
  rm -rf fasd
fi

if ! command -v fzf &> /dev/null; then
  $SUDO git clone --depth 1 https://github.com/junegunn/fzf.git /usr/local/opt/fzf
  $SUDO /usr/local/opt/fzf/install --bin
  $SUDO ln -snf /usr/local/opt/fzf/bin/fzf /usr/local/bin
  $SUDO ln -snf /usr/local/opt/fzf/bin/fzf-tmux /usr/local/bin
fi
/usr/local/opt/fzf/install --no-update-rc --completion --key-bindings

WATCHEXEC_VERSION=1.16.1
if ! [ -f "$HOME/.dotfiles/repos/watchexec-$WATCHEXEC_VERSION-x86_64-unknown-linux-gnu/watchexec" ]; then
  curl -LO https://github.com/watchexec/watchexec/releases/download/cli-v$WATCHEXEC_VERSION/watchexec-$WATCHEXEC_VERSION-x86_64-unknown-linux-gnu.tar.xz
  tar -xJf watchexec-$WATCHEXEC_VERSION-x86_64-unknown-linux-gnu.tar.xz
  ln -snf "$HOME/.dotfiles/repos/watchexec-$WATCHEXEC_VERSION-x86_64-unknown-linux-gnu/watchexec" ~/bin/watchexec
  rm -f watchexec-$WATCHEXEC_VERSION-x86_64-unknown-linux-gnu.tar.gz
fi

popd # repos
