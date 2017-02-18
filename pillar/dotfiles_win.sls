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

dotfiles:
  # All repos are created in .dotfiles/NAME
  repos:
    public:
      git: {{ github("doitian/dotfiles-public") }}
    plug.vim:
      single: {{ github_file("junegunn/vim-plug", "plug.vim") }}
    hugo:
      archive: https://github.com/spf13/hugo/releases/download/v0.18.1/hugo_0.18.1_Windows-64bit.zip
      enforce_toplevel: False

  phrases:
  - file.directory:
    - location: .vim/backup
  - file.managed:
    - location: .vimrc
      source: .dotfiles\repos\public\default\.vimrc
    - location: .vim\autoload\plug.vim
      source: .dotfiles\repos\plug.vim
    - location: .cvsignore
      source: .dotfiles\repos\public\default\.cvsignore
    - location: .gitconfig
      source: .dotfiles\repos\public\gitconfig.jinja
      template: jinja
    - location: bin\hugo.exe
      source: .dotfiles\repos\hugo\hugo_0.18.1_windows_amd64.exe
  {% set posh_profile_dir = salt['environ.get']('PSModulePath').split(';')[0]|replace('\Modules', '') %}
  - file.find:
    - source: .dotfiles\repos\public\WindowsPowerShell
      location: {{ posh_profile_dir}}
      managed: True
  - win.setx:
    - name: CODEBASE
      value: D:\codebase
      replace: False
    - name: GOPATH
      value: '{{ salt['environ.get']('CODEBASE', default='D:\codebase') }}\gopath'
    - name: VCPKG_ROOT
      value: '{{ salt['environ.get']('CODEBASE', default='D:\codebase') }}\vcpkg'
    - name: ONEDRIVE
      location: '{{ onedrive }}'
      replace: False
    - name: Path
      location:
        - bin
        - '{{ onedrive }}\Apps\Apache-Subversion-1.8.13\bin'
        - '{{ onedrive }}\Apps\Sublime'
        - '{{ onedrive }}\Apps\PortableGit\cmd'
        - '{{ onedrive }}\Apps\PortableGit\usr\bin'
        - '{{ onedrive }}\Apps\cmake-3.8.0-rc1-win64-x64\bin'
        - '{{ salt['environ.get']('CODEBASE', default='D:\codebase') }}\gopath\bin'
        - '{{ salt['environ.get']('CODEBASE', default='D:\codebase') }}\vcpkg'
        - '{{ salt['environ.get']('CODEBASE', default='D:\codebase') }}\vcpkg\installed\x64-windows\tools'
