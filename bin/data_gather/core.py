import random, requests, sys, time
from datetime import datetime
from jinja2 import Environment, FileSystemLoader

PAUSE_MIN = 1
PAUSE_MAX = 3

ID_TO_NAME_KEY = "__id_to_name"
ALL_NAMES_KEY = "__all_names"

locales_input_base_dir = 'locales'
locales_output_base_dir = 'output_locales'
modules_input_base_dir = 'gather_modules'
modules_output_base_dir = 'output_gather_modules'

item_cache = {}


def get_jinja_env():
    return Environment(loader=FileSystemLoader('templates'))

def create_locale_lua(template_file, data):
    locale_template = get_jinja_env().get_template("{}/{}".format(locales_input_base_dir, template_file))
    locale_template.stream(pull_time=datetime.now(), items=sorted(data)).dump("{}/{}".format(locales_output_base_dir, template_file))

def create_module_lua(template_file, data):
    module_template = get_jinja_env().get_template("{}/{}".format(modules_input_base_dir, template_file))
    module_template.stream(pull_time=datetime.now(), items=data).dump("{}/{}".format(modules_output_base_dir, template_file))

def get_item_cache():
    return item_cache

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

