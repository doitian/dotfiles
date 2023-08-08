#!/usr/bin/env bash

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

PRIVATE=false
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

function shell_cat() {
  cat "$@" | grep -v "^\s*#"
}
function head_cat() {
  echo "$* {{""{{1"
  shell_cat "$2"
}

function head_safe_cat() {
  echo "$* {{""{{1"
  echo "() {"
  shell_cat "$2"
  echo "}"
}

function find_relative() {
  find "$@" -type f | sed -e "s|^${1%/}/||"
}

function find_relative_d() {
  find "$@" -mindepth 1 -type d | sed -e "s|^${1%/}/||"
}

function command_ok() {
  command "$@" &>/dev/null
}
function command_stdio_ok() {
  command "$@" &>/dev/null <<<""
}
function command_1arg_ok() {
  command "$@" /dev/null &>/dev/null
}
function command_2args_ok() {
  command "$@" /dev/null /dev/null &>/dev/null
}
function detect_aliases() {
  # Ignore these folders (if the necessary grep flags are available)
  local EXC_FOLDERS="{.bzr,CVS,.git,.hg,.svn,.idea,.tox}"
  local GREP_OPTIONS

  if command_stdio_ok grep "" --color=auto --exclude-dir=.cvs; then
    GREP_OPTIONS="--color=auto --exclude-dir=$EXC_FOLDERS"
  elif command_stdio_ok --color=auto --exclude=.cvs; then
    GREP_OPTIONS="--color=auto --exclude=$EXC_FOLDERS"
  fi

  if [[ -n "$GREP_OPTIONS" ]]; then
    echo "alias grep='grep $GREP_OPTIONS'"
  fi

  if command_2args_ok diff --color; then
    echo "alias diff='diff --color'"
  fi

  if command_1arg_ok ls --color; then
    echo "alias ls='ls --color=tty'"
  elif command_1arg_ok ls -G; then
    echo "alias ls='ls -G'"
  fi
}

function fzf_setup() {
  local fzf_base fzf_shell fzfdirs dir

  test -d "${FZF_BASE:-}" && fzf_base="${FZF_BASE}"

  if [[ -z "${fzf_base}" ]]; then
    fzfdirs=(
      "${HOME}/.fzf"
      "${HOME}/.nix-profile/share/fzf"
      "${XDG_DATA_HOME:-$HOME/.local/share}/fzf"
      "/usr/local/opt/fzf"
      "/opt/homebrew/opt/fzf"
      "/usr/share/fzf"
      "/usr/local/share/examples/fzf"
    )
    for dir in "${fzfdirs[@]}"; do
      if [[ -d "${dir}" ]]; then
        fzf_base="${dir}"
        break
      fi
    done
  fi

  if [[ ! -d "${fzf_base}" ]]; then
    return
  fi

  # Fix fzf shell directory for Arch Linux, NixOS or Void Linux packages
  if [[ ! -d "${fzf_base}/shell" ]]; then
    fzf_shell="${fzf_base}"
  else
    fzf_shell="${fzf_base}/shell"
  fi

  # Auto-completion
  echo "source '${fzf_shell}/completion.$1' 2> /dev/null"
  echo "source '${fzf_shell}/key-bindings.$1' 2> /dev/null"
  if command -v fd &>/dev/null; then
    echo "export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'"
  elif command -v fd &>/dev/null; then
    echo "export FZF_DEFAULT_COMMAND='rg --files --hidden --glob \"!.git/*\"'"
  fi
}

function cmd_repos() {
  mkdir -p repos

  if [ "$PRIVATE" = "true" ]; then
    ensure_git_clone git@github.com:doitian/dotfiles-public.git repos/public
    ensure_git_clone git@github.com:doitian/dotfiles-private.git repos/private
  else
    ensure_git_clone https://github.com/doitian/dotfiles-public.git repos/public
  fi
  if [[ "$OSTYPE" == "linux"* ]]; then
    ensure_git_clone https://github.com/doitian/rime-wubi86-jidian.git repos/rime-wubi86-jidian
  fi
  if [ "$UID" != 0 ]; then
    if [ -d "$HOME/.asdf" ]; then
      echo "==> asdf update"
      source "$HOME/.asdf/asdf.sh"
      asdf update
    elif [ -d repos/asdf ]; then
      echo "==> asdf update"
      ln -snf "$DOTFILES_DIR/repos/asdf" "$HOME/.asdf"
      source "$HOME/.asdf/asdf.sh"
      asdf update
    else
      ensure_git_clone https://github.com/asdf-vm/asdf.git repos/asdf
      rm -rf "$HOME/.asdf"
      ln -snf "$DOTFILES_DIR/repos/asdf" "$HOME/.asdf"
    fi
  fi
  if [[ ! -e repos/unicodes.txt ]]; then
    echo "==> curl unicodes.txt"
    curl -sSLo repos/unicodes.txt https://gist.github.com/doitian/f80a5f885946e10f3b42cc1e0392192b/raw/6d8227a4d7161ac7de77fbe290659a3d2e5cb1a3/unicodes.txt
  else
    echo "==> curl unicodes.txt (skipped)"
  fi
}

function cmd_install() {
  if ! [ -d ~/.dotfiles ]; then
    ln -snf "$DOTFILES_DIR" ~/.dotfiles
  fi

  mkdir -p ~/bin
  if ! [ -e ~/bin/nvim ]; then
    if command -v nvim &>/dev/null; then
      ln -snf "$(which nvim)" ~/bin/nvim
    elif command -v vim &>/dev/null; then
      ln -snf "$(which vim)" ~/bin/nvim
    else
      echo "vim not found"
      exit 1
    fi
  fi

  mkdir -p ~/.local/state/vim/{backup,undo,swap}
  mkdir -p ~/.vim/autoload
  mkdir -p ~/.zcompcache/completions
  if [[ "$OSTYPE" == "darwin"* ]]; then
    mkdir -p ~/Library/KeyBindings
  fi

  ln -snf "$DOTFILES_DIR/repos/public/default/.zshenv" ~/.bash_profile
  rm -rf ~/.pandoc
  ln -snf "$DOTFILES_DIR/repos/public/pandoc" ~/.pandoc
  rm -rf ~/.config/nvim
  mkdir -p ~/.config
  ln -snf "$DOTFILES_DIR/repos/public/nvim" ~/.config/nvim

  local PUBLIC_SNIPPETS_DIR="$DOTFILES_DIR/repos/public/nvim/pack/local/start/snippets/snippets"
  local PRIVATE_SNIPPETS_DIR="$DOTFILES_DIR/repos/private/nvim/snippets"
  if [ "$PRIVATE" = "true" ] && command -v jq &>/dev/null; then
    jq -s 'reduce .[] as $item ({}; . * $item)' "$PRIVATE_SNIPPETS_DIR"/* >"$PUBLIC_SNIPPETS_DIR/private-snippets.code-snippets"
  fi
  local VSCODE_SNIPPETS_DIR
  for VSCODE_SNIPPETS_DIR in "$HOME/Library/Application Support/Code/User/snippets"; do
    if [ -d "$VSCODE_SNIPPETS_DIR" ]; then
      rm -rf "$VSCODE_SNIPPETS_DIR"
      ln -snf "$PUBLIC_SNIPPETS_DIR" "$VSCODE_SNIPPETS_DIR"
    fi
  done

  GITCONFIG_PATH="$HOME/.gitconfig"
  if [ -n "${GITHUB_CODESPACE_TOKEN:-}" ]; then
    GITCONFIG_PATH="$HOME/.gitconfig.user"
    git config --global include.path .gitconfig.user
  fi
  cat repos/public/gitconfig.tmpl | tmpl_apply >"$GITCONFIG_PATH"
  if [[ "$OSTYPE" == "darwin"* ]]; then
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

  if [[ "$OSTYPE" == "darwin"* ]]; then
    ln -snf "$DOTFILES_DIR/repos/public/default/.config/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"
  fi

  rm -f ~/.zshrc
  (
    echo '# vim: fmr={{{{,}}}}:fdm=marker'
    head_cat '#' repos/public/zshrc
    local l
    for l in $(find repos/public/zsh -depth 1 -name '*.zsh' | sort); do
      head_cat '#' "$l"
    done
    echo "# detected aliases {{""{{1"
    detect_aliases
    for l in $(find repos/public/zsh/after -name '*.zsh' | sort); do
      head_cat '#' "$l"
    done
    if command -v zoxide &>/dev/null; then
      echo "# zoxide {{""{{1"
      zoxide init zsh --cmd j | grep -v "^\s*#"
    fi
    if command -v direnv &>/dev/null; then
      echo "# direnv {{""{{1"
      direnv hook zsh | grep -v "^\s*#"
    fi
    if command -v fzf &>/dev/null; then
      echo "# fzf {{""{{1"
      fzf_setup zsh
    fi
    if [[ "$OSTYPE" == "darwin"* ]]; then
      head_cat '#' repos/public/zsh/extras/macos.zsh
    fi
    if command -v okc-ssh-agent &>/dev/null; then
      head_cat '#' repos/public/zsh/extras/okc-ssh-agent.zsh
    fi
    if [[ "$(uname -v)" = iSH* ]]; then
      echo 'source ~/.zshenv'
    fi
  ) >~/.zshrc
  chmod 0440 ~/.zshrc

  rm -f ~/.bashrc
  (
    echo '# vim: fmr={{{{,}}}}:fdm=marker'
    head_cat '#' repos/public/bashrc
    head_cat '#' repos/public/zsh/after/aliases.zsh
    echo "# detected aliases {{""{{1"
    detect_aliases
    head_cat '#' repos/public/zsh/after/functions.zsh
    if [[ "$OSTYPE" == "darwin"* ]]; then
      head_cat '#' repos/public/zsh/extras/macos.zsh
    fi
    if command -v zoxide &>/dev/null; then
      echo "# zoxide {{""{{1"
      zoxide init bash --cmd j | grep -v "^\s*#"
    fi
    if command -v direnv &>/dev/null; then
      echo "# direnv {{""{{1"
      direnv hook bash | grep -v "^\s*#"
    fi
    if command -v fzf &>/dev/null; then
      echo "# fzf {{""{{1"
      fzf_setup bash
    fi
    if command -v starship &>/dev/null; then
      echo "# starship {{""{{1"
      echo 'eval "$(starship init bash)"'
    fi
  ) >~/.bashrc
  chmod 0440 ~/.bashrc

  find_relative_d repos/public/default | xargs -I % mkdir -p "$HOME/%"
  find_relative repos/public/default | xargs -I % ln -snf "$DOTFILES_DIR/repos/public/default/%" "$HOME/%"
  private find_relative_d repos/private/default | xargs -I % mkdir -p "$HOME/%"
  private find_relative repos/private/default | xargs -I % ln -snf "$DOTFILES_DIR/repos/private/default/%" "$HOME/%"

  private ln -snf "$DOTFILES_DIR/repos/private/mutt" ~/.mutt
  private mkdir -p ~/.mutt/cred/
  private find_relative ~/.mutt/accounts | xargs -I % touch ~/.mutt/cred/%

  if [[ "$OSTYPE" == "darwin"* ]]; then
    rsync -a -h repos/public/MacOS_cp/ ~/
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

  if [[ "$OSTYPE" == "linux"* ]]; then
    rm -rf "$HOME/.local/share/fcitx5/rime"
    mkdir -p "$HOME/.local/share/fcitx5"
    ln -snf "$DOTFILES_DIR/repos/rime-wubi86-jidian" "$HOME/.local/share/fcitx5/rime"
  fi
}

function cmd_uninstall() {
  find_relative repos/public/MacOS_cp | xargs -I % rm -f "$HOME/%"
  private find_relative repos/private/default | xargs -I % rm -f "$HOME/%"
  find_relative repos/public/default | xargs -I % rm -f "$HOME/%"

  rm -f ~/bin/vim
  rm -f ~/.bashrc
  rm -f ~/.zshrc
  rm -f ~/.gitignore
  rm -rf ~/.aria2/
  rm -f ~/.gitconfig
  rm -f ~/.bash_profile
  rm -f ~/.mutt
  rm -f ~/.pandoc
  rm -f ~/.config/nvim
  rm -rf ~/Library/KeyBindings/

  priate rm ~/.private-snippets.vim

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
