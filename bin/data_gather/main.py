#!/usr/bin/env python3

import json, operator, random, re, requests, sys, time
from functools import reduce
from jinja2 import Environment, PackageLoader, select_autoescape

PAUSE_MIN = 1
PAUSE_MAX = 3

jinja_env = Environment()

template = jinja_env.get_template('mining.lua')


sys.exit()

ID_TO_NAME_KEY = "__id_to_name"
MINING_LABEL = "Chance of"

WH_MINING_GUIDE_URL = "https://classic.wowhead.com/guides/mining-classic-wow-1-300"
WH_MINING_ITEM_URL = "https://classic.wowhead.com/item={}"
WH_MINING_NODE_ID_ENDINGS = ["vein", "deposit", "chunk"]
WH_MINING_ITEM_TYPES = ["ore", "stone", "gems"]
WH_MINING_NODE_NAME_KEY = "name_enus"

addon_data = {
    "mining": {
        ID_TO_NAME_KEY: {}
    }
}
mining_data = addon_data["mining"]

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
        obj = mining_data.setdefault(name, [skills, "1", MINING_LABEL])

        count = 1
        for item_id in item_ids:
            html = get_html_data(WH_MINING_ITEM_URL.format(item_id))
            if html is None:
                write_error("No data for item_id {}\n".format(item_id))
                continue

            m = re.search('WH.Gatherer.addData\(3, 4,.*?"{}".*?name_enus":"(.*?)".*?quality":(\d+)'.format(item_id), html)
            if m is None: continue

            item_name = m.group(1)
            color = m.group(2)
            obj.append([item_name, color, MINING_LABEL])

            write_info("Processing {} -> {}={}\n".format(name, item_name, color))

            ## Don't hammer wowhead with requests
            if count < len(item_ids):
                sleep()
            count += 1

        break
    break

del mining_data[ID_TO_NAME_KEY]

print(json.dumps(addon_data, indent=3, separators=(',', ':')))


