#!/usr/bin/env bash

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

mkdir -p ~/bin repos

apk add vim git rsync tmux make perl less findutils ncurses ripgrep fd fzf fzf-vim fzf-zsh-completion

ln -snf /usr/share/fzf/key-bindings.zsh ~/.fzf.zsh

pushd repos

if ! command -v fasd &> /dev/null; then
  git clone --depth 1 https://github.com/clvv/fasd.git
  pushd fasd
  $SUDO make install
  popd # fasd
  rm -rf fasd
fi

WATCHEXEC_VERSION=1.17.0
if ! [ -f "$HOME/.dotfiles/repos/watchexec-$WATCHEXEC_VERSION-x86_64-unknown-linux-gnu/watchexec" ]; then
  curl -LO https://github.com/watchexec/watchexec/releases/download/cli-v$WATCHEXEC_VERSION/watchexec-$WATCHEXEC_VERSION-x86_64-unknown-linux-gnu.tar.xz
  tar -xJf watchexec-$WATCHEXEC_VERSION-x86_64-unknown-linux-gnu.tar.xz
  ln -snf "$HOME/.dotfiles/repos/watchexec-$WATCHEXEC_VERSION-x86_64-unknown-linux-gnu/watchexec" ~/bin/watchexec
  rm -f watchexec-$WATCHEXEC_VERSION-x86_64-unknown-linux-gnu.tar.gz
fi

popd # repos
