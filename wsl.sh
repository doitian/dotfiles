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
#
# --- GNOME keyring (libsecret / Bun Secrets) ---
#
# WSL has no PAM login, so gnome-keyring-daemon starts locked and tools that
# read secrets (Bun Secrets, `git-mgen`, ...) fail. Store the keyring password
# once and install a systemd user service that unlocks the default collection
# right after the daemon starts:
#
#   ./wsl.sh keyring-install        install + enable the unlock service
#   ./wsl.sh keyring-set-password   prompt for and store the password (0600)
#   ./wsl.sh keyring-unlock         unlock now (also run by the service)
#   ./wsl.sh keyring-status
#   ./wsl.sh keyring-uninstall
#
# The unlock uses gnome-keyring's private D-Bus method
# UnlockWithMasterPassword on the default collection. It needs PyGObject
# (python3-gi) and a working session bus.

PROXY_HOST="${PROXY_HOST:-127.0.0.1}"
PROXY_PORT="${PROXY_PORT:-7890}"
_PROXY_HTTP="http://${PROXY_HOST}:${PROXY_PORT}"
_PROXY_SOCKS="socks5://${PROXY_HOST}:${PROXY_PORT}"

_PROFILE_FILE="/etc/profile.d/proxy.sh"
_APT_FILE="/etc/apt/apt.conf.d/99proxy"

_KEYRING_PASSWORD_FILE="${WSL_KEYRING_PASSWORD_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/keyring/password}"
_KEYRING_UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
_KEYRING_UNIT_NAME="gnome-keyring-unlock.service"
_KEYRING_UNIT_FILE="$_KEYRING_UNIT_DIR/$_KEYRING_UNIT_NAME"
_KEYRING_PYTHON="${WSL_KEYRING_PYTHON:-/usr/bin/python3}"
_WSL_SH="$(readlink -f "${BASH_SOURCE[0]:-$0}")"

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

_wsl_keyring_require_gi() {
    command -v "$_KEYRING_PYTHON" >/dev/null 2>&1 || {
        echo "error: $_KEYRING_PYTHON not found" >&2
        return 1
    }
    "$_KEYRING_PYTHON" -c 'import gi; gi.require_version("Gio", "2.0")' 2>/dev/null || {
        echo "error: $_KEYRING_PYTHON needs PyGObject: sudo apt install -y python3-gi" >&2
        return 1
    }
}

_wsl_keyring_unlock() {
    _wsl_keyring_require_gi || return 1
    if [ ! -r "$_KEYRING_PASSWORD_FILE" ]; then
        echo "error: no password file at $_KEYRING_PASSWORD_FILE (run: wsl.sh keyring-set-password)" >&2
        return 1
    fi
    export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
    "$_KEYRING_PYTHON" - "$_KEYRING_PASSWORD_FILE" <<'PY'
import sys
import time

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

BUS = "org.freedesktop.secrets"
PATH = "/org/freedesktop/secrets"
IFACE = "org.freedesktop.Secret.Service"
GUILT = "org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface"


def call(conn, iface, method, params, reply_type, path=PATH):
    return conn.call_sync(
        BUS,
        path,
        iface,
        method,
        params,
        GLib.VariantType(reply_type) if reply_type else None,
        Gio.DBusCallFlags.NONE,
        -1,
        None,
    )


def secret(session, value):
    return GLib.Variant.new_tuple(
        GLib.Variant("o", session),
        GLib.Variant("ay", b""),
        GLib.Variant("ay", value),
        GLib.Variant("s", "text/plain"),
    )


password = open(sys.argv[1], "rb").read().rstrip(b"\n")

last = None
for _ in range(30):
    try:
        conn = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        reply = call(
            conn,
            IFACE,
            "ReadAlias",
            GLib.Variant.new_tuple(GLib.Variant("s", "default")),
            "(o)",
        )
        collection = reply.unpack()[0]
        if not collection or collection == "/":
            print("no default keyring collection found", file=sys.stderr)
            sys.exit(2)
        reply = call(
            conn,
            IFACE,
            "OpenSession",
            GLib.Variant.new_tuple(
                GLib.Variant("s", "plain"),
                GLib.Variant("v", GLib.Variant("s", "")),
            ),
            "(vo)",
        )
        session = reply.unpack()[1]
        call(
            conn,
            GUILT,
            "UnlockWithMasterPassword",
            GLib.Variant.new_tuple(
                GLib.Variant("o", collection), secret(session, password)
            ),
            "()",
        )
        print("unlocked " + collection)
        break
    except GLib.Error as e:
        last = e
        if "password was invalid" in e.message or "Denied" in e.message:
            print("failed to unlock keyring: " + e.message, file=sys.stderr)
            sys.exit(1)
        time.sleep(1)
else:
    print("keyring not ready: " + (last.message if last else "unknown"), file=sys.stderr)
    sys.exit(1)
PY
}

_wsl_keyring_set_password() {
    local pw pw2 dir
    read -r -s -p "Keyring password: " pw; echo
    read -r -s -p "Confirm password: " pw2; echo
    if [ "$pw" != "$pw2" ]; then
        echo "error: passwords do not match" >&2
        return 1
    fi
    dir="$(dirname "$_KEYRING_PASSWORD_FILE")"
    mkdir -p "$dir"
    chmod 700 "$dir"
    printf '%s' "$pw" > "$_KEYRING_PASSWORD_FILE"
    chmod 600 "$_KEYRING_PASSWORD_FILE"
    echo "stored keyring password in $_KEYRING_PASSWORD_FILE"
    if [ -f "$_KEYRING_UNIT_FILE" ]; then
        _wsl_keyring_unlock || true
        systemctl --user restart "$_KEYRING_UNIT_NAME" 2>/dev/null || true
    fi
}

_wsl_keyring_install() {
    _wsl_keyring_require_gi || return 1
    mkdir -p "$_KEYRING_UNIT_DIR"
    cat > "$_KEYRING_UNIT_FILE" <<EOF
[Unit]
Description=Unlock GNOME keyring (WSL)
After=gnome-keyring-daemon.service
Requires=gnome-keyring-daemon.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$_WSL_SH keyring-unlock

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable "$_KEYRING_UNIT_NAME"
    echo "installed $_KEYRING_UNIT_FILE"
    if [ -r "$_KEYRING_PASSWORD_FILE" ]; then
        _wsl_keyring_unlock && systemctl --user restart "$_KEYRING_UNIT_NAME"
    else
        echo "next: run 'wsl.sh keyring-set-password' to store the password"
    fi
}

_wsl_keyring_status() {
    if [ -r "$_KEYRING_PASSWORD_FILE" ]; then
        echo "password: $_KEYRING_PASSWORD_FILE (present)"
    else
        echo "password: missing (run 'wsl.sh keyring-set-password')"
    fi
    if [ -f "$_KEYRING_UNIT_FILE" ]; then
        printf 'service : %s (%s/%s)\n' "$_KEYRING_UNIT_FILE" \
            "$(systemctl --user is-enabled "$_KEYRING_UNIT_NAME" 2>/dev/null)" \
            "$(systemctl --user is-active "$_KEYRING_UNIT_NAME" 2>/dev/null)"
    else
        echo "service : not installed (run 'wsl.sh keyring-install')"
    fi
}

_wsl_keyring_uninstall() {
    systemctl --user disable --now "$_KEYRING_UNIT_NAME" 2>/dev/null || true
    rm -f "$_KEYRING_UNIT_FILE"
    systemctl --user daemon-reload
    echo "removed $_KEYRING_UNIT_FILE (password file left in place)"
}

case "$1" in
    on)     _wsl_proxy_on ;;
    off)    _wsl_proxy_off ;;
    status) _wsl_proxy_status ;;
    test)   _wsl_proxy_test ;;
    keyring-install)      _wsl_keyring_install ;;
    keyring-set-password) _wsl_keyring_set_password ;;
    keyring-unlock)       _wsl_keyring_unlock ;;
    keyring-status)       _wsl_keyring_status ;;
    keyring-uninstall)    _wsl_keyring_uninstall ;;
    *)      echo "usage: . wsl.sh {on|off|status|test|keyring-install|keyring-set-password|keyring-unlock|keyring-status|keyring-uninstall}" ;;
esac
