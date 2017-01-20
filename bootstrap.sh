#!/usr/bin/env bash

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

  if ! launchctl list com.apple.atrun &> /dev/null; then
    echo 'Enable com.apple.atrun...'
    launchctl load -w /System/Library/LaunchDaemons/com.apple.atrun.plist
  fi

  if grep -e '^user: ' config/minion &> /dev/null; then
    sed -i '' -e "s/^user: .*/user: '$USER'/" config/minion
  else
    echo "user = '$USER'"  >> config/minion
  fi
fi

salt-call state.apply bootstrap
