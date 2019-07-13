import os, re, sys
from jinja2 import Environment, FileSystemLoader, select_autoescape

"""
Apply Default Values to Jinja Templates


This script applies default values to 
docker-compose.yml file.

The template is useful for Ansible,
but this is useful for experiments/one-offs.
"""


# Where templates live
TEMPLATEDIR = '.'

# Where rendered templates will go
OUTDIR = '.'

# Should existing files be overwritten
OVERWRITE = False

env = Environment(loader=FileSystemLoader('.'))

tfile = 'docker-compose.yml.j2'
rfile = 'docker-compose.yml'

content = env.get_template(tfile).render({
    "server_name_default" : "charlesreid1.com",
    "mediawiki_secretkey" : "asdfqwerty_oiuqoweiruoasdfi",
    "mysql_password" : "MySuperSecretPassword"
})

# Write to file
if os.path.exists(rfile) and not OVERWRITE:
    raise Exception("Error: file %s already exists!"%(rfile))
else:
    with open(rfile,'w') as f:
        f.write(content)

