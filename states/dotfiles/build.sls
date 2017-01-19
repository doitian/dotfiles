{%- from "dotfiles/map.jinja" import dotfiles %}
{%- from "dotfiles/phrases/__index__.jinja" import functions %}

{%- set globals = {'index':0} %}
{%- for function_steps_dict in dotfiles.phrases %}
  {%- for function, steps in function_steps_dict.items() %}
    {%- if functions[function] is defined %}
      {%- for step in steps -%}
        {%- do globals.update(index=globals.index+1) %}
{{ functions[function].install(index=globals.index, **step) }}
      {%- endfor %}
    {%- else %}
      {%- do globals.update(index=globals.index+1) %}
phrase step {{ globals.index }}:
  test.fail_without_changes:
    - name: {{ function }} is not a valid function
    {%- endif %}
  {%- endfor %}
{%- endfor %}