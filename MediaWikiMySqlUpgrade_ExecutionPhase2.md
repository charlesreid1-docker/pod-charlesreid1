# MediaWiki/MySQL Upgrade — Phase 2 Execution Log

Executed: 2026-04-15

## Status

Phase 2 steps all complete per plan, but **green MW returns HTTP 500** on page render. Additional Bootstrap2 skin compatibility work is needed before Phase 3 can proceed. Production stack (blue) is untouched and serving normally.

## Done

- **2.0 REL1_39 extensions cloned** into `d-mediawiki-new/charlesreid1-config/mediawiki/extensions/`
  - SyntaxHighlight_GeSHi (REL1_39)
  - ParserFunctions (REL1_39)
  - Math (REL1_39)
  - Ran `scripts/mw/build_extensions_dir_139.sh`

- **2.1 `docker-compose.yml.j2` updated** with green services
  - Added `stormy_mysql_new` service (build: `d-mysql-new`, env `MYSQL_ROOT_PASSWORD`, network `backend_new`, volume `stormy_mysql_new_data`)
  - Added `stormy_mw_new` service (build: `d-mediawiki-new`, env pointing to `stormy_mysql_new` with root user, networks `frontend` + `backend_new`, volume `stormy_mw_new_data`)
  - Added `backend_new` network
  - Added `stormy_mysql_new_data`, `stormy_mw_new_data` volumes
  - Ran `make templates` to regenerate `docker-compose.yml`

- **2.2 Green containers built and started**
  - `docker compose build stormy_mysql_new stormy_mw_new` — built both images
  - `docker compose up -d stormy_mysql_new stormy_mw_new` — containers running
  - `stormy_mysql_new`: MySQL 8.0.45 accepting connections on 3306
  - `stormy_mw_new`: Apache/2.4.65 + PHP 8.3.29 running
  - Old containers (`stormy_mysql`, `stormy_mw`, `stormy_nginx`, `stormy_gitea`) still running untouched

- **2.3 Database migrated from MySQL 5.7 → MySQL 8.0**
  - **Deviation from plan:** Plan §2.3 says to re-dump via `docker exec stormy_mysql … mysqldump …`. My first attempt hit the exact bug documented in `PlanFixBackups.md` — dump truncated at 44 MB. Recognized the pattern and pivoted to using the fresh systemd-triggered backup taken in Phase 1 (`wikidb_20260415_040949.sql`, 578 MB, trailer verified).
  - Loaded it: `docker exec -i stormy_mysql_new sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < /home/charles/backups/20260415/wikidb_20260415_040949.sql`
  - **Row-count verification** (green vs production, identical match):
    | Table | Production | Green | Match |
    |---|---|---|---|
    | `page` | 4631 | 4631 | ✓ |
    | `revision` | 29237 | 29237 | ✓ |
    | `text` | 30081 | 30081 | ✓ |
    | `MAX(rev_timestamp)` | 20260415033800 | 20260415033800 | ✓ |

- **2.4 Uploaded images copied** from old volume to new volume
  - `docker run --rm -v pod-charlesreid1_stormy_mw_data:/old:ro -v pod-charlesreid1_stormy_mw_new_data:/new alpine cp -a /old/images /new/images`
  - Verified 1.6 GB in both volumes (identical)

- **2.5 MediaWiki schema upgrade (MW 1.34 → 1.39)**
  - `docker exec stormy_mw_new php /var/www/html/maintenance/update.php --quick`
  - Completed in 58 seconds with no errors
  - Migrated `templatelinks` (13579 rows backfilled), created `mathlatexml` table, dropped `tl_title`, many idempotent "already completed" entries from previous MW baseline

## Detours encountered

1. **Disk full at 100%** during the DB load — root partition `/dev/sda` (78 GB) hit 100% used, 76 K free. The combined weight of (a) the `d-mediawiki-new` build layers, (b) MySQL 8's temp tablespace during restore, and (c) existing `/home/charles/backups` (20 GB) plus `/var/lib/docker` (19 GB) pushed over. User freed ~28 GB by deleting old backup files. Load succeeded on retry (dropped partial `wikidb` first, then re-loaded).
2. **First mysqldump hung at 44 MB** — exact reproduction of the PTY/flag bug documented in `PlanFixBackups.md`. I had used `docker exec` (no `-t`, good) but with the password on the command line. Pivoted to the already-good systemd backup instead of re-dumping.
3. **Transient Bash harness glitches** — ~10 consecutive `/bin/date`, `/bin/ls`, etc. calls returned exit 1 with empty output during Phase 2.3. Self-resolved.

## Known issue blocking Phase 3

`curl http://localhost:8989/wiki/Main_Page` inside `stormy_mw_new` returns **HTTP 500** with a 336-byte body containing:

```html
<br />
<b>Deprecated</b>: Use of QuickTemplate::(get/html/text/haveData) with parameter `headelement` was deprecated in MediaWiki 1.39.
[Called from QuickTemplate::html in /var/www/html/includes/skins/QuickTemplate.php at line 168]
in <b>/var/www/html/includes/debug/MWDebug.php</b> on line <b>381</b><br />
<!DOCTYPE html>
<html class
```

…and then response truncates mid-`<html class`. That deprecation notice pins the first problem to `Bootstrap2.php` line 75:

```php
$this->html( 'headelement' );
```

MW 1.39 deprecated calling `QuickTemplate::html()` with `'headelement'` specifically. That is only a deprecation warning, but something downstream is fatal-erroring the page mid-render.

`Bootstrap2` is a BaseTemplate-derived skin from the MW 1.18 era. Plan §1.4 only covered three deprecated calls (`wfRunHooks`, `wfMsg`, `wfEmptyMsg`) — real scope is larger. Likely additional fixes needed:

- `$this->html('headelement')` → `$this->get('headelement')` or use `$out->headElement($this->getSkin())` directly
- Possibly other `BaseTemplate`/`QuickTemplate` methods that were removed or changed in MW 1.35–1.39
- The skin's `skin.json` may need updating for MW 1.39 compatibility metadata

Debugging was partially blocked by the container having no `/var/log/apache2/error.log` (Apache sends to docker stdout, but docker logs only showed the access line). I enabled `$wgShowExceptionDetails = true;` inside the running container but the page still truncates before reaching any exception render path — suggests the fatal happens before MW's error handler installs, or display_errors is eating it.

## Files modified during Phase 2

| Path | Change |
|---|---|
| `d-mediawiki-new/charlesreid1-config/mediawiki/extensions/{Math,ParserFunctions,SyntaxHighlight_GeSHi}/` | Cloned from git (REL1_39) |
| `docker-compose.yml.j2` | Added green services, network, volumes |
| `docker-compose.yml` | Regenerated by `make templates` |
| `d-mediawiki-new/charlesreid1-config/mediawiki/LocalSettings.php` | Regenerated by `make templates` from `.j2` |
| `d-mediawiki-new/charlesreid1-config/mediawiki/skins/Bootstrap2/Bootstrap2.php` | Regenerated by `make templates` (patches preserved from `.j2`) |
| `d-mediawiki-new/charlesreid1-config/mediawiki/skins/Bootstrap2/navbar.php` | Regenerated by `make templates` |

## Container state at end of Phase 2

| Container | Image | Status | Notes |
|---|---|---|---|
| `stormy_mysql` | `pod-charlesreid1_stormy_mysql` | Up 35h | Production — untouched |
| `stormy_mw` | `pod-charlesreid1_stormy_mw` | Up 35h | Production — untouched |
| `stormy_nginx` | `nginx:1.27.5` | Up 35h | Still pointing at `stormy_mw:8989` |
| `stormy_gitea` | `gitea/gitea:1.24.5` | Up 2d | Unrelated |
| `stormy_mysql_new` | `pod-charlesreid1-stormy_mysql_new` | Up | MySQL 8.0.45, wikidb loaded & verified |
| `stormy_mw_new` | `pod-charlesreid1-stormy_mw_new` | Up | MW 1.39, schema upgraded, **returns 500** |

## Data state

- Production DB: unchanged
- Green DB: MW 1.39 schema, populated and verified
- Production MW volume: unchanged
- Green MW volume: `images/` copied from production (1.6 GB)
- Nginx proxy: still → blue

## Disk space after Phase 2

`/dev/sda`: 50 GB used / 78 GB total (65%) — 28 GB free.

## Security reminder (still outstanding from Phase 1)

`"Bash(sudo *)"` deny rule in `/home/charles/.claude/settings.json` is still removed. Must be restored after upgrade is complete.

## Next steps before Phase 3

1. **Patch Bootstrap2 for MW 1.39** — fix `$this->html('headelement')` at Bootstrap2.php:75 and find/fix any other BaseTemplate/QuickTemplate incompatibilities causing the 500
2. Rebuild `stormy_mw_new` image with the skin fixes (or bind-mount the skins dir for faster iteration)
3. Re-curl `http://localhost:8989/wiki/Main_Page` inside the container — must return 200 with real HTML
4. If Bootstrap2 can't be made to work reasonably, fallback option: switch `$wgDefaultSkin` to `Vector` as a temporary measure to unblock the upgrade, and treat Bootstrap2 as a separate follow-up
5. Once green MW renders, proceed to Phase 3 (direct browser test via temporary port, then nginx-switchover test)

Fallback posture: production is untouched. If we decide the skin work is too large for this session, we can tear down the green stack and retry later with no impact to the live site.
