import os
import re
import sys
import glob
from jinja2 import Environment, FileSystemLoader, select_autoescape

"""
Apply Default Values to all Jinja Templates
"""


scripts_dir = os.path.dirname(os.path.abspath(__filename__))
repo_root = os.path.abspath(os.path.join(scripts_dir, '..'))


def main():
    env = Environment(loader=FileSystemLoader('.'))
    
    # Should existing files be overwritten
    OVERWRITE = False

    p = os.path.join(repo_root,'**','*.j2')
    template_files = glob.glob(p)
    
    for template_file in template_files:
        
        # full path to template file
        tpath = os.path.abspath(template_file))
    
        # split into directory and filename
        tdir, tfile = os.path.split(tpath)
    
        # from template filename, get output filename
        rfile = tfile[:-3]
    
        # full path to output file
        rpath = os.path.join(tdir, rfile)
    
        #content = env.get_template(tfile).render({
        content = env.get_template(tpath).render({
            "pod_install_dir": os.environ('POD_CHARLESREID1_DIR'),
            "top_domain": os.environ('POD_CHARLESREID1_TLD'),
            "server_name_default" : os.environ('POD_CHARLESREID1_TLD'),
            "username": os.environ('POD_CHARLESREID1_USER'),
            # docker-compose:
            "mysql_password" : os.environ('POD_CHARLESREID1_MYSQL_PASSWORD'),
            "mediawiki_secretkey" : os.environ('POD_CHARLESREID1_MW_ADMIN_EMAIL'),
            # mediawiki:
            "admin_email": os.environ('POD_CHARLESREID1_MW_ADMIN_EMAIL'),
            # gitea:
            "gitea_app_name": os.environ('POD_CHARLESREID1_GITEA_APP_NAME'),
            "gitea_secret_key": os.environ('POD_CHARLESREID1_GITEA_SECRET_KEY'),
            "gitea_internal_token": os.environ('POD_CHARLESREID1_GITEA_INTERNAL_TOKEN'),
            # aws:
            "aws_backup_s3_bucket": os.environ('POD_CHARLESREID1_BACKUP_S3BUCKET'),
            "aws_access_key": os.environ('POD_CHARLESREID1_AWS_ACCESS_KEY'),
            "aws_access_secret": os.environ('POD_CHARLESREID1_AWS_ACCESS_SECRET'),
            "backup_canary_webhook_url": os.environ('POD_CHARLESREID1_BACKUPCANARY_WEBHOOKURL'),
        })
    
        # Write to file
        if os.path.exists(rpath) and not OVERWRITE:
            raise Exception("Error: file %s already exists!"%(rpath))
        else:
            with open(rpath,'w') as f:
                f.write(content)
    
    
    
    
    
    
    # Where templates live
    TEMPLATEDIR = '.'
    
    # Where rendered templates will go
    OUTDIR = '.'
    
    
    
    tfile = 'docker-compose.yml.j2'
    rfile = 'docker-compose.yml'
    
    content = env.get_template(tfile).render({
        "pod_install_dir": os.environ('POD_CHARLESREID1_DIR'),
        "top_domain": os.environ('POD_CHARLESREID1_TLD'),
        "server_name_default" : os.environ('POD_CHARLESREID1_TLD'),
        "username": os.environ('POD_CHARLESREID1_USER'),
        # docker-compose:
        "mysql_password" : os.environ('POD_CHARLESREID1_MYSQL_PASSWORD'),
        "mediawiki_secretkey" : os.environ('POD_CHARLESREID1_MW_ADMIN_EMAIL'),
        # mediawiki:
        "admin_email": os.environ('POD_CHARLESREID1_MW_ADMIN_EMAIL'),
        # gitea:
        "gitea_app_name": os.environ('POD_CHARLESREID1_GITEA_APP_NAME'),
        "gitea_secret_key": os.environ('POD_CHARLESREID1_GITEA_SECRET_KEY'),
        "gitea_internal_token": os.environ('POD_CHARLESREID1_GITEA_INTERNAL_TOKEN'),
        # aws:
        "aws_backup_s3_bucket": os.environ('POD_CHARLESREID1_BACKUP_S3BUCKET'),
        "aws_access_key": os.environ('POD_CHARLESREID1_AWS_ACCESS_KEY'),
        "aws_access_secret": os.environ('POD_CHARLESREID1_AWS_ACCESS_SECRET'),
        "backup_canary_webhook_url": os.environ('POD_CHARLESREID1_BACKUPCANARY_WEBHOOKURL'),
    })
    
    # Write to file
    if os.path.exists(rfile) and not OVERWRITE:
        raise Exception("Error: file %s already exists!"%(rfile))
    else:
        with open(rfile,'w') as f:
            f.write(content)
    

if __name__=="__main__":
    main()
