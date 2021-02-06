#!/usr/bin/env bash

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

brew bundle --file=Brewfile

npm install -g diff-so-fancy

pip3 install -U -r requirements.txt
