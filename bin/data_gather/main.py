#!/usr/bin/env python3

import json, operator, random, re, requests, sys, time
from datetime import datetime
from functools import reduce
from jinja2 import Environment, FileSystemLoader

item_cache = {}

PAUSE_MIN = 1
PAUSE_MAX = 3

jinja_env = Environment(
    loader=FileSystemLoader('templates')        
)

ID_TO_NAME_KEY = "__id_to_name"
ALL_NAMES_KEY = "__all_names"
MINING_LABEL = "Chance of"

WH_MINING_GUIDE_URL = "https://classic.wowhead.com/guides/mining-classic-wow-1-300"
WH_MINING_ITEM_URL = "https://classic.wowhead.com/item={}"
WH_MINING_NODE_ID_ENDINGS = ["vein", "deposit", "chunk"]
WH_MINING_ITEM_TYPES = ["ore", "stone", "gems"]
WH_MINING_NODE_NAME_KEY = "name_enus"

addon_data = {
    "mining": {
        ID_TO_NAME_KEY: {},
        ALL_NAMES_KEY: {},
    }
}
mining_data = addon_data["mining"]

def in_cache(item):
    if item in item_cache:
        return True
    else:
        return False

def add_to_cache(item, val=True):
    item_cache[item] = val

def get_from_cache(item):
    if in_cache(item):
        return item_cache[item]
    else:
        return None

def sleep():
    time.sleep(random.randint(PAUSE_MIN, PAUSE_MAX))

def write_info(msg):
    sys.stdout.write("INF: {}".format(msg))

def write_error(msg):
    sys.stderr.write("ERR: {}".format(msg))

def get_html_data(url):
    response = requests.get(url)
    code = response.status_code

    if code != 200:
        write_error("Received {:d} HTTP code\n".format(code))
        return None

    return response.text


html = get_html_data(WH_MINING_GUIDE_URL)
if html is None: sys.exit(1)

## Find all the mining node names and their IDs
## Create name -> ID mapping
## Create ID -> name mapping
base_objects = re.search("WH\.Gatherer\.addData\(2, 4, (\{.*?})\);", html)

if base_objects:
    json_data = json.loads(base_objects.group(1))

    for k, v in json_data.items():
        obj_id = k
        obj_name = v[WH_MINING_NODE_NAME_KEY]

        if re.search("(?i)({})$".format("|".join(WH_MINING_NODE_ID_ENDINGS)), obj_name):
            mining_data[ID_TO_NAME_KEY][obj_id] = obj_name

## Get all the items a given node can produce along with their IDs
object_data = re.search(r'recorded spawn locations\.(?:\\[nr])+(.*?)(?:\\[nr])+\[br\](?:\\[nr])+\[h2\]Smelting Ore', html)
object_data = object_data.group(1)
object_data = re.sub(r'(?:\\[nr])+', '', object_data)
object_data = re.sub('\\\([/"])', r'\1', object_data)

for data in re.findall("\[h3\].*?(?=(?:\[h3\])|$)", object_data):
    ## Node names - some have multiple like Mithril Deposit and Ooze Covered Mithril Deposit
    m = re.search("(?i)\[b\]Mineral (?:{})s?:\[/b\]\s*(.*?)\s*\[b\]".format("|".join(WH_MINING_NODE_ID_ENDINGS)), data)
    if m is None: continue
    node_ids = re.sub("[^\d,]", "", m.group(1)).split(",")
    node_names = list(map(lambda node_id: mining_data[ID_TO_NAME_KEY][node_id], node_ids))

    ## Node ore mining difficulties
    m = re.search("\[color=r1\](\d+).*?\[color=r2\](\d+).*?\[color=r3\](\d+).*?\[color=r4\](\d+)", data)
    if m is None: continue
    skills = "{},{},{},{}".format(m.group(1), m.group(2), m.group(3), m.group(4))

    ## Node items produced
    item_ids = []
    for label in WH_MINING_ITEM_TYPES:
        m = re.search("(?i)\[b\]{}:\[/b\]\s*(.*?)\s*\[b\]".format(label), data)
        if m is None: continue
        items_str = re.sub("(?i)\(\[(?:zone)=\d+\].*?\)", "", m.group(1))
        item_ids.append(re.sub("[^\d,]", "", items_str).split(","))

    item_ids = list(filter(None, reduce(operator.concat, item_ids)))

    for name in node_names:
        mining_data[ALL_NAMES_KEY][name] = True

        mining_data[name] = {
            "skills": skills.split(","),
            "color": "1",
            "label": MINING_LABEL,
            "items": []
        }

        for item_id in item_ids:
            if in_cache(item_id):
                item_data = get_from_cache(item_id)
                info_label = "From Cache"

            else:
                html = get_html_data(WH_MINING_ITEM_URL.format(item_id))
                if html is None:
                    write_error("No data for item_id {}\n".format(item_id))
                    continue

                m = re.search('WH.Gatherer.addData\(3, 4,.*?"{}".*?name_enus":"(.*?)".*?quality":(\d+)'.format(item_id), html)
                if m is None: continue

                item_name = m.group(1)
                color = m.group(2)
                info_label = "Processing"

                item_data = {
                    "name": item_name,
                    "color": color,
                    "label": MINING_LABEL
                }

                add_to_cache(item_id, item_data)

                ## Don't hammer wowhead with requests
                sleep()

            mining_data[name]["items"].append(item_data)

            item_name = item_data["name"]
            mining_data[ALL_NAMES_KEY][item_name] = True
            write_info("{} {} -> {}={}\n".format(info_label, name, item_name, color))

        sorted_items = sorted(mining_data[name]["items"], key = lambda i: "{}{}".format(i['color'], i['name']))
        mining_data[name]["items"] = sorted_items

        if name == "Tin Vein":
            break
    if "Tin Vein" in node_names:
        break

## Create locale lua file
locale_template = jinja_env.get_template('locales/enUS/mining.lua')
locale_template.stream(pull_time=datetime.now(), items=sorted(mining_data[ALL_NAMES_KEY].keys())).dump('output_locales/enUS/mining.lua')

del mining_data[ID_TO_NAME_KEY]
del mining_data[ALL_NAMES_KEY]

module_template = jinja_env.get_template('gather_modules/Mining.lua')
module_template.stream(pull_time=datetime.now(), items=mining_data).dump('output_gather_modules/Mining.lua')

#print(json.dumps(addon_data, indent=3, separators=(',', ':')))

