#!/usr/bin/env python3

import json, operator, re, requests, sys
from datetime import datetime
from functools import reduce

from core import create_locale_lua, create_module_lua, get_item_cache, in_cache, add_to_cache, get_from_cache, sleep, write_info, write_error, get_html_data
from core import PAUSE_MIN, PAUSE_MAX, ID_TO_NAME_KEY, ALL_NAMES_KEY, MODULE_NAME_KEY, DATA_NAME_KEY

module_name = "Skinning"
locale_template_file = 'enUS/base.lua'
module_template_file = 'Base.lua'

item_cache = get_item_cache()

LABEL = "Chance of"

MAIN_URL = "https://classic.wowhead.com/npcs/min-level:{}/max-level:{}?filter=10;1;0"
DATA_URL = "https://classic.wowhead.com/npc={}"

addon_data = {
    ID_TO_NAME_KEY: {},
    ALL_NAMES_KEY: {},
    MODULE_NAME_KEY: module_name,
    DATA_NAME_KEY: {},
}

url_data = []

for i in range(1, 7):
    max_level = i * 10
    min_level = max_level - 9

    url = MAIN_URL.format(min_level, max_level)
    html = get_html_data(url)
    if html is None: continue

    m = re.search("new Listview\(\{.*?\"template\"\s*:\s*\"npc\".*?data\"\s*:(\[\{.*\}\])", html)

    if m is not None:
        json_data = json.loads(m.group(1))

        for npc in json_data:
            npc_name = npc['name']
            npc_id = npc['id']

            addon_data[ALL_NAMES_KEY][npc_name] = True
            addon_data[ID_TO_NAME_KEY][npc_id] = npc_name

            addon_data[DATA_NAME_KEY][npc_name] = {
                "skills": ["1", "1", "1", "1"],
                "color": "1",
                "label": LABEL,
                "items": []
            }

            #print("{} = {}".format(npc_id, npc_name))

            html = get_html_data(DATA_URL.format(npc_id))
            if html is None:
                write_error("No data for item_id {}\n".format(npc_id))
                continue

            m = re.search("new Listview\(\{template: 'item', id: 'skinning'.*?data:\s*(\[\{.*?\}\])\}\);", html)
            if m is None: continue

            data = m.group(1)
            data = re.sub(',count.*?(\}(?:,|\]))', r'\1', data)
            item_data = json.loads(data)

            for item in item_data:
                if "subclass" not in item: continue
                if int(item["subclass"]) != 6: continue

                item_name = item["name"]
                color = item["quality"]

                addon_data[DATA_NAME_KEY][npc_name]["items"].append({
                    "name": item_name,
                    "color": color,
                    "label": LABEL
                })

                addon_data[ALL_NAMES_KEY][item_name] = True
                write_info("{} {} -> {}={}\n".format("Processing", npc_name, item_name, color))

            sorted_items = sorted(addon_data[DATA_NAME_KEY][npc_name]["items"], key = lambda i: "{}{}".format(i['color'], i['name']))
            addon_data[DATA_NAME_KEY][npc_name]["items"] = sorted_items

    sleep()


create_locale_lua(locale_template_file, addon_data)
create_module_lua(module_template_file, addon_data)

#print(json.dumps(addon_data, indent=3, separators=(',', ':')))


