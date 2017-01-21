include:
  - .pkgs
  - .rbenv
  {%- if grains.os_family == 'MacOS' %}
  - .mas
  {%- endif %}
  - .pip
  - .npm
  - .golang
