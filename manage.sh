#!/usr/bin/env bash

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

PRIVATE=false
UNAME="$(uname -s)"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TMPL_NAME=ian
TMPL_EMAIL=$(echo bWVAaWFueS5tZQ== | base64 -d)
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
    openssl rand -hex "$size" >"var/$key.hash"
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
    echo "==> pull $origin"
    git -C "$target" remote set-url origin "$origin"
    git -C "$target" pull
  else
    echo "==> clone clone $origin"
    git clone --depth 1 "$origin" "$target"
  fi
}

function head_cat() {
  echo "$* {{""{1"
  cat "$2"
}

function head_safe_cat() {
  echo "$* {{""{1"
  echo  "() {"
  cat "$2"
  echo "}"
}

function find_relative() {
  find "$@" -type f | sed -e "s|^${1%/}/||"
}

function find_relative_d() {
  find "$@" -mindepth 1 -type d | sed -e "s|^${1%/}/||"
}

function cmd_repos() {
  mkdir -p repos

  if [ "$PRIVATE" = "true" ]; then
    ensure_git_clone git@github.com:doitian/dotfiles-public.git repos/public
    ensure_git_clone git@github.com:doitian/dotfiles-private.git repos/private
  else
    ensure_git_clone https://github.com/doitian/dotfiles-public.git repos/public
  fi
  ensure_git_clone https://github.com/robbyrussell/oh-my-zsh.git repos/oh-my-zsh
  rm -rf "$HOME/.oh-my-zsh"
  ln -snf "$DOTFILES_DIR/repos/oh-my-zsh" "$HOME/.oh-my-zsh"
  if [ "$UID" != 0 ]; then
    if [ -d "$HOME/.asdf" ]; then
      echo "==> asdf update"
      source "$HOME/.asdf/asdf.sh"
      asdf update
    else
      ensure_git_clone https://github.com/asdf-vm/asdf.git repos/asdf
      rm -rf "$HOME/.asdf"
      ln -snf "$DOTFILES_DIR/repos/asdf" "$HOME/.asdf"
    fi
  fi
  echo "==> curl bd.zsh"
  curl -sSLo repos/bd.zsh https://raw.githubusercontent.com/Tarrasch/zsh-bd/master/bd.zsh
  echo "==> curl plug.vim"
  curl -sSLo repos/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  echo "==> curl unicodes.txt"
  curl -sSLo repos/unicodes.txt https://gist.github.com/doitian/f80a5f885946e10f3b42cc1e0392192b/raw/6d8227a4d7161ac7de77fbe290659a3d2e5cb1a3/unicodes.txt
}

function cmd_install() {
  echo "#==> completion securities check"
  echo "source ~/.oh-my-zsh/lib/compfix.zsh"
  echo "handle_completion_insecurities"
  echo "#==> asdf direnv setup"
  echo "asdf direnv setup --shell zsh --version system"

  if ! [ -d ~/.dotfiles ]; then
    ln -snf "$DOTFILES_DIR" ~/.dotfiles
  fi
  rm -rf "$HOME/.oh-my-zsh"
  ln -snf "$DOTFILES_DIR/repos/oh-my-zsh" "$HOME/.oh-my-zsh"

  mkdir -p ~/.zcompcache/completions
  mkdir -p ~/.vim/files/backup
  mkdir -p ~/.vim/files/undo
  mkdir -p ~/.vim/files/swap
  mkdir -p ~/.vim/autoload
  mkdir -p ~/bin
  mkdir -p ~/.zsh-completions
  if [ "$UNAME" = "Darwin" ]; then
    mkdir -p ~/Library/KeyBindings
  fi

  ln -snf "$DOTFILES_DIR/repos/plug.vim" ~/.vim/autoload/plug.vim
  ln -snf "$DOTFILES_DIR/repos/public/default/.zshenv" ~/.bash_profile

  GITCONFIG_PATH="$HOME/.gitconfig"
  if [ -n "${GITHUB_CODESPACE_TOKEN:-}" ]; then
    GITCONFIG_PATH="$HOME/.gitconfig.user"
    git config --global include.path .gitconfig.user
  fi
  cat repos/public/gitconfig.tmpl | tmpl_apply >"$GITCONFIG_PATH"
  if [ "$UNAME" = "Darwin" ]; then
    git config --global credential.helper osxkeychain
  fi
  git config --global core.hooksPath "$HOME/.githooks"
  if command -v delta &>/dev/null; then
    git config --global pager.diff delta
    git config --global pager.show delta
    git config --global pager.log delta
    git config --global pager.reflog delta
    git config --global interactive.diffFilter 'delta --color-only --features="${TERM_BACKGROUND:-light}-background interactive"'
  fi
  chmod 0640 "$GITCONFIG_PATH"

  mkdir -p ~/.aria2/
  cat repos/public/aria2rpc.conf.tmpl | tmpl_apply | get_or_set_hash aria2rpc 8 >~/.aria2/aria2rpc.conf
  chmod 0640 ~/.aria2/aria2rpc.conf

  rm -f ~/.safebin
  echo __HASH__ | get_or_set_hash safebin 4 >~/.safebin
  chmod 0400 ~/.safebin

  rm -f ~/.zshrc
  (
    cat repos/public/zshrc
    local l
    for l in completion directories functions git grep history key-bindings misc spectrum termsupport theme-and-appearance clipboard; do
      head_cat '#' ~/.oh-my-zsh/lib/$l.zsh
    done
    for l in gpg-agent sudo copybuffer copypath isodate magic-enter encode64 urltools direnv fzf; do
      head_safe_cat '#' ~/.oh-my-zsh/plugins/$l/$l.plugin.zsh
    done
    head_cat '#' ~/.oh-my-zsh/plugins/gitfast/git-prompt.sh
    for l in $(find repos/public/zsh -name '*.zsh'); do
      head_cat '#' "$l"
    done
    head_cat '#' repos/bd.zsh
    head_cat '#' repos/public/zshrc.after
    if [[ "$(uname -v)" = iSH* ]]; then
      echo 'source ~/.zshenv'
    fi
    if [ "$UNAME" = "Darwin" ]; then
      echo 'source ~/.oh-my-zsh/plugins/macos/macos.plugin.zsh'
    fi
  ) >~/.zshrc
  chmod 0440 ~/.zshrc

  rm -f ~/.bashrc
  (
    cat repos/public/bashrc
    head_cat '#' repos/public/zsh/aliases.zsh
    head_cat '#' repos/public/zsh/functions.zsh
  ) >~/.bashrc
  chmod 0440 ~/.bashrc

  find_relative_d repos/public/default | xargs -I % mkdir -p "$HOME/%"
  find_relative repos/public/default | xargs -I % ln -snf "$DOTFILES_DIR/repos/public/default/%" "$HOME/%"
  private find_relative_d repos/private/default | xargs -I % mkdir -p "$HOME/%"
  private find_relative repos/private/default | xargs -I % ln -snf "$DOTFILES_DIR/repos/private/default/%" "$HOME/%"

  private ln -snf "$DOTFILES_DIR/repos/private/UltiSnips" ~/.vim/UltiSnips
  private ln -snf "$DOTFILES_DIR/repos/private/mutt" ~/.mutt
  private mkdir -p ~/.mutt/cred/
  private find_relative ~/.mutt/accounts | xargs -I % touch ~/.mutt/cred/%
  if [ "$UNAME" = "Darwin" ]; then
    rsync -a -h repos/public/MacOS_cp/ ~/
    mkdir -p ~/.MacOSX
    cat repos/public/environment.plist.tmpl | tmpl_apply >~/.MacOSX/environment.plist
  fi

  if [ -f "$HOME/Library/Spelling/LocalDictionary" ]; then
    ln -snf "$HOME/Library/Spelling/LocalDictionary" "$HOME/.vim-spell-en.utf-8.add"
  fi

  if [ -n "${WSLENV:-}" ]; then
    ln -snf "$(which ssh.exe)" "$HOME/bin/ssh"
    ln -snf "$(which scp.exe)" "$HOME/bin/scp"
    ln -snf "$(which gpg.exe)" "$HOME/bin/gpg"
    ln -snf "$(which gopass.exe)" "$HOME/bin/gopass"
    git config --global core.sshCommand "$(which ssh.exe)"
  fi

  mkdir -p ~/.gnupg
  cp "$DOTFILES_DIR/repos/public/gpg-agent.conf" ~/.gnupg/gpg-agent.conf
  if [ -f /usr/local/bin/pinentry-mac ]; then
    echo 'pinentry-program /usr/local/bin/pinentry-mac' >>~/.gnupg/gpg-agent.conf
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
  rm -f ~/.bash_profile
  rm -f ~/.vim/autoload/plug.vim
  rm -f ~/.mutt
  rm -f ~/.vim/UltiSnips

  rm -rf ~/Library/KeyBindings/

  if [ -n "${WSLENV:-}" ]; then
    rm -f "$HOME/bin/ssh"
    rm -f "$HOME/bin/scp"
    rm -f "$HOME/bin/gpg"
    rm -f "$HOME/bin/gopass"
  fi
}

function main() {
  local command="${1:-}"
  shift
  if [ "${1:-}" = "--private" -o "${1:-}" = "-p" ]; then
    PRIVATE=true
  fi

  case "$command" in
    repos | r)
      cmd_repos
      ;;
    install | i)
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
