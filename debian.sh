#!/usr/bin/env bash

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

if [ "$UID" = 0 ]; then
  apt-get update -y
  apt-get install -y git zsh dirmngr

  if ! id ian; then
    useradd -s /usr/bin/zsh -m ian
  fi
  if ! [ -f /etc/sudoers.d/99-ian ]; then
    (
    echo 'Defaults:ian !requiretty'
    echo 'ian ALL=(ALL:ALL) NOPASSWD: ALL'
    ) | sudo EDITOR='tee -a' visudo -f /etc/sudoers.d/99-ian
  fi

  pushd /home/ian
  if ! [ -d .ssh ]; then
    sudo -H -u ian mkdir -p .ssh
    sudo -H -u ian cat > .ssh/authorized_keys <<"SSH"
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTg9oTy+aDkvfv+rfbIR775U1XxFSk+Ro3l5+in9gBHTSZQ+sjSzpaaSbjw9pZvxqPF43ZXs2+WbdOlWYv+LuaDzZhAlfs/R91ffTCvN4tsCo0lvOke8MEU4LTqSS0Ng9mtDPhGJuv4U6gzwxoHBaAle+Ay30Eg4yA6ovpwOWWvZlJCYiK9JMdz58lbH6+2zRe3XxXwoK+86PluZtgXIjmBykrGLZxQZFR7ylKDURrUmuAekd/1T0QrQxfo2VH4LVKRKPUY+VRNEmfpFtTWPa2Jhjrnln3UNc9Bv1bWjh1GhMX3548l5CekwOfmpTxiuyBNgz8UCprXu5PooA1fanv ian@ian-rmbp
SSH
    ssh-keyscan -H github.com | sudo -H -u ian tee ~/.ssh/known_hosts
  fi
  if ! [ -d .dotfiles ]; then
    git clone --depth 1 git@github.com:doitian/dotfiles.git .dotfiles
    chown -R ian:ian .dotfiles
  fi
  popd # /home/ian
  exit 0
fi

mkdir -p ~/bin repos

CUSTOM_PKGS="libssl1.0-dev"
IS_UBUNTU=
if uname -a | grep -q Ubuntu; then
  IS_UBUNTU=true
  CUSTOM_PKGS="libssl-dev"
fi

INSTALL_APT=
while [ "$#" != 0 ]; do
  case "$1" in
    --apt)
      INSTALL_APT=true
      shift
      ;;
    *)
      echo 'debian.sh [--apt]' >&2
      exit 1
      ;;
  esac
done

if [ -n "$INSTALL_APT" ]; then
  sudo apt-get update -y
  sudo apt-get install -y unzip vim tmux build-essential autoconf flex bison texinfo libtool libreadline-dev zlib1g-dev $CUSTOM_PKGS
  sudo update-alternatives --install /usr/bin/editor editor /usr/bin/vim 100
fi

pushd repos

if ! command -v rg &> /dev/null; then
  RIPGREP_VERSION=11.0.1
  curl -LO https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep_${RIPGREP_VERSION}_amd64.deb
  sudo dpkg -i ripgrep_${RIPGREP_VERSION}_amd64.deb
  rm -f ripgrep_${RIPGREP_VERSION}_amd64.deb
fi

if ! command -v fasd &> /dev/null; then
  git clone --depth 1 https://github.com/clvv/fasd.git
  pushd fasd
  sudo make install
  popd # fasd
  rm -rf fasd
fi

if ! command -v fzf &> /dev/null; then
  sudo git clone --depth 1 https://github.com/junegunn/fzf.git /usr/local/opt/fzf
  sudo /usr/local/opt/fzf/install --bin
  sudo ln -snf /usr/local/opt/fzf/bin/fzf /usr/local/bin
  sudo ln -snf /usr/local/opt/fzf/bin/fzf-tmux /usr/local/bin
fi
/usr/local/opt/fzf/install --no-update-rc --completion --key-bindings

if ! [ -f "$HOME/.dotfiles/repos/watchexec-1.8.6-x86_64-unknown-linux-gnu/watchexec" ]; then
  curl -LO https://github.com/mattgreen/watchexec/releases/download/1.8.6/watchexec-1.8.6-x86_64-unknown-linux-gnu.tar.gz
  tar -xzf watchexec-1.8.6-x86_64-unknown-linux-gnu.tar.gz
  ln -snf "$HOME/.dotfiles/repos/watchexec-1.8.6-x86_64-unknown-linux-gnu/watchexec" ~/bin/watchexec
  rm -f watchexec-1.8.6-x86_64-unknown-linux-gnu.tar.gz
fi

popd # repos
