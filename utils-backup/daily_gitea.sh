#!/bin/bash
#
# Just make a daily MediaWiki files backup.
set -x

stamp="`date +"%Y-%m-%d"`"
backup_tool="${HOME}/codes/docker/pod-charlesreid1/utils-gitea/backup_gitea.sh"

backup_dir="/junkinthetrunk/backups/daily/gitea_${stamp}"
backup_target="${backup_dir}"

log_dir="${HOME}/.logs/backups/daily"
log_target="${log_dir}/gitea_${stamp}.log"

mkdir -p ${backup_dir}
mkdir -p ${log_dir}
cat /dev/null > ${log_target}

echo "================================" >> ${log_target}
echo "=== Daily Gitea Files Backup ===" >> ${log_target}
echo "================================" >> ${log_target}
echo ""                                 >> ${log_target}
echo "Backup Utility: ${backup_tool}"   >> ${log_target}
echo "Backup Target: ${backup_target}"  >> ${log_target}
echo "Log Target: ${log_target}"        >> ${log_target}
echo ""                                 >> ${log_target}
echo "Command: ${backup_tool} ${backup_target} 2>&1 ${log_target}" >> ${log_target}
echo "" >> ${log_target}

${backup_tool} ${backup_target} 2>&1 ${log_target}

echo "Done" >> ${log_target}

