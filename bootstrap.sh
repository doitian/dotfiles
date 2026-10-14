# Sourced by arch.sh, debian.sh and fedora.sh when they run as root.

function bootstrap_user() {
  local admin_group="$1"

  if ! id ian &>/dev/null; then
    useradd -s /usr/bin/zsh -m ian
  fi
  usermod -aG "$admin_group" ian

  pushd /home/ian >/dev/null || return
  if ! [ -d .ssh ]; then
    sudo -H -u ian mkdir -m 700 .ssh
    sudo -H -u ian tee .ssh/authorized_keys >/dev/null <<"SSH"
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO+Gm8XO6FLDbmYjaFfHoFMtAe/YvkTycV/Sj/uXH6sp ian
SSH
    ssh-keyscan -H github.com | sudo -H -u ian tee .ssh/known_hosts >/dev/null
    chmod o-rw,g-w .ssh/authorized_keys .ssh/known_hosts
  fi
  if ! [ -d .dotfiles ]; then
    sudo -H -u ian git clone --filter=blob:none https://github.com/doitian/dotfiles.git .dotfiles
  fi
  popd >/dev/null || return

  case "$(passwd -S ian 2>/dev/null | awk '{print $2}')" in
  L | LK | NP)
    echo "==> run 'passwd ian' so ian can use sudo"
    ;;
  esac
}
