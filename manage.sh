#!/usr/bin/env bash

PRIVATE=false
UNAME="$(uname -s)"
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

TMPL_NAME=ian
TMPL_EMAIL=$(echo bWVAaWFueS5tZQ== | base64 --decode)
TMPL_HOME="$HOME"

function tmpl_apply() {
  sed -e "s|__NAME__|$TMPL_NAME|g" \
    -e "s|__EMAIL__|$TMPL_EMAIL|g" \
    -e "s|__HOME__|$TMPL_HOME|g"
}

function get_or_set_hash() {
  local content="$(cat)"
  local key="$1"
  local size="${2:-16}"
  if ! [ -f "var/$key.hash" ]; then
    openssl rand -hex "$size" > "var/$key.hash"
  fi

  local hash="$(cat "var/$key.hash")"
  echo "$content" | sed -e "s|__HASH__|$hash|g"
}

function private() {
  if [ "$PRIVATE" = "true" ]; then
    "$@"
  fi
}

function ensure_git_clone() {
  local origin="$1"
  local target="$2"
  if [ -d "$target" ]; then
    git -C "$target" remote set-url origin "$origin"
    git -C "$target" pull
  else
    git clone --depth 1 "$origin" "$target"
  fi
}

function head_cat() {
  echo "$* {{""{1"
  cat "$2"
}

function find_relative() {
  find "$@" -type f | sed -e "s|^${1%/}/||"
}

function find_relative_d() {
  find "$@" -type d -mindepth 1 | sed -e "s|^${1%/}/||"
}

function cmd_repos() {
  mkdir -p repos
  if [ "$PRIVATE" = "true" ]; then
    ensure_git_clone git@github.com:doitian/dotfiles-public.git repos/public
    ensure_git_clone git@github.com:doitian/dotfiles-private.git repos/private
  else
    ensure_git_clone https://github.com/doitian/dotfiles-public.git repos/public
  fi
  ensure_git_clone https://github.com/robbyrussell/oh-my-zsh.git "$HOME/.oh-my-zsh"
  curl -sSLo repos/bd.zsh https://raw.githubusercontent.com/Tarrasch/zsh-bd/master/bd.zsh
  curl -sSLo repos/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

function cmd_install() {
  mkdir -p ~/.zcompcache
  mkdir -p ~/.vim/backup
  mkdir -p ~/.vim/undo
  mkdir -p ~/.vim/autoload
  mkdir -p ~/bin
  mkdir -p ~/.zsh-completions
  if [ "$UNAME" = "Darwin" ]; then
    mkdir -p ~/Library/KeyBindings
  fi

  ln -snf "$DOTFILES_DIR/repos/plug.vim" ~/.vim/autoload/plug.vim
  ln -snf "$DOTFILES_DIR/repos/public/default/.zshenv" ~/.bash_profile
  if [ "$UNAME" = "Darwin" ]; then
    ln -snf "$DOTFILES_DIR/repos/public/tmux.conf" ~/.tmux.conf
  else
    ln -snf "$DOTFILES_DIR/repos/public/tmux.linux.conf" ~/.tmux.conf
  fi

  cat repos/public/gitconfig.tmpl | tmpl_apply > ~/.gitconfig
  if [ "$UNAME" = "Darwin" ]; then
    cat repos/public/gitconfig.macos >> ~/.gitconfig
  else
    cat repos/public/gitconfig.common >> ~/.gitconfig
  fi
  if command -v diff-so-fancy &> /dev/null; then
    git config --global pager.diff "diff-so-fancy | less --tabs=1,5 -RFX"
    git config --global pager.show "diff-so-fancy | less --tabs=1,5 -RFX"
  fi
  chmod 0640 ~/.gitconfig

  mkdir -p ~/.aria2/
  cat repos/public/aria2rpc.conf.tmpl | tmpl_apply | get_or_set_hash aria2rpc 8 > ~/.aria2/aria2rpc.conf
  chmod 0640 ~/.aria2/aria2rpc.conf

  rm -f ~/.safebin
  echo __HASH__ | get_or_set_hash safebin 4 > ~/.safebin
  chmod 0400 ~/.safebin

  rm -f ~/.zshrc
  (
    cat repos/public/zshrc
    local l
    for l in completion directories functions git grep history key-bindings misc spectrum termsupport theme-and-appearance; do
      head_cat '#' ~/.oh-my-zsh/lib/$l.zsh
    done
    for l in safe-paste ssh-agent rake-fast; do
      head_cat '#' ~/.oh-my-zsh/plugins/$l/$l.plugin.zsh
    done
    head_cat '#' ~/.oh-my-zsh/plugins/gitfast/git-prompt.sh
    for l in $(find repos/public/zsh -name '*.zsh'); do
      head_cat '#' "$l"
    done
    head_cat '#' repos/bd.zsh
    head_cat '#' repos/public/zshrc.after
  ) > ~/.zshrc
  chmod 0440 ~/.zshrc

  rm -f ~/.bashrc
  (
    cat repos/public/bashrc
    head_cat '#' repos/public/zsh/aliases.zsh
    head_cat '#' repos/public/zsh/functions.zsh
  ) > ~/.bashrc
  chmod 0440 ~/.bashrc

  find_relative_d repos/public/default | xargs -I % mkdir -p "$HOME/%"
  find_relative repos/public/default | xargs -I % ln -snf "$DOTFILES_DIR/repos/public/default/%" "$HOME/%"
  private find_relative_d repos/private/default | xargs -I % mkdir -p "$HOME/%"
  private find_relative repos/private/default | xargs -I % ln -snf "$DOTFILES_DIR/repos/private/default/%" "$HOME/%"
  if [ "$UNAME" = "Darwin" ]; then
    rsync -av --progress -h repos/public/MacOS_cp/ ~/
    mkdir -p ~/.MacOSX
    cat repos/public/environment.plist.tmpl | tmpl_apply > ~/.MacOSX/environment.plist
  fi

  ln -snf "$DOTFILES_DIR/repos/public/gittmpl" "$HOME/.gittmpl"
  ln -snf "$DOTFILES_DIR/repos/public/vimscripts" "$HOME/.vim/scripts"

  if [ -f "$HOME/Library/Spelling/LocalDictionary" ]; then
    ln -snf "$HOME/Library/Spelling/LocalDictionary" "$HOME/.vim-spell-en.utf-8.add"
    if [ -d "$HOME/Library/Application Support/Code/User" ]; then
      ln -snf "$HOME/Library/Spelling/LocalDictionary" "$HOME/Library/Application Support/Code/User/spellright.dict"
    fi
  fi
}

function cmd_uninstall() {
  rm -f ~/.MacOSX/environment.plist
  rmdir ~/.MacOSX || true

  find_relative repos/public/MacOS_cp | xargs -I % rm -f "$HOME/%"
  private find_relative repos/private/default | xargs -I % rm -f "$HOME/%"
  find_relative repos/public/default | xargs -I % rm -f "$HOME/%"

  rm -f ~/.bashrc
  rm -f ~/.zshrc
  rm -f ~/.safebin
  rm -f ~/.gitignore
  rm -rf ~/.aria2/
  rm -f ~/.gitconfig
  rm -f ~/.tmux.conf
  rm -f ~/.bash_profile
  rm -f ~/.vim/autoload/plug.vim
  rm -f ~/.gittmpl
  rm -f ~/.vim/scripts

  rm -rf ~/Library/KeyBindings/
}

function main() {
  local command="${1:-}"
  shift
  if [ "${1:-}" = "--private" -o "${1:-}" = "-p" ]; then
    PRIVATE=true
  fi

  case "$command" in
    repos)
      cmd_repos
      ;;
    install)
      cmd_install
      ;;
    uninstall)
      cmd_uninstall
      ;;
    *)
      echo "manage.sh repos|install|uninstall [--private]"
      ;;
  esac
}

main "$@"
