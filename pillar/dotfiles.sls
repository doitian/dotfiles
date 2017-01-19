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
    # location: .dotfiles/repos/private

    # download_archive:
    #   archive: http://example.com/archive.zip
    # download_single:
    #   single: http://example.com/single

  phrases:
  - file.directory:
    - location: .vim/backup
  - file.managed:
    - location: .vim/autoload/plug.vim
      source: {{ github_file("junegunn/vim-plug", "plug.vim") }}
  - file.find:
    - source: .dotfiles/repos/public/default
      symlink: True
  {%- if grains.os_family == "MacOS" %}
  - file.find:
    - source: .dotfiles/repos/public/MacOS
      symlink: True
  - file.find:
    - source: .dotfiles/repos/public/MacOS_cp
      managed:
        mode: 440
  {%- endif %}
