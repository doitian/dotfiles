#!/usr/bin/env bash

set -e
set -u
set -x

TLPKGS=(
  texliveonfly adjustbox tcolorbox collectbox ucs environ
  trimspaces titling enumitem rsfs xecjk fvextra svg transparent
  lualatex-math selnolig changepage ifoddpage
)

case "$OSTYPE" in
darwin*)
  brew install librsvg
  brew install --cask basictex
  eval "$(/usr/libexec/path_helper)"

  sudo tlmgr update --self
  sudo tlmgr update --all
  for pkg in "${TLPKGS[@]}"; do
    sudo tlmgr install $pkg
  done
  ;;
linux*)
  if type -f apt &>/dev/null; then
    sudo apt install texlive-xetex
  else
    echo "Unsupported system $OSTYPE" >&2
    exit 1
  fi
  ;;
*)
  echo "Unsupported system $OSTYPE" >&2
  exit 1
  ;;
esac
