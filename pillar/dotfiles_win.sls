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

{%- set onedrive = salt['environ.get']('ONEDRIVE', 'OneDrive') %}
{%- set cmderr = salt['file.join'](salt['environ.get']('ONEDRIVE', 'OneDrive'), 'Apps', 'cmder') %}

dotfiles:
  # All repos are created in .dotfiles/NAME
  repos:
    public:
      git: {{ github("doitian/dotfiles-public") }}
    plug.vim:
      single: {{ github_file("junegunn/vim-plug", "plug.vim") }}
    qshell:
      archive: http://devtools.qiniu.com/qshell-v2.0.0.zip
      enforce_toplevel: False

  phrases:
  - file.directory:
    - location: .vim/backup
  - file.managed:
    - location: .vim\autoload\plug.vim
      source: .dotfiles\repos\plug.vim
    - location: bin/qshell
      source: .dotfiles\repos\qshell\qshell_windows_amd64.exe
    - location: .cvsignore
      source: .dotfiles\repos\public\default\.cvsignore
    - location: .gitconfig
      source: .dotfiles\repos\public\gitconfig.jinja
      template: jinja
  - file.find:
    - source: .dotfiles\repos\public\Windows_cmder
      location: '{{ cmderr }}'
      managed: True
  - win.setx:
    - name: CODEBASE
      value: D:\codebase
      replace: False
    - name: GOPATH
      value: '{{ salt['environ.get']('CODEBASE', default='D:\codebase') }}\gopath'
    - name: ONEDRIVE
      location: '{{ onedrive }}'
      replace: False
    - name: Path
      location:
        - bin
        - '{{ onedrive }}\Apps\cmder\vendor\git-for-windows\bin'
        - '{{ onedrive }}\Apps\Apache-Subversion-1.8.13\bin'
        - '{{ onedrive }}\Apps\Sublime'
        - '{{ salt['environ.get']('CODEBASE', default='D:\codebase') }}\gopath\bin'