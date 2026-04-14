# Plan: Fix the Broken wikidb Backup Script

## Status

**BLOCKING:** The MySQL no-root-password migration (`MySqlNoRootPasswordPlan.md`)
is on hold until backups are working. We will not touch the database until we
have a verified, complete, restorable dump in hand.

## What we observed

On 2026-04-13 at 18:02 PDT we ran `scripts/backups/wikidb_dump.sh` as a
pre-flight safety net. After ~14 seconds the output file stopped growing at
459,628,206 bytes (~439 MB) and the script hung. After 6+ minutes:

- The `mysqldump` process inside `stormy_mysql` was still alive but in `S`
  (sleeping) state, using ~1% CPU.
- `SHOW PROCESSLIST` on MySQL showed **no** mysqldump connection — MySQL had
  already dropped it.
- The dump file ended mid-`INSERT`, mid-row, with **no** `-- Dump completed on …`
  trailer. The dump is unusable.

So: every "successful" run of this script may have been silently producing
truncated dumps. We do not know how long this has been broken or whether any
recent backup in `/home/charles/backups` or in S3 is restorable. **That is
question one.**

## Root cause hypothesis

`scripts/backups/wikidb_dump.sh` runs:

```bash
DOCKERX="${DOCKER} exec -t"
${DOCKERX} ${CONTAINER_NAME} sh -c 'exec mysqldump wikidb --databases -uroot -p"$MYSQL_ROOT_PASSWORD" --default-character-set=binary' > "${BACKUP_TARGET}"
```

The `-t` flag allocates a pseudo-TTY inside the container. Two problems with
that:

1. **PTY corrupts binary output.** A PTY translates `LF` → `CRLF` on output.
   `mysqldump --default-character-set=binary` writes raw `_binary` blobs that
   contain `\n` bytes; these get rewritten in transit, silently corrupting the
   dump even when it does complete.
2. **PTY buffers can deadlock on large streams.** PTYs have small kernel
   buffers (typically 4 KB). When the redirect target (`> file`) drains slower
   than mysqldump produces, or when MySQL hits `net_write_timeout` and closes
   the connection, mysqldump can end up sleeping on a PTY write that will
   never complete. That matches what we saw: MySQL connection gone, mysqldump
   alive but sleeping, file frozen at ~439 MB.

The script also strips the first line with `tail -n +2` to drop mysqldump's
"Using a password on the command line interface can be insecure" warning. The
warning goes to **stderr**, not stdout, so this `tail` is at best a no-op and
at worst silently deletes the first line of real SQL.

## Affected files

| File | Change |
|------|--------|
| `scripts/backups/wikidb_dump.sh` | Remove `-t`; switch auth to `MYSQL_PWD` env; remove broken `tail -n +2`; add completion-trailer check; add `--single-transaction --quick --routines --triggers --events` |
| `scripts/backups/wikidb_restore_test.sh` | **NEW** — restore the latest dump into a throwaway MySQL container and run sanity queries |
| `scripts/backups/README.md` *(if present)* | Document the restore-test command and integrity check |

We will not touch `scripts/mysql/restore_database.sh` here — it is broken
independently (references the deleted `.mysql.rootpw.cnf`) and is tracked
separately.

---

## Phase 0: Triage (do this first, before any changes)

### Step 0.1: Kill the hung mysqldump

```bash
docker exec stormy_mysql sh -c 'pkill -9 mysqldump || true'
# also kill the host-side docker exec wrapper if it is still around
pgrep -af 'docker exec.*mysqldump' || true
```

After this, confirm nothing is running:

```bash
docker exec stormy_mysql sh -c 'pgrep -a mysqldump || echo none'
```

### Step 0.2: Remove the truncated dump

```bash
rm -i /home/charles/backups/$(date +%Y%m%d)/wikidb_*.sql
```

### Step 0.3: Audit existing backups — are *any* of them complete?

We need to know whether we have a known-good dump anywhere. For each candidate
file, the last bytes should contain `-- Dump completed on`:

```bash
for f in $(find /home/charles/backups -name 'wikidb_*.sql' -mtime -30 | sort); do
  trailer=$(tail -c 200 "$f" | tr -d '\0' | grep -o 'Dump completed on[^"]*' || echo "MISSING")
  size=$(stat -c %s "$f")
  echo "$f  size=$size  trailer=$trailer"
done
```

Any file showing `MISSING` is truncated and **not a real backup**. Record the
results — we need to know whether the most recent good dump is from yesterday,
last week, or never.

### Step 0.4: Audit the S3 backups

```bash
source ./environment
aws s3 ls "s3://${POD_CHARLESREID1_BACKUP_S3BUCKET}/" --recursive | grep wikidb | tail -20
```

Pull the most recent one down to a scratch dir and trailer-check it the same
way as Step 0.3. **Do not assume it is good just because it exists.**

### Step 0.5: Decide whether to pause writes

If Step 0.3 + 0.4 show no recent good backup, consider whether to pause writes
to the wiki (read-only mode via `$wgReadOnly` in `LocalSettings.php`) until we
have one. This is a judgement call — if the most recent good backup is days old
but the wiki is low-traffic, the risk of leaving it writable while we fix the
script is low. Decide explicitly, do not just drift.

---

## Phase 1: Fix the script

### Step 1.1: Edit `scripts/backups/wikidb_dump.sh`

Replace the docker exec block with:

```bash
# Pass the password via env to avoid:
#  - the cmdline-password warning on stderr
#  - the password showing up in `ps` inside the container
# No `-t`: PTY corrupts binary dumps and can deadlock on large output.
docker exec -i \
  -e MYSQL_PWD \
  "${CONTAINER_NAME}" \
  sh -c 'exec mysqldump \
            --user=root \
            --single-transaction \
            --quick \
            --routines \
            --triggers \
            --events \
            --default-character-set=binary \
            --databases wikidb' \
  > "${BACKUP_TARGET}"
```

Notes on each flag:

- `-i` — keep stdin open (no PTY). This is the single most important change.
- `-e MYSQL_PWD` — forwards the host's `MYSQL_PWD` env var into the container
  for this one exec call. mysqldump reads `MYSQL_PWD` automatically. Set it on
  the host before invoking the script:
  ```bash
  export MYSQL_PWD="$(docker exec stormy_mysql printenv MYSQL_ROOT_PASSWORD)"
  ```
  We pull it from the container so we don't have to duplicate the secret on
  the host. The systemd unit / cron wrapper that runs this script will need
  the same line.
- `--single-transaction` — InnoDB-only consistent snapshot without table
  locks. wikidb is InnoDB. This is the standard recommendation for live MW
  databases.
- `--quick` — stream rows one at a time instead of buffering whole tables in
  RAM. Important for large `text` / `revision` tables.
- `--routines --triggers --events` — include stored programs. Cheap insurance.
- Removed `-uroot -p"$MYSQL_ROOT_PASSWORD"` from the inner sh -c, replaced
  with `--user=root` + `MYSQL_PWD`.

### Step 1.2: Remove the broken `tail -n +2` block

The "warning" it was trying to strip went to stderr, never stdout. The
existing code:

```bash
tail -n +2 "${BACKUP_TARGET}" > "${BACKUP_TARGET}.tmp"
mv "${BACKUP_TARGET}.tmp" "${BACKUP_TARGET}"
```

is silently deleting the first line of real SQL (typically the
`-- MySQL dump …` header comment). Delete the block entirely.

### Step 1.3: Add an integrity check

After the dump, before declaring success:

```bash
# A complete mysqldump always ends with `-- Dump completed on …`.
if ! tail -c 200 "${BACKUP_TARGET}" | grep -q 'Dump completed on'; then
  echo "ERROR: dump file ${BACKUP_TARGET} is missing the completion trailer." >&2
  echo "       mysqldump did not finish successfully." >&2
  exit 2
fi

# Sanity: file should be at least a few MB. Tune the floor as you like.
size=$(stat -c %s "${BACKUP_TARGET}")
if [ "${size}" -lt $((50 * 1024 * 1024)) ]; then
  echo "ERROR: dump file ${BACKUP_TARGET} is only ${size} bytes; suspicious." >&2
  exit 3
fi

echo "Dump OK: ${BACKUP_TARGET} (${size} bytes)"
```

`set -eux` is already at the top of the script, so any failed step exits
non-zero. Good — make sure whatever runs the script (systemd, cron) actually
notices that exit code and alerts.

---

## Phase 2: Verify the new script works

### Step 2.1: Run it

```bash
export MYSQL_PWD="$(docker exec stormy_mysql printenv MYSQL_ROOT_PASSWORD)"
source ./environment
bash ./scripts/backups/wikidb_dump.sh
```

Time it. On a healthy `--quick` stream, 400 MB of wikidb should take well
under a minute on local disk.

### Step 2.2: Verify the trailer

```bash
tail -c 200 /home/charles/backups/$(date +%Y%m%d)/wikidb_*.sql | tr -d '\0'
```

Must end with `-- Dump completed on YYYY-MM-DD HH:MM:SS`.

### Step 2.3: Verify the byte count is sane

It should be **larger** than the truncated 439 MB we saw earlier (because the
truncated file was missing the tail end of a table). Compare to the largest
recent S3 backup if you have one.

### Step 2.4: Spot-check the SQL

```bash
head -50 /home/charles/backups/$(date +%Y%m%d)/wikidb_*.sql
```

Should start with `-- MySQL dump …` (NOT with `CREATE TABLE` — if it starts
with `CREATE TABLE` then the dead `tail -n +2` is still there, eating the
header).

---

## Phase 3: Prove the dump is restorable

A backup is only a backup if you have actually restored from it. Until then
it is a file of unknown provenance.

### Step 3.1: Spin up a throwaway MySQL container

```bash
docker run -d --rm \
  --name wikidb_restore_test \
  -e MYSQL_ROOT_PASSWORD=temp_test_pw_$$ \
  mysql:5.7  # or whatever version stormy_mysql is — check with: docker inspect stormy_mysql --format '{{.Config.Image}}'
```

Wait for it to be ready:

```bash
until docker exec wikidb_restore_test sh -c 'mysqladmin -uroot -p"$MYSQL_ROOT_PASSWORD" ping' 2>/dev/null; do
  sleep 2
done
```

### Step 3.2: Pipe the dump in

```bash
docker exec -i wikidb_restore_test sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' \
  < /home/charles/backups/$(date +%Y%m%d)/wikidb_*.sql
```

Should complete with no errors.

### Step 3.3: Run sanity queries against the restored DB

```bash
docker exec wikidb_restore_test sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
  USE wikidb;
  SELECT COUNT(*) AS pages FROM page;
  SELECT COUNT(*) AS revisions FROM revision;
  SELECT COUNT(*) AS texts FROM text;
  SELECT MAX(rev_timestamp) AS most_recent_edit FROM revision;
"'
```

Compare those numbers to live `stormy_mysql`:

```bash
docker exec -i stormy_mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
  USE wikidb;
  SELECT COUNT(*) FROM page;
  SELECT COUNT(*) FROM revision;
  SELECT COUNT(*) FROM text;
  SELECT MAX(rev_timestamp) FROM revision;
"'
```

They should match (allowing for any edits between the dump time and the live
query).

### Step 3.4: Tear down

```bash
docker stop wikidb_restore_test
```

`--rm` removes it on stop. No leftover state.

### Step 3.5: Bake this into a script

Save the Phase 3 commands as `scripts/backups/wikidb_restore_test.sh` so we
can re-run it on demand. It should take a backup file path as its single
argument and exit non-zero on any mismatch.

---

## Phase 4: Verify the scheduled-backup path

Whatever runs `wikidb_dump.sh` on a schedule needs to:

1. Set `MYSQL_PWD` (or otherwise provide the password) before invoking.
2. Actually notice and alert on a non-zero exit.

### Step 4.1: Find the scheduler

```bash
systemctl list-timers --all | grep -i backup
ls /etc/systemd/system/ | grep -i backup
crontab -l
sudo crontab -l
```

### Step 4.2: Inspect whatever you find

Confirm it sources `./environment` (or otherwise gets `MYSQL_PWD`), runs the
script, and surfaces failures (slack canary webhook? email? exit-code check?
journalctl?). If the failure path is "we'd notice in the logs eventually,"
that is not a failure path.

### Step 4.3: Trigger the scheduled job manually and confirm a clean run

```bash
sudo systemctl start <whatever-the-unit-is>.service
journalctl -u <whatever-the-unit-is>.service --since "5 min ago"
```

The journal should show the "Dump OK" line from Step 1.3.

---

## Phase 5: Commit and unblock the MySQL work

### Step 5.1: Commit the script + new restore-test script

Branch, commit, push, PR. Reference this plan in the PR description.

### Step 5.2: Update `MySqlNoRootPasswordPlan.md` Step 4 (Take a fresh backup)

It should now point at the fixed script and the restore-test script — Phase 0
of the no-root-password plan should require **both** a successful dump AND a
successful restore-test before proceeding.

### Step 5.3: Resume the MySQL no-root-password migration

Only after Phase 3 above has passed at least once on a fresh dump.

---

## Rollback

There is nothing to roll back in Phase 0–3 — we are only modifying a script
and creating throwaway containers. If the new script doesn't work, the old
script is in git history (`git checkout -- scripts/backups/wikidb_dump.sh`)
and we are no worse off than we are right now (which is: backups are
broken).

---

## Notes / open questions

- **How long has this been broken?** Answer with Phase 0.3 + 0.4. If every
  recent dump is truncated, this has been broken since whenever the wiki grew
  past the first PTY-buffer-stall threshold. We should figure out an
  approximate date so we know what window of "we thought we had backups" was
  fictional.
- **Why no alert?** Phase 4 needs to answer this. A backup pipeline that can
  silently produce 439 MB of garbage for an unknown number of days is the
  real bug. The script fix is necessary but not sufficient.
- **Should we move off `mysqldump` entirely?** For a database this size,
  `mysqldump` is fine. Not worth re-architecting. The fix is one flag and
  one integrity check.
- **`docker exec -t` elsewhere in the repo?** Worth a grep — same bug pattern
  could exist in any other backup or maintenance script.
