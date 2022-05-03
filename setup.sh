#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.ssh"
ssh-keyscan -H github.com | tee "$HOME/.ssh/known_hosts"

if [ -n "${GITPOD_WORKSPACE_ID:-}" ]; then
  mkdir -p /workspace/dotfiles-repos
  ln -snf /workspace/dotfiles-repos "$DOTFILES_DIR/repos"
fi

if type -f brew &> /dev/null; then
  ./debian.sh --apt --brew
else
  ./debian.sh --apt
fi
./manage.sh r
./manage.sh i
