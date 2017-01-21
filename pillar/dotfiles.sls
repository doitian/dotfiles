{%- macro github(user_repo, protocol="https") -%}
  {%- if protocol == "git" -%}
git@github.com:{{ user_repo }}.git
  {%- else -%}
https://github.com/{{ user_repo }}.git
  {%- endif -%}
{%- endmacro -%}

{%- macro github_file(user_repo, file, branch="master") -%}
https://raw.githubusercontent.com/{{ user_repo }}/{{ branch }}/{{ file }}
{%- endmacro -%}

dotfiles:
  # All repos are created in .dotfiles/NAME
  repos:
    public:
      git: {{ github("doitian/dotfiles-public") }}
      # location: .dotfiles/repos/public
    private:
      git: {{ github("doitian/dotfiles-private") }}
      private: True
    on-my-zsh:
      git: {{ github("robbyrussell/oh-my-zsh") }}
      location: .oh-my-zsh
    bd.zsh:
      single: {{ github_file("Tarrasch/zsh-bd", "bd.zsh") }}
    plug.vim:
      single: {{ github_file("junegunn/vim-plug", "plug.vim") }}
    flora_pac:
      single: {{ github_file("Leask/Flora_Pac", "flora_pac") }}
      mode: 0755
    chnroutes.py:
      single: {{ github_file("fivesheep/chnroutes", "chnroutes.py") }}
      mode: 0755
    qshell:
      archive: http://devtools.qiniu.com/qshell-v2.0.0.zip
      enforce_toplevel: False

  phrases:
  - file.directory:
    - location: .zcompcache
    - location: .vim/backup
  - file.symlink:
    - location: .vim/autoload/plug.vim
      source: .dotfiles/repos/plug.vim
    - location: bin/flora_pac
      source: .dotfiles/repos/flora_pac
      mode: 0555
    - location: bin/chnroutes.py
      source: .dotfiles/repos/chnroutes.py
      mode: 0555
    - location: bin/qshell
      source: .dotfiles/repos/qshell/qshell_{{ salt['grains.filter_by']({
        'MacOS': 'darwin_amd64',
        'Windows': 'windows_amd64',
        'default': 'linux_amd64'
      }) }}
  - file.managed:
    - location: .gitconfig
      source: .dotfiles/repos/public/gitconfig.jinja
      template: jinja
      mode: 0640
    - location: .safebin
      contents: "{{ salt['grains.get_or_set_hash']('dotfiles:safebin_secret', length=8, chars='abcdefghijklmnopqrstuvwxyz0123456789') }}"
      mode: 0400
  - file.concat:
    - location: .zshrc
      comment: '# '
      mode: 0440
      source:
        - .dotfiles/repos/public/zshrc
        {%- load_yaml as libs %}
        - completion
        - directories
        - functions
        - grep
        - history
        - key-bindings
        - git
        - misc
        - spectrum
        - termsupport
        - theme-and-appearance
        {%- endload %}
        {%- for l in libs %}
        - .oh-my-zsh/lib/{{ l }}.zsh
        {%- endfor %}
        {%- for p in ['safe-paste', 'ssh-agent', 'rake-fast'] %}
        - .oh-my-zsh/plugins/{{ p }}/{{ p }}.plugin.zsh
        {%- endfor %}
        - .oh-my-zsh/plugins/gitfast/git-prompt.sh
        - find:
            path: .dotfiles/repos/public/zsh
            name: '*.zsh'
        - .dotfiles/repos/bd.zsh
        - .dotfiles/repos/public/zshrc.after

  - file.find:
    - source: .dotfiles/repos/public/default
      symlink: True
    - source: .dotfiles/repos/private/default
      symlink: True
      private: True
  {%- if grains.os_family == "MacOS" %}
  - file.find:
    - source: .dotfiles/repos/public/MacOS
      symlink: True
  - file.find:
    - source: .dotfiles/repos/public/MacOS_cp
      managed:
        mode: 440
  - file.managed:
    - source: .dotfiles/repos/public/environment.plist.jinja
      template: jinja
      location: .MacOSX/environment.plist
  {%- endif %}
