# Dotfiles Provision

This repository is used to manage dotfiles, my public dotfiles repository has been moved to https://github.com/doitian/dotfiles-public

Install

```
./manage.sh repos
./manage.sh install
```

Uninstall

```
./manage.sh uninstall
```

With private files, clone them with `repos -p` before `install -p`:

```
./manage.sh repos -p
./manage.sh install -p
./manage.sh uninstall -p
```

`mise run install` and `mise run repo` pass `-p` automatically when `repos/private` exists.

## New machines

On Arch, Debian or Fedora, run the platform script from a checkout twice: first as root to create the user `ian`, add the SSH key and clone this repository into `/home/ian/.dotfiles`, then as `ian` to install packages.

```
sudo ./arch.sh    # or debian.sh / fedora.sh
passwd ian        # if ian has no password yet, so sudo works
su - ian
cd ~/.dotfiles && ./arch.sh && ./manage.sh repos && ./manage.sh install
```

- `debian.sh --apt [--brew]` installs the apt packages, and Homebrew ones with `--brew`. `setup.sh` runs it together with `manage.sh` in a fresh container or Codespace.
- `macos.sh` installs `Brewfile` and the Python packages in `requirements.txt`.
- `wsl.sh` toggles the Windows host proxy and unlocks the GNOME keyring in WSL; see the comments at its top.
- `cloud-init.yaml` creates the user on cloud VMs instead of the root step above.

Windows: [dotfiles-windows](https://github.com/doitian/dotfiles-windows).
