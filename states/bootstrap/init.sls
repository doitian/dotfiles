include:
  {%- if grains.os_family == 'MacOS' %}
  - .macos
  {%- endif %}
