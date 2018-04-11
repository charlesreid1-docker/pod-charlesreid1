#!/usr/bin/env python3
import os
import subprocess
import time
import datetime as dt
from os.path import join

"""
Weekly Gitea Backups



Short Description:

Keep a rolling 8-week weekly backup
of gitea files, and a monthly archive.



Long Description:

This backs up the to

    <backup-dir>/backups/weekly/

It creates one directory per weekly backup,
containing two zip files:

    <backup-dir>/backups/weekly/wikidb_YYYY-MM-DD/
                                                  gitea-dump-*.zip
                                                  gitea-avatars.zip

Output from backup commands is logged to:

    <log-dir>/backups/weekly/

One log per weekly backup:

    <log-dir>/backups/weekly/gitea_YYYY-MM-DD.log



Logging:

This cron job logs to its own log file,

    <log-dir>/cron/weekly_gitea_YYYY-MM-DD.log

The output of the commands run by this script are in:

    <log-dir>/backups/weekly/gitea_YYYY-MM-DD.log

"""

home = os.environ['HOME']

utils_location = join(home,"/codes/docker/pod-charlesreid1/utils-gitea")

temp = "/temp"
log_dir = join(home,".logs")


# -----------------------------------


today = dt.date.today().strftime("%Y-%m-%d")

# Meta-logging: set up log file
weekly_log = "weekly_gitea_"+today+".log"
cron_log_dir = join(log_dir,"cron")
meta_log = join(cron_log_dir,weekly_log)

# Make log dir
subprocess.call(["mkdir","-p",cron_log_dir])

ml = open(meta_log,'w')


print("Weekly Gitea Backup Script", file=ml)
print("="*40, file=ml)


# Set log and backup locations

weekly_prefix = "backups/weekly"

# Log location:
weekly_log_dir = join(log_dir,weekly_prefix)

# Weekly backup location:
weekly_backup_dir = join(backup_dir,weekly_prefix)

# Get date for weekly backup target 
today_prefix = "gitea_"+today

# Weekly backup target: gitea_YYYY-MM-DD
# (gitea backup takes a directory name)
today_target = join(weekly_backup_dir,today_prefix)
backuptarget = today_target

# Weekly log target: wikidb_YYYY-MM-DD.log
today_log_target = join(weekly_log_dir,today_prefix+".log")
logtarget = today_log_target

# Backup utilities location
backuputil = join(utils_location,"backup_gitea.sh")

print("", file=ml)
print("\tbackup utility: %s"%(backuputil), file=ml)
print("\tbackup target: %s"%(backuptarget), file=ml)
print("\tlog file: %s"%(logtarget), file=ml)
print("", file=ml)



# Back up gitea

# make today's backup target dir
mkprocess = subprocess.call(["mkdir","-p",today_target])
mkprocess = subprocess.call(["mkdir","-p",daily_log_dir])

# do the task:
print("\tCreating gitea backup...", file=ml)
backupproc = subprocess.Popen([backuputil,backuptarget], shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

ll = open(logtarget,'w')

print("="*40,file=ll)
print("\n",file=ll)
print("STDOUT\n",file=ll)
print(backupproc.stdout.read(),file=ll)
print("\n",file=ll)

print("="*40,file=ll)
print("\n",file=ll)
print("STDERR\n",file=ll)
print(backupproc.stderr.read(),file=ll)
print("\n",file=ll)

ll.close()

print("\tSuccess!", file=ml)
print("", file=ml)



# Clear out old backups

print("\tRemoving weekly backups > 8 weeks old...", file=ml)

eightweeks = 8 * 7 * 24 * 3600 # seconds in 8 weeks

now = time.time()
for f in os.listdir(weekly_backup_dir):
    if('gitea' in f):
        f = join(weekly_backup_dir,f)
        eightweeksago = now - eightweeks
        if os.path.getctime(f) < weightweeksago:
            print("\t\tRemoving directory: %s"%(f), file=ml)
            rmcmd = ["/bin/rm","-rf",f]
            rmproc = subprocess.Popen(rmcmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

            ll = open(logtarget,'w')
            
            print("="*40,file=ll)
            print("rm command: %s"%(" ".join(rmcmd)))
            print("-"*40,file=ll)
            print("\n",file=ll)
            print("STDOUT\n",file=ll)
            print(rmproc.stdout.read(),file=ll)
            print("\n",file=ll)

            print("-"*40,file=ll)
            print("\n",file=ll)
            print("STDERR\n",file=ll)
            print(rmproc.stderr.read(),file=ll)
            print("\n",file=ll)
            
            ll.close()

        else:
            print("\t\tNot touching directory: %s"%(f), file=ml)



# Check if last week's backup was in a prior month 

print("\tChecking if we need to create monthly backup from last month's data...", file=ml)

sevendays = 7 * 24 * 3600 # seconds in 7 days

now = time.time()
sevendaysago = now - sevendays

d1 = datetime.utcfromtimestamp(now)
d2 = datetime.utcfromtimestamp(sevendaysago)

if(abs(d2.month - d1.month)>0):
    print("\t\tYes. Yes we do.")

    old_date = d2.strftime("%Y-%m-%d")
    old_prefix = "gitea_"+old_date
    old_dumptarget = join(weekly_backup_dir,old_prefix)

    monthly_date = d2.strftime("%Y-%m-%d")
    monthly_prefix = "gitea_"+monthly_date
    monthly_dumptarget = join(monthly_backup_dir,monthly_prefix)

    cpcmd = ["/bin/cp",old_dumptarget,monthly_dumptarget]
    cpproc = subprocess.Popen(cpcmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    print("="*40,file=ll)
    print("cp command: %s"%(" ".join(cpcmd)))
    print("-"*40,file=ll)
    print("\n",file=ll)
    print("STDOUT\n",file=ll)
    print(cpproc.stdout.read(),file=ll)
    print("\n",file=ll)

    print("-"*40,file=ll)
    print("\n",file=ll)
    print("STDERR\n",file=ll)
    print(cpproc.stderr.read(),file=ll)
    print("\n",file=ll)

    ll.close()

else:
    print("\t\tNope. We do not.")

ml.close()

