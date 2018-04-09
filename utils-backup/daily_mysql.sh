#!/bin/bash
#
# Just make a daily MySQL backup.

stamp=$(date +"%Y-%m-%d")

backup_tool="${HOME}/codes/docker/pod-charlesreid1/utils-mysql/dump_database.sh"

backup_dir="/junkinthetrunk/backups/daily/wikidb_${stamp}"
backup_target="${backup_dir}/wikidb.sql"

log_dir="${HOME}/.logs/backups/daily"
log_target="${log_dir}/wikidb_${stamp}.log"

mkdir -p ${backup_dir}
mkdir -p ${log_dir}
cat /dev/null > ${log_target}

echo "=======================================" >> ${log_target}
echo "=== Daily MediaWiki Database Backup ===" >> ${log_target}
echo "=======================================" >> ${log_target}
echo ""                                        >> ${log_target}
echo "Backup Utility: ${backup_tool}"          >> ${log_target}
echo "Backup Target: ${backup_target}"         >> ${log_target}
echo "Log Target: ${log_target}"               >> ${log_target}
echo ""                                        >> ${log_target}
echo "Command: ${backup_tool} ${backup_target} 2>&1 ${log_target}" >> ${log_target}
echo "" >> ${log_target}

${backup_tool} ${backup_target} 2>&1 ${log_target}

echo "Done" >> ${log_target}

