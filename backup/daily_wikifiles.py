#!/usr/bin/env python
import os
import subprocess
import time
import datetime as dt
from os.path import join

"""
Daily Wiki Files Backups



Short Description:

Keep a rolling 7-day backup of wiki files.



Long Description:

This backs up the wiki files to 

    <backup-dir>/backups/daily/

It creates one directory per daily backup,
containing a tar file containing the files:

    <backup-dir>/backups/daily/wikifiles_YYYY-MM-DD/wikifiles.tar.gz

Output from backup commands is logged to:

    <log-dir>/backups/daily/

One log per daily backup:

    <log-dir>/backups/daily/wikifiles_YYYY-MM-DD.log



Logging:

This daily_wikifiles.py cron job logs to its own log file,

    <log-dir>/cron/daily_wikifiles_YYYY-MM-DD.log

The output of the commands run by this script are in:

    <log-dir>/backups/daily/wikifiles_YYYY-MM-DD.log

"""

home = os.environ['HOME']

utils_location = join(home,"/codes/docker/pod-charlesreid1/utils-mw")

temp = "/temp"
log_dir = join(home,".logs")


# -----------------------------------


today = dt.date.today().strftime("%Y-%m-%d")

# Meta-logging: set up log file for daily_wikifiles.py
daily_log = "daily_wikifiles_"+today+".log"
cron_log_dir = join(log_dir,"cron")
meta_log = join(cron_log_dir,daily_log)

# Make log dir
subprocess.call(["mkdir","-p",cron_log_dir])

ml = open(meta_log,'w')


print("Daily Wikifiles Backup Script", file=ml)
print("="*40, file=ml)


# Set log and backup locations

daily_prefix = "backups/daily"

# Log location:
daily_log_dir = join(log_dir,daily_prefix)

# Daily backup location:
daily_backup_dir = join(backup_dir,daily_prefix)

# Get date for daily backup target 
today_prefix = "wikifiles_"+today

# Daily backup target: wikidb_YYYY-MM-DD
today_target = join(daily_backup_dir,today_prefix)
backupfile = "wikifiles.tar.gz"
backuptarget = join(today_target,backupfile)

# Daily log target: wikidb_YYYY-MM-DD.log
today_log_target = join(daily_log_dir,today_prefix+".log")
logtarget = today_log_target

# Backup utilities location
backuputil = join(utils_location,"backup_wikifiles.sh")

print("", file=ml)
print("\tbackup utility: %s"%(backuputil), file=ml)
print("\tbackup target: %s"%(backuptarget), file=ml)
print("\tlog file: %s"%(logtarget), file=ml)
print("", file=ml)



# Back up mysql

# Make today's backup target dir
subprocess.call(["mkdir","-p",today_target])
subprocess.call(["mkdir","-p",daily_log_dir])

# Do the task:
print("\tCompressing wikifiles...", file=ml)
backupproc = subprocess.Popen([backuputil,backuptarget], shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

ll = open(logtarget,'w')

print("="*40,file=ll)
print("backup command: %s"%(" ".join([backuputil,backuptarget])))
print("-"*40,file=ll)
print("\n",file=ll)
print("STDOUT\n",file=ll)
print(backupproc.stdout.read(),file=ll)
print("\n",file=ll)

print("-"*40,file=ll)
print("\n",file=ll)
print("STDERR\n",file=ll)
print(backupproc.stderr.read(),file=ll)
print("\n",file=ll)

ll.close()

print("\tSuccess!", file=ml)
print("", file=ml)



# Clear out old backups

print("\tRemoving daily backups > 7 days old...", file=ml)

sevendays = 7 * 24 * 3600 # seconds in 7 days
now = time.time()
for f in os.listdir(daily_backup_dir):
    if('wikifiles' in f):
        f = join(daily_backup_dir,f)
        sevendaysago = now - sevendays
        if os.path.getctime(f) < sevendaysago:
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

ml.close()


