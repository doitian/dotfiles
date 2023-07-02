#!/usr/bin/env bash

set -e
set -u
set -x

UNAME="$(uname -s)"
TLPKGS=(
  texliveonfly xelatex adjustbox tcolorbox collectbox ucs environ
  trimspaces titling enumitem rsfs xecjk fvextra svg transparent
  lualatex-math selnolig
)

case "$UNAME" in
  Darwin)
    brew install librsvg
    brew install --cask basictex
    eval "$(/usr/libexec/path_helper)"

    sudo tlmgr update --self
    sudo tlmgr update --all
    for pkg in "${TLPKGS[@]}"; do
      sudo tlmgr install $pkg
    done
    ;;
  Linux)
    if type -f apt &>/dev/null; then
      sudo apt install texlive-xetex
    else
      echo "Unsupported system $UNAME" >&2
      exit 1
    fi
    ;;
  *)
    echo "Unsupported system $UNAME" >&2
    exit 1
    ;;
esac
