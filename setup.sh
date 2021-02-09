#!/bin/bash

# for GitHub Codespaces <https://docs.github.com/en/github/developing-online-with-codespaces/personalizing-codespaces-for-your-account>

ssh-keyscan -H github.com | sudo -H -u ian tee .ssh/known_hosts
ln -snf "$HOME/dotfiles" "$HOME/.dotfiles"

./debian.sh
./manage.sh r -p
./manage.sh i -p
