import os
import re
import sys
import glob
from jinja2 import Environment, FileSystemLoader, select_autoescape

"""
Apply Default Values to all Jinja Templates
"""


# Should existing files be overwritten
OVERWRITE = True 


scripts_dir = os.path.dirname(os.path.abspath(__file__))
repo_root = os.path.abspath(os.path.join(scripts_dir, '..'))


def check_env_vars():
    env_var_list = [
        'POD_CHARLESREID1_DIR',
        'POD_CHARLESREID1_TLD',
        'POD_CHARLESREID1_USER',
        'POD_CHARLESREID1_MYSQL_PASSWORD',
        'POD_CHARLESREID1_MW_ADMIN_EMAIL',
        'POD_CHARLESREID1_MW_SECRET_KEY',
        'POD_CHARLESREID1_GITEA_APP_NAME',
        'POD_CHARLESREID1_GITEA_SECRET_KEY',
        'POD_CHARLESREID1_GITEA_INTERNAL_TOKEN',
        'POD_CHARLESREID1_BACKUP_DIR',
        'POD_CHARLESREID1_BACKUP_S3BUCKET',
        'POD_CHARLESREID1_AWS_ACCESS_KEY',
        'POD_CHARLESREID1_AWS_ACCESS_SECRET',
        'POD_CHARLESREID1_CANARY_WEBHOOK',
    ]
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
        #content = env.get_template(tpath).render({
        content = env.get_template(tname).render({
            "pod_install_dir": os.environ['POD_CHARLESREID1_DIR'],
            "top_domain": os.environ['POD_CHARLESREID1_TLD'],
            "server_name_default" : os.environ['POD_CHARLESREID1_TLD'],
            "username": os.environ['POD_CHARLESREID1_USER'],
            # docker-compose:
            "mysql_password" : os.environ['POD_CHARLESREID1_MYSQL_PASSWORD'],
            "mediawiki_secretkey" : os.environ['POD_CHARLESREID1_MW_ADMIN_EMAIL'],
            # mediawiki:
            "admin_email": os.environ['POD_CHARLESREID1_MW_ADMIN_EMAIL'],
            # gitea:
            "gitea_app_name": os.environ['POD_CHARLESREID1_GITEA_APP_NAME'],
            "gitea_secret_key": os.environ['POD_CHARLESREID1_GITEA_SECRET_KEY'],
            "gitea_internal_token": os.environ['POD_CHARLESREID1_GITEA_INTERNAL_TOKEN'],
            # aws:
            "aws_backup_s3_bucket": os.environ['POD_CHARLESREID1_BACKUP_S3BUCKET'],
            "aws_access_key": os.environ['POD_CHARLESREID1_AWS_ACCESS_KEY'],
            "aws_access_secret": os.environ['POD_CHARLESREID1_AWS_ACCESS_SECRET'],
            "backup_canary_webhook_url": os.environ['POD_CHARLESREID1_BACKUPCANARY_WEBHOOKURL'],
        })
    
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
