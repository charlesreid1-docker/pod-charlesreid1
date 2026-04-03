# Plan: Stop MediaWiki from Connecting to MySQL as Root

## Overview

MediaWiki currently connects to MySQL as `root`. We will create a dedicated
`wikiuser` account with permissions only on `wikidb`, then switch MediaWiki to
use it. Backup scripts will continue to use root (they need it for `mysqldump`).

**Affected files:**

| File | Change |
|------|--------|
| `docker-compose.yml.j2` | Add `MYSQL_USER`/`MYSQL_PASSWORD` for wikiuser on MySQL container; change MW container to use wikiuser |
| `environment.j2` | Add new `POD_CHARLESREID1_MYSQL_WIKIUSER_PASSWORD` export |
| `environment.example` | Add example for the new variable |
| `scripts/apply_templates.py` | Add new Jinja2-to-env mapping |

**Not changed:**

| File | Why |
|------|-----|
| `scripts/backups/wikidb_dump.sh` | Backup must use root; it already reads `MYSQL_ROOT_PASSWORD` from the container env, which remains unchanged |
| `scripts/mysql/restore_database.sh` | Already broken (references deleted `.mysql.rootpw.cnf`); separate fix needed |
| `d-mediawiki/charlesreid1-config/mediawiki/LocalSettings.php.j2` | Already reads `MYSQL_USER` / `MYSQL_PASSWORD` from env; no change needed |

---

## Pre-flight checks (run these BEFORE making any changes)

All commands assume you are on the host that runs the pod, in the
`pod-charlesreid1` directory, and that the pod is running.

### 1. Confirm the pod is healthy

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

You should see `stormy_mysql`, `stormy_mw`, `stormy_nginx`, `stormy_gitea` all
`Up`.

### 2. Confirm you can connect to MySQL as root inside the container

```bash
docker exec -t stormy_mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1"'
```

Expected output: a table with `1`.

### 3. Verify the `wikidb` database exists and note its tables

```bash
docker exec -t stormy_mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW TABLES" wikidb' | head -20
```

### 4. Take a fresh backup (safety net)

```bash
source ./environment
bash ./scripts/backups/wikidb_dump.sh
```

Confirm the backup file exists and is non-empty:

```bash
ls -lh ${POD_CHARLESREID1_BACKUP_DIR}/$(date +%Y%m%d)/wikidb_*.sql
```

---

## Phase 1: Create the MySQL user inside the running container

This phase requires **zero downtime**. We create the user while everything is
running. MediaWiki continues using root throughout this phase.

### Step 1.1: Choose a password for `wikiuser`

Generate a strong random password:

```bash
openssl rand -base64 24
```

Save this value. You will need to export it as
`POD_CHARLESREID1_MYSQL_WIKIUSER_PASSWORD` later.

### Step 1.2: Create the user and grant permissions

Replace `<WIKIUSER_PASSWORD>` with the password from Step 1.1:

```bash
docker exec -t stormy_mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
  CREATE USER IF NOT EXISTS '"'"'wikiuser'"'"'@'"'"'%'"'"' IDENTIFIED BY '"'"'<WIKIUSER_PASSWORD>'"'"';
  GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON wikidb.* TO '"'"'wikiuser'"'"'@'"'"'%'"'"';
  FLUSH PRIVILEGES;
"'
```

**Why these grants?** MediaWiki needs:
- `SELECT, INSERT, UPDATE, DELETE` -- normal read/write operations
- `CREATE, DROP, INDEX, ALTER` -- for schema migrations during upgrades (`update.php`)
- `CREATE TEMPORARY TABLES` -- used by some MW queries
- `LOCK TABLES` -- used by maintenance scripts and `update.php`

This is strictly scoped to `wikidb.*` -- no access to `mysql.*`, `information_schema`, or any other database.

### Step 1.3: Verify the new user can connect and read wikidb

```bash
docker exec -t stormy_mysql sh -c 'exec mysql -uwikiuser -p"<WIKIUSER_PASSWORD>" -e "SELECT COUNT(*) FROM page" wikidb'
```

Expected: a number (the count of wiki pages). If this fails, the user was not
created correctly -- go back to Step 1.2.

### Step 1.4: Verify the new user CANNOT access other databases

```bash
docker exec -t stormy_mysql sh -c 'exec mysql -uwikiuser -p"<WIKIUSER_PASSWORD>" -e "SHOW DATABASES"'
```

Expected output should show only:

```
+--------------------+
| Database           |
+--------------------+
| information_schema |
| wikidb             |
+--------------------+
```

If you see `mysql`, `performance_schema`, or others, the grants are too broad.
Run `REVOKE ALL PRIVILEGES ON *.* FROM 'wikiuser'@'%'; FLUSH PRIVILEGES;` and
redo Step 1.2.

### Step 1.5: Verify the new user can write

```bash
docker exec -t stormy_mysql sh -c 'exec mysql -uwikiuser -p"<WIKIUSER_PASSWORD>" -e "
  CREATE TABLE wikidb._test_write (id INT);
  DROP TABLE wikidb._test_write;
"'
```

No errors = success.

---

## Phase 2: Update template files (on your local dev machine or on the host)

These are the code changes to commit and push.

### Step 2.1: Export the new environment variable

On the host, add to your shell environment (e.g., `.bashrc` or wherever you
keep pod secrets):

```bash
export POD_CHARLESREID1_MYSQL_WIKIUSER_PASSWORD="<WIKIUSER_PASSWORD>"
```

### Step 2.2: Edit `scripts/apply_templates.py`

Add the new mapping to the `jinja_to_env` dictionary:

```python
"pod_charlesreid1_mysql_wikiuser_password": "POD_CHARLESREID1_MYSQL_WIKIUSER_PASSWORD",
```

### Step 2.3: Edit `environment.j2`

Add the new export:

```bash
export POD_CHARLESREID1_MYSQL_WIKIUSER_PASSWORD="{{ pod_charlesreid1_mysql_wikiuser_password }}"
```

### Step 2.4: Edit `environment.example`

Add an example value:

```bash
export POD_CHARLESREID1_MYSQL_WIKIUSER_PASSWORD="AnotherSecretPassword"
```

### Step 2.5: Edit `docker-compose.yml.j2`

**MySQL container** -- add env vars so the user is auto-created on fresh
deployments (won't affect existing volumes, but documents intent):

```yaml
  stormy_mysql:
    build: d-mysql
    container_name: stormy_mysql
    volumes:
      - "stormy_mysql_data:/var/lib/mysql"
      - "./d-mysql/conf.d:/etc/mysql/conf.d:ro"
    logging:
      driver: "json-file"
      options:
        max-size: 1m
        max-file: "10"
    environment:
      - MYSQL_ROOT_PASSWORD={{ pod_charlesreid1_mysql_password }}
      - MYSQL_DATABASE=wikidb
      - MYSQL_USER=wikiuser
      - MYSQL_PASSWORD={{ pod_charlesreid1_mysql_wikiuser_password }}
```

**MediaWiki container** -- switch from root to wikiuser:

```yaml
    environment:
      - MEDIAWIKI_SITE_SERVER=https://{{ pod_charlesreid1_server_name }}
      - MEDIAWIKI_SECRETKEY={{ pod_charlesreid1_mediawiki_secretkey }}
      - MEDIAWIKI_UPGRADEKEY={{ pod_charlesreid1_mediawiki_upgradekey }}
      - MYSQL_HOST=stormy_mysql
      - MYSQL_DATABASE=wikidb
      - MYSQL_USER=wikiuser
      - MYSQL_PASSWORD={{ pod_charlesreid1_mysql_wikiuser_password }}
```

Note: `MYSQL_PASSWORD` now uses the **wikiuser password**, not the root
password. Root password stays only on the MySQL container.

### Step 2.6: Re-render templates

```bash
source ./environment  # (or wherever you export the new var)
make templates
```

### Step 2.7: Verify the rendered `docker-compose.yml`

```bash
grep -A5 'MYSQL_USER' docker-compose.yml
```

Confirm it shows `wikiuser`, not `root`.

---

## Phase 3: Switchover (brief downtime)

This is the only phase with downtime. It should take under 60 seconds.

### Step 3.1: Restart only the MediaWiki container

We only need to restart `stormy_mw` to pick up the new environment variables.
MySQL stays running -- no data risk.

```bash
docker-compose up -d --no-deps --build stormy_mw
```

`--no-deps` prevents MySQL from being restarted. `--build` rebuilds the image
if the Dockerfile changed (it didn't, but it's a safe habit).

### Step 3.2: Verify MediaWiki is working

Wait a few seconds, then:

```bash
# Check the container is running
docker ps --filter name=stormy_mw --format "{{.Status}}"

# Hit the wiki and check for a 200 response
curl -s -o /dev/null -w "%{http_code}" http://localhost:8989/wiki/Main_Page
```

(Adjust the port/URL to match your nginx config. If nginx proxies to MW, test
through nginx instead:)

```bash
curl -s -o /dev/null -w "%{http_code}" https://charlesreid1.com/wiki/Main_Page
```

Expected: `200`.

### Step 3.3: Check MediaWiki logs for database errors

```bash
docker logs stormy_mw --tail 50 --since 2m
```

Look for any `Access denied` or `Connection refused` errors. If you see them,
proceed to the Rollback section below.

### Step 3.4: Verify backups still work

```bash
source ./environment
bash ./scripts/backups/wikidb_dump.sh
```

Backups use `MYSQL_ROOT_PASSWORD` from inside the MySQL container, which has not
changed. This should work exactly as before.

---

## Phase 4: Post-switchover verification

### Step 4.1: Confirm MediaWiki can read (browse the wiki)

Open your browser and navigate to a few wiki pages. Confirm content loads.

### Step 4.2: Confirm MediaWiki can write (make an edit)

Edit a wiki page (even a trivial whitespace change) and save. Confirm the edit
is saved and appears in Recent Changes.

### Step 4.3: Confirm the root user still works (for admin tasks)

```bash
docker exec -t stormy_mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1"'
```

### Step 4.4: Confirm wikiuser cannot see other databases

```bash
docker exec -t stormy_mysql sh -c 'exec mysql -uwikiuser -p"<WIKIUSER_PASSWORD>" -e "SHOW DATABASES"'
```

Should only show `information_schema` and `wikidb`.

---

## Rollback procedure

If anything goes wrong after the switchover, revert MediaWiki to root access in
under 30 seconds:

### Quick rollback (no code change needed)

```bash
# Stop MW
docker-compose stop stormy_mw

# Edit the rendered docker-compose.yml directly (not the .j2 template):
# Change MYSQL_USER=wikiuser back to MYSQL_USER=root
# Change MYSQL_PASSWORD=<wikiuser_password> back to MYSQL_PASSWORD=<root_password>
sed -i.bak \
  -e 's/MYSQL_USER=wikiuser/MYSQL_USER=root/' \
  docker-compose.yml

# You also need to fix the password -- find the wikiuser password line and
# replace it with the root password. Check the MYSQL_ROOT_PASSWORD line on
# the stormy_mysql container for the correct value.

# Restart MW
docker-compose up -d --no-deps stormy_mw
```

### Full rollback (revert code changes)

```bash
git checkout -- docker-compose.yml.j2 environment.j2 environment.example scripts/apply_templates.py
make templates
docker-compose up -d --no-deps stormy_mw
```

The `wikiuser` MySQL account can be left in place; it does no harm. To remove it:

```bash
docker exec -t stormy_mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP USER IF EXISTS '"'"'wikiuser'"'"'@'"'"'%'"'"'; FLUSH PRIVILEGES;"'
```

---

## Notes

- **Why not change the backup scripts?** `mysqldump` with `--databases` needs
  broader permissions than a restricted user has. Keeping backups on root is
  fine because the backup script runs on the host (via systemd), not inside the
  MW container.

- **Why `wikiuser@'%'` instead of `wikiuser@'stormy_mw'`?** Docker Compose
  networking uses dynamic IPs. The `%` wildcard matches any host within the
  Docker network. Since MySQL is not exposed to the host network, this is safe.

- **Fresh deployments:** With `MYSQL_DATABASE`, `MYSQL_USER`, and
  `MYSQL_PASSWORD` set on the MySQL container, the official MySQL image will
  auto-create the user and database on first init (empty volume). This means
  new deployments won't need the manual Phase 1 steps.

- **The restore script is broken independently:** `restore_database.sh`
  references `/root/.mysql.rootpw.cnf` which was removed in commit `940e21f`.
  That's a separate fix (tracked as a different issue).
