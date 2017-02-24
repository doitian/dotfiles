Homebrew packages:
  pkg.installed:
    - pkgs:
      - ant
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
      - git-number
      - git-extras
      - htop-osx
      - hugo
      - imagemagick
      - jq
      - lua@5.3
      - mtr
      - pidof
      - postgresql
      - pstree
      - redis
      - rlwrap
      - subversion
      - tag
      - the_silver_searcher
      - tig
      - tmux
      - tree
      - unrar
      - zsh-completions
      - mas
      - python3
      - node
      - rbenv
      - rbenv-default-gems
      - rbenv-communal-gems
      - rbenv-aliases
      - rbenv-bundler
      
macvim:
  pkg.installed:
    - options:
      - '--override-system-vim' 

npm packages:
  npm.installed:
    - names:
      - js-beautify
      - eslint
      - eslint-plugin-react
      - jsonlint
    - require:
      - pkg: 'Homebrew packages'

{%- load_yaml as mas_packages %}
836500024: WeChat
451108668: QQ
928871589: Noizio
880001334: Reeder
419330170: Moom
490152466: iBooks Author
863486266: SketchBook
970502923: Typeeto
1055511498: Day One
618061906: Softmatic ScreenLayers
451691288: Contacts Sync For Google Gmail
450201424: Lingon 3
461369673: VOX
682658836: GarageBand
594432954: Read CHM
595615424: QQMusic
734418810: SSH Tunnel
424389933: Final Cut Pro
622066258: Softmatic WebLayers
407963104: Pixelmator
557168941: Tweetbot
429449079: Patterns
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
