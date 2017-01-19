# Dotfiles Provision

This repository is used to manage dotfiles, my public dotfiles repository has been moved to https://github.com/doitian/dotfiles-public

Install

```
make
```

Uninstall

```
make uninstall
```

With private staffs

```
make install private=True
make uninstall private=True
```

Other userful Makefile variables:

- user: install dotfiles for this user
- group: set installed file group owner to this