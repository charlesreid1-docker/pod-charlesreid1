import os
import sys
import json
import requests
import boto3
import botocore
import subprocess


webhook_url = os.environ['POD_CHARLESREID1_CANARY_WEBHOOK']
backup_dir = os.environ['POD_CHARLESREID1_BACKUP_DIR']
backup_bucket = os.environ['POD_CHARLESREID1_BACKUP_S3BUCKET']


# Check for backups created in the last N days
N = 7


def main():
    # verify the backups directory exists
    if not os.path.exists(backup_dir):
        msg = "Local Backups Error:\n"
        msg += f"The backup directory `{backup_dir}` does not exist!"
        alert(msg)

    # verify there is a backup newer than N days
    newer_backups = subprocess.getoutput(f'find {backup_dir} -mtime -{N}').split('\n')
    if len(newer_backups)==1 and newer_backups[0]=='':
        msg = "Local Backups Error:\n"
        msg += f"The backup directory `{backup_dir}` is missing backup files from the last {N} day(s)!"
        alert(msg)

    newest_backup_name = subprocess.getoutput(f'ls -t {backup_dir} | head -n1')
    newest_backup_path = os.path.join(backup_dir, newest_backup_name)
    newest_backup_files = subprocess.getoutput(f'find {newest_backup_path} -type f').split('\n')

    # verify the most recent backup directory is not empty
    if len(newest_backup_files)==1 and newer_backups[0]=='':
        msg = "Local Backups Error:\n"
        msg += f"The most recent backup directory `{newest_backup_path}` is empty!"
        alert(msg)

    # verify the most recent backup files have nonzero size
    for backup_file in newest_backup_files:
        if os.path.getsize(backup_file)==0:
            msg = "Local Backups Error:\n"
            msg += f"The most recent backup directory `{newest_backup_path}` contains an empty backup file!\n"
            msg += f"Backup file name: {backup_file}!"
            alert(msg)

    # verify the most recent backup files exist in the s3 backups bucket
    bucket_base_path = os.path.join('backups', newest_backup_name)
    for backup_file in newest_backup_files:
        backup_name = os.path.basename(backup_file)
        bucket_backup_path = os.path.join(bucket_base_path, backup_name)
        check_exists(bucket_name, bucket_backup_path)

def check_exists(bucket_name, bucket_path):
    try:
        s3.Object(bucket_name, bucket_path).load()
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == "404":
            # File does not exist
            msg = "S3 Backups Error:\n"
            msg += f"Failed to find the file `{bucket_path}` in bucket `{bucket_name}`"
        else:
            # Problem accessing backups on bucket
            msg = "S3 Backups Error:\n"
            msg += f"Failed to access the file `{bucket_path}` in bucket `{bucket_name}`"


def alert(msg):
    title = ":bangbang: pod-charlesreid1 backup canary"
    hostname = subprocess.getoutput('hostname')
    msg += f"\n\nHost: {hostname}"
    slack_data = {
        "username": "backups_canary",
        "channel" : "#alerts",
        "attachments": [
            {
                "color": "#CC0000",
                "fields": [
                    {
                        "title": title,
                        "value": msg,
                        "short": "false",
                    }
                ]
            }
        ]
    }
    byte_length = str(sys.getsizeof(slack_data))
    headers = {'Content-Type': "application/json", 'Content-Length': byte_length}
    response = requests.post(webhook_url, data=json.dumps(slack_data), headers=headers)
    if response.status_code != 200:
        raise Exception(response.status_code, response.text)

    print("Goodbye.")
    sys.exit(1)


if __name__ == '__main__':
    main()
