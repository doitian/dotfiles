#!/usr/bin/env bash

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

if ! type brew; then
  echo 'Installing homebrew...'
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew_packages=(
  bash
  clang-format
  coreutils
  ctags
  duti
  editorconfig
  fasd
  fzf
  gist
  git
  git-lfs
  grep
  hugo
  imagemagick
  jq
  mas
  node
  pidof
  pipenv
  pstree
  python
  rsync
  reattach-to-user-namespace
  ripgrep
  rlwrap
  tag
  tmux
  trash
  tree
  unrar
  watchexec
  yarn
  zsh
  zsh-completions
)

brew install "${brew_packages[@]}"

npm install -g prettier eslint eslint-plugin-react diff-so-fancy tldr

pip3 install -U -r requirements.txt
pip3 install flake8 autopep8

for pkg in \
"836500024: WeChat" \
"490152466: iBooks Author" \
"1055511498: Day One" \
"451691288: Contacts Sync For Google Gmail" \
"682658836: GarageBand" \
"595615424: QQMusic" \
"734418810: SSH Tunnel" \
"424389933: Final Cut Pro" \
"937984704: Amphetamine" \
; do
  id="${pkg%:*}"
  name="${pkg#*: }"
  if ! [ -e "/Applications/$name.app" ]; then
    mas install "$id"
  fi
done
