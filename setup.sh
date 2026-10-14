#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR" || exit 1

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if ! ssh-keygen -F github.com -f "$HOME/.ssh/known_hosts" &>/dev/null; then
  ssh-keyscan -H github.com >>"$HOME/.ssh/known_hosts"
fi

MANAGE_FLAGS=()
if [ -d "$DOTFILES_DIR/repos/private" ]; then
  MANAGE_FLAGS=(-p)
fi
DEBIAN_FLAGS=(--apt)
if command -v brew &>/dev/null; then
  DEBIAN_FLAGS+=(--brew)
fi

./manage.sh r "${MANAGE_FLAGS[@]}"
./manage.sh i "${MANAGE_FLAGS[@]}"
(
  ./debian.sh "${DEBIAN_FLAGS[@]}"
  ./manage.sh r "${MANAGE_FLAGS[@]}"
  ./manage.sh i "${MANAGE_FLAGS[@]}"
) &
disown
