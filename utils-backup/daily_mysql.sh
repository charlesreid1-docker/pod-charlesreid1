#!/bin/bash
#
# Just make a daily MySQL backup.

stamp=$(date +"%Y-%m-%d")

backup_tool="${HOME}/codes/docker/pod-charlesreid1/utils-mysql/dump_database.sh"

backup_dir="/junkinthetrunk/backups/daily/wikidb_${stamp}"
backup_target="${backup_dir}/wikidb_${stamp}.sql"

log_dir="${HOME}/.logs/backups/daily"
log_target="${log_dir}/wikidb_${stamp}.log"

mkdir -p ${backup_dir}
mkdir -p ${log_dir}
cat /dev/null > ${log_target}

echo "=======================================" | tee ${log_target}
echo "=== MediaWiki Database Backup =========" | tee ${log_target}
echo "=======================================" | tee ${log_target}
echo ""                                        | tee ${log_target}
echo "Backup Utility: ${backup_tool}"          | tee ${log_target}
echo "Backup Target: ${backup_target}"         | tee ${log_target}
echo "Log Target: ${log_target}"               | tee ${log_target}
echo ""                                        | tee ${log_target}

set -x
${backup_tool} ${backup_target} >> ${log_target} 2>&1
set +x

echo "Done" | tee ${log_target}

