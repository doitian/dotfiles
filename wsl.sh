#!/usr/bin/env bash
# wsl.sh — enable/disable the Windows-host Clash proxy for WSL, system-wide.
#
# `on`  writes  /etc/profile.d/proxy.sh  and  /etc/apt/apt.conf.d/99proxy
#       (persistent: every new login shell + apt use the proxy) and also
#       sets the proxy in the CURRENT shell when this file is sourced.
# `off` deletes both files and unsets the vars in the current shell.
#
# Writing under /etc needs root, so on/off use sudo (or just run as root).
# Source it if you also want the current shell updated immediately:
#
#   . ~/.dotfiles/wsl.sh on
#   . ~/.dotfiles/wsl.sh off
#   . ~/.dotfiles/wsl.sh status
#   . ~/.dotfiles/wsl.sh test
#
# Override host/port (default 127.0.0.1:7890, Clash's mixed port):
#   PROXY_HOST=127.0.0.1 PROXY_PORT=7890 . wsl.sh on
#
# NOTE: 127.0.0.1 only reaches the host Clash when networkingMode=mirrored.

PROXY_HOST="${PROXY_HOST:-127.0.0.1}"
PROXY_PORT="${PROXY_PORT:-7890}"
_PROXY_HTTP="http://${PROXY_HOST}:${PROXY_PORT}"
_PROXY_SOCKS="socks5://${PROXY_HOST}:${PROXY_PORT}"

_PROFILE_FILE="/etc/profile.d/proxy.sh"
_APT_FILE="/etc/apt/apt.conf.d/99proxy"

if [ "$(id -u)" -eq 0 ]; then _SUDO=""; else _SUDO="sudo"; fi

_wsl_env_on() {
    export http_proxy="$_PROXY_HTTP"  https_proxy="$_PROXY_HTTP"  all_proxy="$_PROXY_SOCKS"
    export HTTP_PROXY="$_PROXY_HTTP"  HTTPS_PROXY="$_PROXY_HTTP"  ALL_PROXY="$_PROXY_SOCKS"
    export no_proxy="localhost,127.0.0.1,::1"  NO_PROXY="localhost,127.0.0.1,::1"
}

_wsl_env_off() {
    unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY no_proxy NO_PROXY
}

_wsl_proxy_on() {
    $_SUDO tee "$_PROFILE_FILE" >/dev/null <<EOF
# Managed by wsl.sh — route WSL traffic through the Windows host Clash proxy.
# Requires WSL networkingMode=mirrored so 127.0.0.1 is shared with the host.
export http_proxy="$_PROXY_HTTP"
export https_proxy="$_PROXY_HTTP"
export all_proxy="$_PROXY_SOCKS"
export no_proxy="localhost,127.0.0.1,::1"
export HTTP_PROXY="$_PROXY_HTTP"
export HTTPS_PROXY="$_PROXY_HTTP"
export ALL_PROXY="$_PROXY_SOCKS"
export NO_PROXY="localhost,127.0.0.1,::1"
EOF
    $_SUDO chmod 644 "$_PROFILE_FILE"
    $_SUDO tee "$_APT_FILE" >/dev/null <<EOF
// Managed by wsl.sh — apt runs as root and ignores the shell proxy env.
Acquire::http::Proxy "$_PROXY_HTTP";
Acquire::https::Proxy "$_PROXY_HTTP";
EOF
    $_SUDO chmod 644 "$_APT_FILE"
    _wsl_env_on
    echo "proxy ON  -> $_PROXY_HTTP"
    echo "  wrote $_PROFILE_FILE"
    echo "  wrote $_APT_FILE"
}

_wsl_proxy_off() {
    $_SUDO rm -f "$_PROFILE_FILE" "$_APT_FILE"
    _wsl_env_off
    echo "proxy OFF -> direct"
    echo "  removed $_PROFILE_FILE"
    echo "  removed $_APT_FILE"
}

_wsl_proxy_status() {
    if [ -f "$_PROFILE_FILE" ]; then echo "system: $_PROFILE_FILE present"; else echo "system: $_PROFILE_FILE absent"; fi
    if [ -f "$_APT_FILE" ]; then echo "system: $_APT_FILE present"; else echo "system: $_APT_FILE absent"; fi
    if [ -n "$http_proxy" ]; then echo "shell : proxy ON  -> $http_proxy"; else echo "shell : proxy OFF -> direct"; fi
}

_wsl_proxy_test() {
    for _url in https://www.baidu.com https://www.google.com; do
        _code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$_url")
        _t=$(curl -s -o /dev/null -w '%{time_total}' --max-time 10 "$_url")
        printf '  %-24s http=%s  time=%ss\n' "$_url" "$_code" "$_t"
    done
}

case "$1" in
    on)     _wsl_proxy_on ;;
    off)    _wsl_proxy_off ;;
    status) _wsl_proxy_status ;;
    test)   _wsl_proxy_test ;;
    *)      echo "usage: . wsl.sh {on|off|status|test}" ;;
esac
