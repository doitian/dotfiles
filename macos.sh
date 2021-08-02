#!/usr/bin/env bash

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

# brew bundle dump --force --file=Brewfile
brew bundle --file=Brewfile

pip3 install -U -r requirements.txt
