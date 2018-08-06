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
  braid
  clang-format
  colordiff
  coreutils
  ctags
  dos2unix
  duti
  editorconfig
  fasd
  fzf
  gist
  git
  git-extras
  git-lfs
  git-open
  gradle
  grep
  htop
  hub
  hugo
  imagemagick
  jq
  lua@5.3
  mas
  mtr
  node
  pidof
  pipenv
  postgresql
  pstree
  python
  python@2
  rbenv
  rbenv-aliases
  rbenv-bundler
  rbenv-default-gems
  reattach-to-user-namespace
  redis
  ripgrep
  rlwrap
  subversion
  tag
  telnet
  tig
  tmux
  tree
  unrar
  watchexec
  yarn
  zsh
  zsh-completions
)

brew install "${brew_packages[@]}"

npm install -g prettier eslint eslint-plugin-react

pip3 install flake8 autopep8

for pkg in \
"836500024: WeChat" \
"451108668: QQ" \
"880001334: Reeder" \
"419330170: Moom" \
"490152466: iBooks Author" \
"1055511498: Day One" \
"618061906: Softmatic ScreenLayers" \
"451691288: Contacts Sync For Google Gmail" \
"461369673: VOX" \
"682658836: GarageBand" \
"594432954: Read CHM" \
"595615424: QQMusic" \
"734418810: SSH Tunnel" \
"424389933: Final Cut Pro" \
"622066258: Softmatic WebLayers" \
"557168941: Tweetbot" \
"937984704: Amphetamine" \
"1314980676: iText" \
; do
  id="${pkg%:*}"
  name="${pkg#*: }"
  if ! [ -e "/Applications/$name.app" ]; then
    mas install "$id"
  fi
done
