#!/usr/bin/env bash

bin/setup

UNAME="$(uname)"

if [ "$UNAME" = "Darwin" ]; then
  if ! type brew; then
    echo 'Installing homebrew...'
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  if ! type salt-call; then
    echo 'Installing saltstack...'
    brew install saltstack
  fi
fi

salt-call state.apply bootstrap
