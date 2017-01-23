base:
  '*':
  - git
  {%- if grains.os_family != "Windows" %}
  - dotfiles
  {%- else %}
  - dotfiles_win
  {%- endif %}
