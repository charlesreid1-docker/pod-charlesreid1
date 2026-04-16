# Upgrade Plan: MediaWiki 1.34 → 1.39+ and MySQL 5.7 → 8.0

## Context

MediaWiki 1.34 (EOL Nov 2021) and MySQL 5.7 (EOL Oct 2023) are both end-of-life and no longer receive security patches. The goal is to upgrade both with **minimal downtime** by running old and new versions side-by-side, testing the new stack, then switching over — with the ability to roll back instantly.

**Additional motivation:** The REST API v1 endpoint `/w/rest.php/v1/page/{title}/with_html` returns a 500 error ("Unable to fetch Parsoid HTML") because MW 1.34 does not bundle Parsoid. MW 1.39 bundles Parsoid in-process, which is required for this endpoint to work. This blocks tools (e.g., MediaWiki MCP) that rely on the REST API to fetch rendered HTML.

## Strategy: Blue-Green Deployment

Run the old stack ("blue") untouched while building and testing the new stack ("green") alongside it. Nginx acts as the switch — changing one `proxy_pass` line flips between old and new.

```
                          ┌─ stormy_mw (MW 1.34) ──── stormy_mysql (MySQL 5.7)     ← BLUE (old)
nginx ── proxy_pass ──────┤
                          └─ stormy_mw_new (MW 1.39) ─ stormy_mysql_new (MySQL 8)  ← GREEN (new)
```

Both stacks use **separate volumes** — the old data is never touched.

---

## Decisions (Locked In)

- **Target:** MediaWiki 1.39 LTS (smallest jump from 1.34, can do 1.39→1.42 later)
- **Skin:** Patch Bootstrap2 to replace deprecated API calls for MW 1.39 compatibility
- **EmbedVideo:** Skip for now — don't include in green stack. Add back later if needed.
- **Extensions in green stack:** SyntaxHighlight_GeSHi, ParserFunctions, Math (all have REL1_39 branches)

---

## Phase 1: Preparation (no downtime)

All work happens on the VPS alongside the running production stack.

### 1.1 Full backup
```bash
# Database dump
make backups
# or manually:
./scripts/backups/wikidb_dump.sh

# Also back up the MW volume (uploaded images, cache)
docker run --rm -v stormy_mw_data:/data -v /tmp/mw_backup:/backup \
  alpine tar czf /backup/mw_data_backup.tar.gz -C /data .
```

### 1.2 Create new Dockerfiles

**`d-mediawiki-new/Dockerfile`** — based on `mediawiki:1.39`
- Same structure as current Dockerfile
- Update extension COPY paths for new versions
- Update apt packages if needed (texlive, imagemagick still required)
- Apache config stays the same (port 8989)

**`d-mysql-new/Dockerfile`** — based on `mysql:8.0`
- Same structure as current
- Keep slow-log config (syntax compatible with 8.0)

### 1.3 Update extensions for target MW version

Create `scripts/mw/build_extensions_dir_139.sh` to clone REL1_39 branches:

| Extension | Current | New |
|-----------|---------|-----|
| SyntaxHighlight_GeSHi | REL1_34 | REL1_39 |
| ParserFunctions | REL1_34 | REL1_39 |
| Math | REL1_34 | REL1_39 |
| EmbedVideo | v2.7.3 | **Skipped** (add back later) |

### 1.4 Patch Bootstrap2 skin

Replace deprecated calls in `skins/Bootstrap2/`:
- `wfRunHooks('hook', ...)` → `Hooks::run('hook', ...)`  (MW 1.35+)
- `wfMsg('key')` → `wfMessage('key')->text()`
- `wfEmptyMsg('key')` → `wfMessage('key')->isDisabled()`

### 1.5 Update LocalSettings.php.j2 (new copy for green stack)

Changes needed for MW 1.39:
- `require_once "$IP/extensions/Math/Math.php"` → `wfLoadExtension( 'Math' )`
- `$wgDBmysql5 = true;` — remove (deprecated in 1.39)
- Remove `wfLoadExtension( 'EmbedVideo' )` (skipped for now)
- Review other deprecated settings
- Add Parsoid configuration (bundled in MW 1.39, runs in-process — no separate container needed):
  ```php
  # Parsoid (required for REST API with_html endpoint)
  wfLoadExtension( 'Parsoid', "$IP/vendor/wikimedia/parsoid/extension.json" );
  $wgParsoidSettings = [
      'useSelser' => true,
  ];
  ```

---

## Phase 2: Build Green Stack (no downtime)

### 2.1 Add new services to docker-compose.yml.j2

```yaml
  stormy_mysql_new:
    restart: always
    build: d-mysql-new
    container_name: stormy_mysql_new
    volumes:
      - "stormy_mysql_new_data:/var/lib/mysql"
      - "./d-mysql/conf.d:/etc/mysql/conf.d:ro"
    environment:
      - MYSQL_ROOT_PASSWORD={{ pod_charlesreid1_mysql_password }}
    networks:
      - backend_new

  stormy_mw_new:
    restart: always
    build: d-mediawiki-new
    container_name: stormy_mw_new
    volumes:
      - "stormy_mw_new_data:/var/www/html"
    environment:
      - MEDIAWIKI_SITE_SERVER=https://{{ pod_charlesreid1_server_name }}
      - MEDIAWIKI_SECRETKEY={{ pod_charlesreid1_mediawiki_secretkey }}
      - MEDIAWIKI_UPGRADEKEY={{ pod_charlesreid1_mediawiki_upgradekey }}
      - MYSQL_HOST=stormy_mysql_new
      - MYSQL_DATABASE=wikidb
      - MYSQL_USER=root
      - MYSQL_PASSWORD={{ pod_charlesreid1_mysql_password }}
    depends_on:
      - stormy_mysql_new
    networks:
      - frontend
      - backend_new
```

Add `stormy_mysql_new_data`, `stormy_mw_new_data` to volumes, `backend_new` to networks.

### 2.2 Build and start green containers

```bash
docker compose build stormy_mysql_new stormy_mw_new
docker compose up -d stormy_mysql_new stormy_mw_new
```

Old containers keep running — no disruption.

### 2.3 Migrate database to new MySQL 8.0

```bash
# Dump from old MySQL 5.7
docker exec stormy_mysql sh -c \
  'mysqldump wikidb --databases -uroot -p"$MYSQL_ROOT_PASSWORD" --default-character-set=binary' \
  > /tmp/wikidb_for_upgrade.sql

# Load into new MySQL 8.0
docker exec -i stormy_mysql_new sh -c \
  'mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' \
  < /tmp/wikidb_for_upgrade.sql
```

### 2.4 Migrate MW uploaded files

```bash
# Copy images/uploads from old volume to new volume
docker run --rm \
  -v stormy_mw_data:/old:ro \
  -v stormy_mw_new_data:/new \
  alpine sh -c 'cp -a /old/images/. /new/images/ 2>/dev/null; echo done'
```

### 2.5 Run MediaWiki database upgrade

```bash
docker exec stormy_mw_new php /var/www/html/maintenance/update.php --quick
```

This migrates the DB schema from MW 1.34 → 1.39 format.

---

## Phase 3: Test Green Stack (no downtime)

### 3.1 Direct browser test

Temporarily expose the new MW on a different port for testing:

```yaml
  stormy_mw_new:
    ports:
      - "8990:8989"  # temporary, for direct testing
```

Visit `http://<vps-ip>:8990` to verify MW loads, pages render, login works.

### 3.2 Test via nginx (brief switchover)

Edit nginx config to point `/wiki/` and `/w/` at `stormy_mw_new:8989`:

```nginx
proxy_pass http://stormy_mw_new:8989/wiki/;
```

```bash
docker exec stormy_nginx nginx -s reload
```

Test the live site. If broken, switch back:

```nginx
proxy_pass http://stormy_mw:8989/wiki/;
```

```bash
docker exec stormy_nginx nginx -s reload
```

**Switchover and rollback each take ~2 seconds** (nginx reload, no container restart).

### 3.3 Test checklist

- [ ] Wiki pages render correctly
- [ ] Bootstrap2 skin displays properly
- [ ] Login works
- [ ] Math equations render
- [ ] Syntax highlighting works
- [ ] Image uploads work
- [ ] File downloads work
- [ ] Edit pages (as sysop)
- [ ] Search works
- [ ] Special pages load
- [ ] REST API: `curl -s -o /dev/null -w '%{http_code}' https://wiki.golly.life/w/rest.php/v1/page/Main_Page/with_html` returns `200`
- [ ] REST API: response contains rendered HTML (not "Unable to fetch Parsoid HTML")
- [ ] MediaWiki MCP tool can fetch pages without 500 errors

---

## Phase 4: Switchover (~2 seconds downtime)

Once testing passes:

### 4.1 Final data sync

Right before switchover, re-dump and re-load the database to capture any edits made since Phase 2:

```bash
# Fresh dump
docker exec stormy_mysql sh -c \
  'mysqldump wikidb --databases -uroot -p"$MYSQL_ROOT_PASSWORD" --default-character-set=binary' \
  > /tmp/wikidb_final.sql

# Load into new
docker exec -i stormy_mysql_new sh -c \
  'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE wikidb; CREATE DATABASE wikidb;"'
docker exec -i stormy_mysql_new sh -c \
  'mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < /tmp/wikidb_final.sql

# Re-run schema upgrade
docker exec stormy_mw_new php /var/www/html/maintenance/update.php --quick
```

### 4.2 Switch nginx

Update proxy_pass in nginx config, reload. **This is the only moment of downtime.**

### 4.3 Stop old containers (optional, can defer)

```bash
docker compose stop stormy_mysql stormy_mw
```

Keep volumes intact for rollback.

---

## Phase 5: Rollback (if needed)

At any point after switchover:

```bash
# Point nginx back to old containers
# (edit proxy_pass back to stormy_mw:8989)
docker compose start stormy_mysql stormy_mw
docker exec stormy_nginx nginx -s reload
```

Old containers + old volumes are untouched. Rollback is instant.

**Keep old containers and volumes for at least 2 weeks** before removing.

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `d-mediawiki-new/Dockerfile` | Create — based on `mediawiki:1.39` |
| `d-mediawiki-new/charlesreid1-config/` | Create — copy from d-mediawiki, update extensions |
| `d-mysql-new/Dockerfile` | Create — based on `mysql:8.0` |
| `docker-compose.yml.j2` | Add green stack services, volumes, network |
| `d-nginx-charlesreid1/conf.d/https.DOMAIN.conf.j2` | Switchover: change proxy_pass targets |
| `scripts/mw/build_extensions_dir_139.sh` | Create — clone REL1_39 branches |
| `d-mediawiki-new/charlesreid1-config/mediawiki/LocalSettings.php.j2` | Update for MW 1.39 compat |
| `d-mediawiki-new/charlesreid1-config/mediawiki/skins/Bootstrap2/` | Patch deprecated API calls |

---

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Bootstrap2 skin breaks on MW 1.39 | MEDIUM | Patching deprecated calls; have Vector as fallback |
| Math extension rendering changes | LOW | REL1_39 branch exists; test rendering |
| MySQL 8 query compatibility | LOW | MW 1.39 officially supports MySQL 8.0 |
| Uploaded images lost | NONE | Copied to new volume; old volume preserved |
| Database corruption on migration | LOW | Old DB untouched; dump/restore is safe |
| Pages using EmbedVideo break | LOW | Videos won't render but pages still load; add back later |

---

## Implementation Order

1. **Prepare** new Dockerfiles and extension builds (Phase 1)
2. **Build** green stack alongside production (Phase 2)
3. **Test** thoroughly (Phase 3)
4. **Switch** when confident (Phase 4)
5. **Clean up** old containers after 2 weeks (Phase 5)
