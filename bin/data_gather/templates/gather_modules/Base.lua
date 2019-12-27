-- THIS FILE IS AUTO_GENERATED. DO NOT EDIT. ALL CHANGES WILL BE LOST.
-- LAST UPDATE FROM https://classic.wowhead.com AT {{ pull_time }} UTC

local L = GatherSage2.L
local module = GatherSage2:NewModule(L["{{ module_name }}"])

local data = {% raw -%}{{%- endraw -%}{% for k, v in items.items() %}
    [L["{{k}}"]] = {
        {% raw -%}{{%- endraw -%}{%- for s in v.skills -%}
            "{{s}}"{%- if not loop.last %}, {% endif -%}
        {%- endfor -%}{%- raw -%}},{%- endraw %}
        L["{{ v["label"] }}"],
    {%- for i in v["items"] %}
        {% raw -%}{{%- endraw -%}L["{{ i.name }}"], "{{ i.color }}", L["{{ i.label }}"]{%- raw -%}},{%- endraw -%}
    {% endfor %}
    }{%- if not loop.last %},{% endif %}
    {%- endfor %}
{% raw -%}}{%- endraw %}

module:SetProperty("data", data)

