#!/bin/bash

# for GitHub Codespaces <https://docs.github.com/en/github/developing-online-with-codespaces/personalizing-codespaces-for-your-account>

if [ -d "$HOME/dotfiles" ] && ! [ -d "$HOME/.dotfiles" ]; then
  ln -snf "$HOME/dotfiles" "$HOME/.dotfiles"
fi
cd "$HOME/.dotfiles"
mkdir -p "$HOME/.ssh"
ssh-keyscan -H github.com | tee "$HOME/.ssh/known_hosts"

if [ -n "${GITPOD_WORKSPACE_ID:-}" ]; then
  mkdir -p /workspace/dotfiles-repos
  ln -snf /workspace/dotfiles-repos repos
fi

if type -f brew &> /dev/null; then
  ./debian.sh --apt --brew
else
  ./debian.sh --apt
fi
./manage.sh r
./manage.sh i
