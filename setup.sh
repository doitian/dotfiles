#!/bin/bash

# for GitHub Codespaces <https://docs.github.com/en/github/developing-online-with-codespaces/personalizing-codespaces-for-your-account>

if [ -d "$HOME/dotfiles" ] && ! [ -d "$HOME/.dotfiles" ]; then
  ln -snf "$HOME/dotfiles" "$HOME/.dotfiles"
fi
cd "$HOME/.dotfiles"
mkdir -p "$HOME/.ssh"
ssh-keyscan -H github.com | tee "$HOME/.ssh/known_hosts"

./debian.sh
./manage.sh r
./manage.sh i
