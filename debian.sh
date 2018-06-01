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
  if ! [ -f /etc/sudoers.d/ian ]; then
    (
    echo 'Defaults:ian !requiretty'
    echo 'ian ALL=(ALL:ALL) NOPASSWD: ALL'
    ) | sudo EDITOR='tee -a' visudo -f /etc/sudoers.d/ian
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

mkdir -p ~/bin

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
echo 'deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main' | sudo tee /etc/apt/sources.list.d/ansible.list
sudo apt-get update -y
sudo apt-get install -y vim tmux build-essential autoconf flex bison texinfo libtool libssl1.0-dev libreadline-dev zlib1g-dev \
  redis-server mysql-server default-libmysqlclient-dev nodejs
sudo update-alternatives --install /usr/bin/editor editor /usr/bin/vim 100

ln -snf /usr/bin/python3 ~/bin/python3

pushd repos

if ! command -v rg &> /dev/null; then
  curl -LO https://github.com/BurntSushi/ripgrep/releases/download/0.8.1/ripgrep_0.8.1_amd64.deb
  sudo dpkg -i ripgrep_0.8.1_amd64.deb
  rm -f ripgrep_0.8.1_amd64.deb
fi

if ! command -v fasd &> /dev/null; then
  git clone --depth 1 https://github.com/clvv/fasd.git
  pushd fasd
  sudo make install
  popd # fasd
  rm -rf fasd
fi

popd # repos

if ! command -v fzf &> /dev/null; then
  sudo git clone --depth 1 https://github.com/junegunn/fzf.git /usr/local/opt/fzf
  sudo /usr/local/opt/fzf/install --bin
  sudo ln -snf /usr/local/opt/fzf/bin/fzf /usr/local/bin
  sudo ln -snf /usr/local/opt/fzf/bin/fzf-tmux /usr/local/bin
fi
/usr/local/opt/fzf/install --update-rc --completion --key-bindings

if ! command -v rbenv &> /dev/null; then
  sudo git clone --depth 1 https://github.com/rbenv/rbenv.git /usr/local/opt/rbenv
  pushd /usr/local/opt/rbenv
  sudo src/configure
  sudo make -C src
  sudo ln -snf /usr/local/opt/rbenv/bin/rbenv /usr/local/bin
  popd # /usr/local/opt/rbenv
fi

mkdir -p ~/.rbenv/plugins
if ! [ -d ~/.rbenv/plugins/ruby-build ]; then
  git clone --depth 1 https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi
if ! [ -d ~/.rbenv/versions/2.2.3 ]; then
  curl -fsSL https://gist.github.com/mislav/055441129184a1512bb5.txt |\
    RUBY_CONFIGURE_OPTS=--disable-install-doc rbenv install --patch 2.2.3
fi

if ! command -v rustc &> /dev/null; then
  pushd repos
  curl https://sh.rustup.rs -sSf > rustup-installer.sh
  bash rustup-installer.sh --default-host x86_64-unknown-linux-gnu --default-toolchain nightly-2018-05-23 --no-modify-path -y
  rustup component add rustfmt-preview --toolchain=nightly-2018-05-23
  cargo install clippy --vers 0.0.204 --force
  popd repos
fi

if ! [ -f "$HOME/.dotfiles/repos/watchexec-1.8.6-x86_64-unknown-linux-gnu/watchexec" ]; then
  curl -LO https://github.com/mattgreen/watchexec/releases/download/1.8.6/watchexec-1.8.6-x86_64-unknown-linux-gnu.tar.gz
  tar -xzf watchexec-1.8.6-x86_64-unknown-linux-gnu.tar.gz
  ln -snf "$HOME/.dotfiles/repos/watchexec-1.8.6-x86_64-unknown-linux-gnu/watchexec" ~/bin/watchexec
  rm -f watchexec-1.8.6-x86_64-unknown-linux-gnu.tar.gz
fi

if ! command -v caddy &> /dev/null; then
  curl https://getcaddy.com | bash -s personal
fi

