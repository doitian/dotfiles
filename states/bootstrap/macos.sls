Homebrew packages:
  pkg.installed:
    - pkgs:
      - aria2
      - bash
      - colordiff
      - coreutils
      - ctags
      - dos2unix
      - duti
      - editorconfig
      - fasd
      - gist
      - git
      - git-extras
      - gradle
      - htop-osx
      - hub
      - hugo
      - imagemagick
      - jq
      - lua@5.3
      - mas
      - mtr
      - node
      - pidof
      - postgresql
      - pstree
      - rbenv
      - rbenv-aliases
      - rbenv-bundler
      - rbenv-default-gems
      - redis
      - rlwrap
      - subversion
      - tag
      - telnet
      - the_silver_searcher
      - tmux
      - tree
      - unrar
      - watchexec
      - yarn
      - zsh
      - zsh-completions
      
npm packages:
  npm.installed:
    - names:
      - prettier
      - eslint
      - eslint-plugin-react
    - require:
      - pkg: 'Homebrew packages'

{%- load_yaml as mas_packages %}
836500024: WeChat
451108668: QQ
880001334: Reeder
419330170: Moom
490152466: iBooks Author
1055511498: Day One
618061906: Softmatic ScreenLayers
451691288: Contacts Sync For Google Gmail
461369673: VOX
682658836: GarageBand
594432954: Read CHM
595615424: QQMusic
734418810: SSH Tunnel
424389933: Final Cut Pro
622066258: Softmatic WebLayers
407963104: Pixelmator
557168941: Tweetbot
937984704: Amphetamine
{%- endload %}

{%- for id, name in mas_packages.items() %}
/Applications/{{ name }}.app:
  cmd.run:
    - name: mas install {{ id }}
    - unless:
      - test -e "/Applications/{{ name }}.app"
    - require:
      - pkg: 'Homebrew packages'
{%- endfor %}
