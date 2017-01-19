{%- from "dotfiles/map.jinja" import dotfiles %}
{%- from "dotfiles/macros.jinja" import abspath, repo_path %}

{%- for name, kwargs in dotfiles.repos.items() if dotfiles.private or not kwargs.get('private', False) %}
dotfiles repo {{ name }}:
  {%- if 'git' in kwargs %}
  git.latest:
    - name: {{ kwargs.git }}
    {%- if 'location' in kwargs or 'target' in kwargs %}
    - target: '{{ abspath(kwargs.get('location', kwargs.get('target'))) }}'
    {%- else %}
    - target: '{{ repo_path(name) }}'
    {%- endif %}
    {%- if 'rev' not in kwargs %}
    - rev: master
    {%- endif %}
    {%- if dotfiles.user is not none %}
    - user: {{ dotfiles.user }}
    {%- endif %}
    {%- for k, v in kwargs.items() if k not in ["private", "name", "git", "location", "target"] %}
    - {{ k }}: {{ v | json }}
    {%- endfor %}
  {% elif 'archive' in kwargs %}
  archive.extracted:
    {%- if 'location' in kwargs or 'name' in kwargs %}
    - name: '{{ abspath(kwargs.get('location', kwargs.get('name'))) }}'
    {%- else %}
    - name: '{{ repo_path(name) }}'
    {%- endif %}
    - source: {{ kwargs.archive }}
    {%- if 'source_hash' not in kwargs %}
    - skip_verify: True
    {%- endif %}
    {%- if dotfiles.user is not none %}
    - user: {{ dotfiles.user }}
    {%- endif %}
    {%- if dotfiles.group is not none %}
    - group: {{ dotfiles.group }}
    {%- endif %}
    {%- for k, v in kwargs.items() if k not in ["private", "name", "archive", "location", "source"] %}
    - {{ k }}: {{ v | json }}
    {%- endfor %}
  {% elif 'single' in kwargs %}
  file.managed:
    {%- if 'location' in kwargs or 'name' in kwargs %}
    - name: '{{ abspath(kwargs.get('location', kwargs.get('name'))) }}'
    {%- else %}
    - name: '{{ repo_path(name) }}'
    {%- endif %}
    - source: {{ kwargs.single }}
    {%- if 'source_hash' not in kwargs %}
    - skip_verify: True
    {%- endif %}
    {%- if dotfiles.user is not none %}
    - user: {{ dotfiles.user }}
    {%- endif %}
    {%- if dotfiles.group is not none %}
    - group: {{ dotfiles.group }}
    {%- endif %}
    {%- for k, v in kwargs.items() if k not in ["private", "name", "single", "location", "source"] %}
    - {{ k }}: {{ v | json }}
    {%- endfor %}
  {%- else %}
  test.fail_without_changes: 
    - name: repo "{{ name }}" type cannot be recoganized
  {%- endif %}
{%- endfor %}