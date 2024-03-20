#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

mkdir -p "$HOME/.ssh"
ssh-keyscan -H github.com | tee "$HOME/.ssh/known_hosts"

if [ -n "${GITPOD_WORKSPACE_ID:-}" ]; then
  mkdir -p /workspace/dotfiles-repos
  ln -snf /workspace/dotfiles-repos "$DOTFILES_DIR/repos"
  if [ -d /home/gitpod/.config/direnv ]; then
    sudo chown -R gitpod: /home/gitpod/.config/direnv
  fi
fi

if command -v brew &>/dev/null; then
  if [ -d "$DOTFILES_DIR/repos/private" ]; then
    ./manage.sh r -p
    ./manage.sh i -p
    (
      ./debian.sh --apt --brew
      ./manage.sh r -p
      ./manage.sh i -p
    ) &
    disown
  else
    ./manage.sh r
    ./manage.sh i
    (
      ./debian.sh --apt --brew
      ./manage.sh r
      ./manage.sh i
    ) &
    disown
  fi
else
  if [ -d "$DOTFILES_DIR/repos/private" ]; then
    ./manage.sh r -p
    ./manage.sh i -p
    (
      ./debian.sh --apt
      ./manage.sh r -p
      ./manage.sh i -p
    ) &
    disown
  else
    ./manage.sh r
    ./manage.sh i
    (
      ./debian.sh --apt
      ./manage.sh r
      ./manage.sh i
    ) &
    disown
  fi
fi
