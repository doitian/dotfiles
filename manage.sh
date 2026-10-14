#!/usr/bin/env bash

set -e
set -u
set -o pipefail
[ -n "${DEBUG:-}" ] && set -x || true

PRIVATE=false
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

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
  local file="var/$key.hash"
  if ! [ -s "$file" ]; then
    if ! command -v openssl &>/dev/null; then
      echo "openssl is required to generate $file" >&2
      return 1
    fi
    (
      umask 077
      openssl rand -hex "$size" >"$file.tmp"
    )
    mv -f "$file.tmp" "$file"
  fi
  chmod 600 "$file"

  local hash
  hash="$(cat "$file")"
  echo "${content//__HASH__/$hash}"
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
    git clone --filter=blob:none "$origin" "$target"
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
  local GREP_OPTIONS=""

  if command_stdio_ok grep "" --color=auto --exclude-dir=.cvs; then
    GREP_OPTIONS="--color=auto --exclude-dir=$EXC_FOLDERS"
  elif command_stdio_ok grep "" --color=auto --exclude=.cvs; then
    GREP_OPTIONS="--color=auto --exclude=$EXC_FOLDERS"
  fi

  if [[ -n "$GREP_OPTIONS" ]]; then
    echo "alias grep='grep $GREP_OPTIONS'"
  fi

  if command_2args_ok diff --color=auto; then
    echo "alias diff='diff --color=auto'"
  fi

  if command_1arg_ok ls --color=auto; then
    echo "alias ls='ls --color=auto'"
  fi

  if command -v eza &>/dev/null; then
    echo "alias l='eza'"
    echo "alias li='eza --icons'"
  elif command -v exa &>/dev/null; then
    echo "alias l='exa'"
    echo "alias li='exa --icons'"
  else
    echo "alias l='ls'"
    echo "alias li='ls'"
  fi
}

function mise_rc() {
  if command -v mise &>/dev/null; then
    echo "# mise {{""{{1"
    echo 'if [[ -f ".mise-auto" || -n "$__MISE_DIFF" ]]; then'
    echo '  eval "$(mise activate)"'
    echo 'fi'
  fi
}

function fzf_setup() {
  local fzf_base fzf_shell fzfdirs dir

  test -d "${FZF_BASE:-}" && fzf_base="${FZF_BASE}"

  if [[ -z "${fzf_base:-}" ]]; then
    fzfdirs=(
      "${HOME}/.fzf"
      "${XDG_DATA_HOME:-$HOME/.local/share}/fzf"
      "/usr/local/opt/fzf"
      "/opt/homebrew/opt/fzf"
      "/home/linuxbrew/.linuxbrew/opt/fzf"
      "/usr/share/fzf"
      "/usr/share/doc/fzf/examples"
      "/usr/local/share/examples/fzf"
      "/data/data/com.termux/files/usr/share/fzf"
    )
    for dir in "${fzfdirs[@]}"; do
      if [[ -d "${dir}" ]]; then
        fzf_base="${dir}"
        break
      fi
    done
  fi

  if [[ ! -d "${fzf_base:-}" ]]; then
    echo "fzf not found" >&2
    return
  fi

  # Fix fzf shell directory for Arch Linux, NixOS or Void Linux packages
  if [[ ! -d "${fzf_base}/shell" ]]; then
    fzf_shell="${fzf_base}"
  else
    fzf_shell="${fzf_base}/shell"
  fi

  echo "source '${fzf_shell}/completion.$1' 2> /dev/null"
  echo "source '${fzf_shell}/key-bindings.$1' 2> /dev/null"
  if command -v fd &>/dev/null; then
    echo "export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'"
  elif command -v rg &>/dev/null; then
    echo "export FZF_DEFAULT_COMMAND='rg --files --hidden --glob \"!.git/*\"'"
  fi
}

function prune_stale_links() {
  local depth dir link
  {
    for dir in "$HOME" "$HOME/.claude" "$HOME/.agents" "$HOME/.gemini" "$HOME/.copilot" "$HOME/.config/opencode" "$HOME/.pi/agent"; do
      echo "1 $dir"
    done
    find_relative_d repos/public/default | sed -e "s|^|1 $HOME/|"
    private find_relative_d repos/private/default | sed -e "s|^|1 $HOME/|"
    echo "3 $HOME/.config"
    echo "3 $HOME/.local/share"
  } | while read -r depth dir; do
    [ -d "$dir" ] || continue
    { find "$dir" -maxdepth "$depth" -type l -lname "$DOTFILES_DIR/repos/*" 2>/dev/null || true; } | while IFS= read -r link; do
      if ! [ -e "$link" ]; then
        echo "remove stale link $link"
        rm -f "$link"
      fi
    done
  done
}

function cmd_repos() {
  mkdir -p repos

  if [ "$PRIVATE" = "true" ]; then
    ensure_git_clone git@github.com:doitian/dotfiles-public.git repos/public
    ensure_git_clone git@github.com:doitian/dotfiles-private.git repos/private
  else
    ensure_git_clone https://github.com/doitian/dotfiles-public.git repos/public
  fi
}

function cmd_install() {
  if ! [ -d ~/.dotfiles ]; then
    ln -snf "$DOTFILES_DIR" ~/.dotfiles
  fi
  prune_stale_links

  # directories
  mkdir -p ~/bin
  mkdir -p ~/.local/state/vim/{backup,undo,swap}
  mkdir -p ~/.zcompcache
  if [[ "$OSTYPE" == "darwin"* ]]; then
    mkdir -p ~/Library/KeyBindings
  fi
  ln -snf "$DOTFILES_DIR/repos/public/default/.zshenv" ~/.bash_profile
  rm -rf ~/.pandoc
  ln -snf "$DOTFILES_DIR/repos/public/pandoc" ~/.pandoc
  mkdir -p ~/.config
  rm -rf ~/.config/nvim
  ln -snf "$DOTFILES_DIR/repos/public/nvim" ~/.config/nvim
  mkdir -p ~/.claude
  rm -rf ~/.claude/skills
  ln -snf "$DOTFILES_DIR/repos/public/ai/skills" ~/.claude/skills
  mkdir -p ~/.agents
  rm -rf ~/.agents/skills
  ln -snf "$DOTFILES_DIR/repos/public/ai/skills" ~/.agents/skills
  ln -snf "$DOTFILES_DIR/repos/public/ai/skill-lock.json" ~/.agents/.skill-lock.json
  mkdir -p ~/.gemini
  ln -snf "$DOTFILES_DIR/repos/public/ai/gemini/settings.json" ~/.gemini/settings.json

  mkdir -p ~/.config/opencode
  mkdir -p ~/.copilot
  mkdir -p ~/.pi/agent
  local AGENTS_MD="$DOTFILES_DIR/repos/public/ai/rules/linux.md"
  ln -snf "$AGENTS_MD" ~/.gemini/AGENTS.md
  ln -snf "$AGENTS_MD" ~/.claude/AGENTS.md
  ln -snf "$AGENTS_MD" ~/.copilot/copilot-instructions.md
  ln -snf "$AGENTS_MD" ~/.config/opencode/AGENTS.md
  ln -snf "$AGENTS_MD" ~/.pi/agent/AGENTS.md

  # default
  find_relative_d repos/public/default | xargs -I % mkdir -p "$HOME/%"
  find_relative repos/public/default | xargs -I % ln -snf "$DOTFILES_DIR/repos/public/default/%" "$HOME/%"
  private find_relative_d repos/private/default | xargs -I % mkdir -p "$HOME/%"
  private find_relative repos/private/default | xargs -I % ln -snf "$DOTFILES_DIR/repos/private/default/%" "$HOME/%"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    rsync -a -h repos/public/MacOS_cp/ ~/
  fi

  # editor
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

  local PUBLIC_SNIPPETS_DIR="$DOTFILES_DIR/repos/public/nvim/snippets"
  local PRIVATE_SNIPPETS_DIR="$DOTFILES_DIR/repos/private/nvim/snippets"
  if [ "$PRIVATE" = "true" ]; then
    local private_snippets=()
    if [ -d "$PRIVATE_SNIPPETS_DIR" ]; then
      private_snippets=("$PRIVATE_SNIPPETS_DIR"/*)
    fi
    if ! [ -e "${private_snippets[0]:-}" ]; then
      rm -f "$PUBLIC_SNIPPETS_DIR/private-snippets.code-snippets"
    elif command -v jq &>/dev/null; then
      jq -s 'reduce .[] as $item ({}; . * $item)' "${private_snippets[@]}" >"$PUBLIC_SNIPPETS_DIR/private-snippets.code-snippets"
    fi
  fi
  local VSCODE_SNIPPETS_DIR
  for VSCODE_SNIPPETS_DIR in "$HOME/Library/Application Support/Code/User/snippets" "$HOME/.config/Code/User/snippets"; do
    if [ -d "$VSCODE_SNIPPETS_DIR" ]; then
      rm -rf "$VSCODE_SNIPPETS_DIR"
      ln -snf "$PUBLIC_SNIPPETS_DIR" "$VSCODE_SNIPPETS_DIR"
    fi
  done

  mkdir -p "$HOME/.config/harper-ls"
  touch "$HOME/.config/harper-ls/dictionary.txt"
  ln -snf "$HOME/.config/harper-ls/dictionary.txt" "$HOME/.vim-spell-en.utf-8.add"

  # gpg
  mkdir -p ~/.gnupg
  chmod 700 ~/.gnupg
  cp "$DOTFILES_DIR/repos/public/gpg-agent.conf" ~/.gnupg/gpg-agent.conf
  local pinentry_mac
  if pinentry_mac="$(command -v pinentry-mac)"; then
    echo "pinentry-program $pinentry_mac" >>~/.gnupg/gpg-agent.conf
  fi
  local ssh_auth_sock EXPORT_SSH_AUTH_SOCK=""
  ssh_auth_sock="$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null || true)"
  if [ -n "$ssh_auth_sock" ]; then
    EXPORT_SSH_AUTH_SOCK="export SSH_AUTH_SOCK='$ssh_auth_sock'"
  fi

  # git
  GITCONFIG_PATH="$HOME/.gitconfig"
  if [ -n "${GITHUB_CODESPACE_TOKEN:-}" ]; then
    GITCONFIG_PATH="$HOME/.gitconfig.user"
    git config --global include.path .gitconfig.user
  fi
  rm -f "$GITCONFIG_PATH.tmp"
  tmpl_apply <repos/public/gitconfig.tmpl >"$GITCONFIG_PATH.tmp"
  mv -f "$GITCONFIG_PATH.tmp" "$GITCONFIG_PATH"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    git config --global credential.helper osxkeychain
  fi
  git config --global core.hooksPath "$HOME/.githooks"
  chmod 0640 "$GITCONFIG_PATH"
  if command -v meld &>/dev/null; then
    git config --global diff.guitool meld
    git config --global merge.guitool meld
  fi
  if command -v nvim &>/dev/null; then
    git config --global diff.tool nvimdiff
    git config --global merge.tool nvimdiff
  fi
  if [[ "$OSTYPE" == "darwin"* ]]; then
    mkdir -p "$HOME/Library/Application Support/lazygit"
    ln -snf "$DOTFILES_DIR/repos/public/default/.config/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"
  fi

  # zsh
  rm -f ~/.zshrc.tmp
  (
    echo '# vim: fmr={{{{,}}}}:fdm=marker'
    head_cat '#' repos/public/zshrc
    if [ -n "$EXPORT_SSH_AUTH_SOCK" ]; then
      echo "$EXPORT_SSH_AUTH_SOCK"
    fi
    local l
    for l in $(find repos/public/zsh -maxdepth 1 -name '*.zsh' | sort); do
      head_cat '#' "$l"
    done
    echo "# detected aliases {{""{{1"
    detect_aliases
    for l in $(find repos/public/zsh/after -name '*.zsh' | sort); do
      head_cat '#' "$l"
    done
    if command -v fzf &>/dev/null; then
      echo "# fzf {{""{{1"
      fzf_setup zsh
    fi
    mise_rc
    if [[ "$OSTYPE" == "darwin"* ]]; then
      head_cat '#' repos/public/zsh/extras/macos.zsh
    fi
    if command -v okc-ssh-agent &>/dev/null; then
      head_cat '#' repos/public/zsh/extras/okc-ssh-agent.zsh
    fi
    if [[ "$(uname -v)" = iSH* ]]; then
      echo 'source ~/.zshenv'
    fi
    if [ -n "${WSLENV:-}" ]; then
      echo '# proxy {{""{{1'
      echo 'if [ -f /etc/profile.d/proxy.sh ]; then source /etc/profile.d/proxy.sh; fi'
    fi
  ) >~/.zshrc.tmp
  chmod 0440 ~/.zshrc.tmp
  mv -f ~/.zshrc.tmp ~/.zshrc

  # bash
  rm -f ~/.bashrc.tmp
  (
    echo '# vim: fmr={{{{,}}}}:fdm=marker'
    head_cat '#' repos/public/bashrc
    if [ -n "$EXPORT_SSH_AUTH_SOCK" ]; then
      echo "$EXPORT_SSH_AUTH_SOCK"
    fi
    head_cat '#' repos/public/zsh/after/aliases.zsh
    echo "# detected aliases {{""{{1"
    detect_aliases
    head_cat '#' repos/public/zsh/after/functions.zsh
    if [[ "$OSTYPE" == "darwin"* ]]; then
      head_cat '#' repos/public/zsh/extras/macos.zsh
    fi
    if command -v fzf &>/dev/null; then
      echo "# fzf {{""{{1"
      fzf_setup bash
    fi
    mise_rc
    if command -v starship &>/dev/null; then
      echo "# starship {{""{{1"
      echo 'eval "$(starship init bash)"'
    fi
  ) >~/.bashrc.tmp
  chmod 0440 ~/.bashrc.tmp
  mv -f ~/.bashrc.tmp ~/.bashrc

  # mutt
  private ln -snf "$DOTFILES_DIR/repos/private/mutt" ~/.mutt
  private mkdir -p ~/.mutt/cred/
  private chmod -R go-rwx ~/.mutt/cred/
  private find_relative ~/.mutt/accounts | xargs -I % sh -c 'umask 077 && touch "$1" && chmod 600 "$1"' sh ~/.mutt/cred/%

  if [ -n "${WSLENV:-}" ]; then
    if [ -f /etc/profile.d/proxy.sh ]; then
      source /etc/profile.d/proxy.sh
    fi
    local exe
    for exe in ssh scp gpg gopass; do
      if command -v "$exe.exe" &>/dev/null; then
        ln -snf "$(command -v "$exe.exe")" "$HOME/bin/$exe"
      fi
    done
    git config --global core.sshCommand "$HOME/bin/ssh"
    if command -v wslview &>/dev/null; then
      ln -snf "$(command -v wslview)" "$HOME/bin/xdg-open"
    fi
  fi

  # aria2
  mkdir -p ~/.aria2/
  rm -f ~/.aria2/aria2rpc.conf.tmp
  (
    umask 027
    tmpl_apply <repos/public/aria2rpc.conf.tmpl | get_or_set_hash aria2rpc 8 >~/.aria2/aria2rpc.conf.tmp
  )
  chmod 0640 ~/.aria2/aria2rpc.conf.tmp
  mv -f ~/.aria2/aria2rpc.conf.tmp ~/.aria2/aria2rpc.conf

  # Linux GUI
  if [[ "$OSTYPE" == "linux"* && (-n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}") ]]; then
    mkdir -p "$HOME/.config/fontconfig"
    cp -f "$DOTFILES_DIR/repos/public/fontconfig/fonts.conf" "$HOME/.config/fontconfig/"

    # rofi window mode looks up icons by lowercased app_id in the icon theme
    local icon_link
    for icon_link in \
      "256x256/apps/com.anthropic.claude.png:/usr/share/icons/hicolor/256x256/apps/claude-desktop.png" \
      "512x512/apps/md.obsidian.obsidian.png:/usr/share/icons/hicolor/512x512/apps/obsidian.png"; do
      local link="$HOME/.local/share/icons/hicolor/${icon_link%%:*}"
      local target="${icon_link#*:}"
      if [ -f "$target" ]; then
        mkdir -p "$(dirname "$link")"
        ln -snf "$target" "$link"
      fi
    done
  fi

  # termux
  if [[ -n "${TERMUX_VERSION:-}" ]]; then
    mkdir -p "$HOME/.termux"

    ln -snf "$DOTFILES_DIR/repos/public/termux/colors.properties" "$HOME/.termux/"
    ln -snf "$DOTFILES_DIR/repos/public/termux/termux.properties" "$HOME/.termux/"
  fi

  # npmrc
  if ! [[ -f "$HOME/.npmrc" ]]; then
    echo "init-author-name = Ian Yang" >"$HOME/.npmrc"
  fi

  # cargo
  if [ -f ~/.local/share/mbx/bin/cargo ] && [ -f /usr/bin/cargo ]; then
    ln -snf ~/.local/share/mbx/bin/cargo ~/bin/cargo
    ln -snf ~/.local/share/mbx/bin/mbx-target ~/bin/mbx-target
  fi

  # mise
  mkdir -p ~/.config
  ln -snf "$DOTFILES_DIR/repos/public/mise" ~/.config/mise
  touch ~/.config/mise/config.toml

  if command -v mise &>/dev/null && command -v bun &>/dev/null; then
    mise -C "$DOTFILES_DIR/repos/public" build
    "$DOTFILES_DIR/repos/public/dist/mise-tasks/g-agent-config"
  fi
  if [ ! -x "$DOTFILES_DIR/repos/public/dist/git-gpg" ]; then
    if [ -n "${WSLENV:-}" ]; then
      git config --global gpg.program "$HOME/bin/gpg"
    else
      git config --global --unset gpg.program || true
    fi
  fi
}

function cmd_uninstall() {
  find_relative repos/public/MacOS_cp | xargs -I % rm -f "$HOME/%"
  private find_relative repos/private/default | xargs -I % rm -f "$HOME/%"
  find_relative repos/public/default | xargs -I % rm -f "$HOME/%"

  if [ -L ~/bin/nvim ]; then
    rm -f ~/bin/nvim
  fi
  rm -f ~/.bashrc
  rm -f ~/.zshrc
  rm -rf ~/.aria2/
  rm -f ~/.gitconfig
  rm -f ~/.bash_profile
  rm -f ~/.mutt
  rm -f ~/.pandoc
  rm -f ~/.config/nvim
  rm -f ~/.config/mise
  rm -f ~/.claude/skills
  rm -f ~/.claude/AGENTS.md
  rm -f ~/.pi/agent/AGENTS.md
  rm -f ~/.gemini/AGENTS.md
  rm -f ~/.copilot/copilot-instructions.md
  rm -f ~/.config/opencode/AGENTS.md
  rm -f ~/.agents/skills
  rm -f ~/.agents/.skill-lock.json
  rm -f ~/.gemini/settings.json
  rm -f ~/.vim-spell-en.utf-8.add
  rm -f ~/.gnupg/gpg-agent.conf
  rm -f ~/.config/fontconfig/fonts.conf
  rm -f ~/.local/share/icons/hicolor/256x256/apps/com.anthropic.claude.png
  rm -f ~/.local/share/icons/hicolor/512x512/apps/md.obsidian.obsidian.png
  rm -f ~/.termux/colors.properties ~/.termux/termux.properties
  rm -f ~/bin/cargo ~/bin/mbx-target

  if [ -n "${WSLENV:-}" ]; then
    rm -f "$HOME/bin/ssh"
    rm -f "$HOME/bin/scp"
    rm -f "$HOME/bin/gpg"
    rm -f "$HOME/bin/gopass"
    rm -f "$HOME/bin/xdg-open"
  fi
}

function main() {
  local command="${1:-}"
  if [ "$#" -gt 0 ]; then
    shift
  fi
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
    echo "manage.sh repos|install|uninstall [--private]" >&2
    exit 1
    ;;
  esac
}

main "$@"
