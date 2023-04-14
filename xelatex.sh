#!/usr/bin/env bash

set -e
set -u
set -x

UNAME="$(uname -s)"

case "$UNAME" in
  Darwin)
    brew install --cask basictex
    eval "$(/usr/libexec/path_helper)"
    ;;
  *)
    echo "Unsupported system $UNAME" >&2
    exit 1
    ;;
esac

sudo tlmgr update --self
sudo tlmgr update --all
for pkg in texliveonfly xelatex adjustbox tcolorbox collectbox ucs environ \
  trimspaces titling enumitem rsfs xecjk fvextra; do
  sudo tlmgr install $pkg
done
