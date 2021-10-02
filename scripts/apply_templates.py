import os
import re
import sys
import glob
from jinja2 import Environment, FileSystemLoader, select_autoescape


# Should existing files be overwritten
OVERWRITE = True 

# Map of jinja variables to environment variables
jinja_to_env = {
    "pod_install_dir": "POD_CHARLESREID1_DIR",
    "top_domain": "POD_CHARLESREID1_TLD",
    "server_name_default" : "POD_CHARLESREID1_TLD",
    "username": "POD_CHARLESREID1_USER",
    # docker-compose:
    "mysql_password" : "POD_CHARLESREID1_MYSQL_PASSWORD",
    "mediawiki_secretkey" : "POD_CHARLESREID1_MW_ADMIN_EMAIL",
    # mediawiki:
    "admin_email": "POD_CHARLESREID1_MW_ADMIN_EMAIL",
    # gitea:
    "gitea_app_name": "POD_CHARLESREID1_GITEA_APP_NAME",
    "gitea_secret_key": "POD_CHARLESREID1_GITEA_SECRET_KEY",
    "gitea_internal_token": "POD_CHARLESREID1_GITEA_INTERNAL_TOKEN",
    # aws:
    "backup_canary_webhook_url": "POD_CHARLESREID1_CANARY_WEBHOOK",
}

scripts_dir = os.path.dirname(os.path.abspath(__file__))
repo_root = os.path.abspath(os.path.join(scripts_dir, '..'))


def check_env_vars():
    env_var_list = jinja_to_env.values()
    nerrs = 0
    print("Checking environment variables")
    for env_var in env_var_list:
        try:
            _ = os.environ[env_var]
        except KeyError:
            nerrs += 1
            print(f"Missing environment variable: {env_var}")
    if nerrs > 0:
        raise Exception("Environment variables check did not succeed")


def main():

    check_env_vars()

    p = os.path.join(repo_root,'**','*.j2')
    template_files = glob.glob(p, recursive=True)

    print(f"Found {len(template_files)} template files in {repo_root}:")
    print("\n".join([f"- {j}" for j in template_files]))
    print("")
    
    for template_file in template_files:
        
        # get paths and filenames for template file and output file
        tpath = os.path.abspath(template_file)
        tdir, tname = os.path.split(tpath)
        rname = tname[:-3]
        rpath = os.path.join(tdir, rname)

        env = Environment(loader=FileSystemLoader(tdir))
    
        print(f"Rendering template {tname}:")
        print(f"    Template path: {tpath}")
        print(f"    Output path: {rpath}")

        jinja_vars = {}
        for k, v in jinja_to_env.items():
            jinja_vars[k] = os.environ[v]

        content = env.get_template(tname).render(jinja_vars)
    
        # Write to file
        if os.path.exists(rpath) and not OVERWRITE:
            raise Exception("Error: file %s already exists!"%(rpath))
        else:
            with open(rpath,'w') as f:
                f.write(content)
            print(f"    Done!")
            print("")
    
if __name__=="__main__":
    main()
