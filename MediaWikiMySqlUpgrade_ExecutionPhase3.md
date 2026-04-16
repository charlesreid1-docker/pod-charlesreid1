# MediaWiki/MySQL Upgrade — Phase 3 + Phase 4 Execution Log

Executed: 2026-04-15 → 2026-04-16

## Final state

Site is live on the green stack. Blue stack is stopped with volumes preserved for rollback.

```
stormy_mw_new      Up    ← live
stormy_mysql_new   Up    ← live
stormy_nginx       Up    → proxies to stormy_mw_new:8989
stormy_gitea       Up
stormy_mw          Exited (blue, volumes kept)
stormy_mysql       Exited (blue, volumes kept)
```

- MediaWiki 1.39.17 on PHP 8 / Apache
- MySQL 8.0.45
- Bootstrap2 skin rendering correctly
- Math formulas render client-side via self-hosted MathJax 3.2.2 (no external services)
- Page edits, uploads, deletes all working
- Parsoid bundled (REST `/w/rest.php/v1/page/*/with_html` works)
- All volumes, including the 1.64 GB image volume, migrated cleanly

## Phase 3 — Test Green Stack

### 3.1 Direct browser test on bound port 8990 — SKIPPED

Temp port binding added to `docker-compose.yml.j2`, then removed during Phase 4 cleanup. Bare port-bound responses render unstyled HTML because assets route through nginx; jumped to 3.2.

### 3.2 Test via nginx (dress rehearsal)

Flipped both `charlesreid1.com` and `www.charlesreid1.com` server blocks (and both `/wiki/` and `/w/` locations) in `d-nginx-charlesreid1/conf.d/https.DOMAIN.conf.j2` → `proxy_pass http://stormy_mw_new:8989/`. Reloaded nginx. Four regressions surfaced and were fixed (see below).

### 3.3 Test checklist results

All pass on live (post-fixes):
- Wiki pages render
- Bootstrap2 skin displays
- Math equations render (source mode + MathJax)
- Syntax highlighting works
- Edit / delete pages work as sysop
- Search works
- Special pages load (`SpecialPages`, `AllPages`, `RecentChanges`, `Search`)
- REST API: `/w/rest.php/v1/page/Main_Page/with_html` → 200 with rendered HTML

## Phase 3 regressions fixed during dress rehearsal

### Bug 1: Bootstrap2 CSS entirely missing

**Symptom:** unstyled pages, zero `<link rel="stylesheet">` in head.

**Root cause:** MW 1.39 removed `Skin::setupSkinUserCss()`. Bootstrap2's override was dead code.

**Fix:** in `d-mediawiki-new/charlesreid1-config/mediawiki/skins/Bootstrap2/Bootstrap2.php.j2`, replaced with `initPage( OutputPage $out )` override containing the same `$out->addStyle()` calls.

### Bug 2: `InvalidArgumentException: Actor name can not be empty for 0 and 9` on page save

**Symptom:** every edit submit returned 500.

**Root cause:** `update.php` backfilled `actor` table with `actor_user=NULL, actor_name=''` for revisions whose legacy `rev_user_text` was empty (historical imports with no attribution). 3007 revisions referenced it. MW 1.34 tolerated empty actor names; 1.39's `ActorStore::newActorFromRowFields()` throws.

**Fix:** scripted at `scripts/mw/phase4_post_load_fixups.sql`. Creates an "Unknown user" sentinel actor if absent, repoints every actor-column table (`revision`, `logging`, `recentchanges`, `archive`, `image`, `oldimage`, `filearchive`) from the empty-name actor to the sentinel, deletes the empty row.

Re-run during Phase 4 final data sync.

### Bug 3: Math rendering — "Invalid response from restbase"

**Symptom:** pages with `<math>` tags showed `<strong class="error texerror">Failed to parse (SVG ... Invalid response ...restbase...)</strong>` for every formula. Preview worked; saved output didn't.

**Initial wrong path:** assumed stale parser cache. Truncated `math`/`mathoid`/`mathlatexml` tables, cleared `objectcache`, restarted apache, restarted the container. Error count fluctuated (132 → 38 → 69 → 90) but never hit zero. Injected debug `error_log` in `ParserHooksHandler::mathTagHook` — zero lines logged on page fetch, which misled me into blaming APCu worker isolation.

**Real root cause:** even in `source` mode, `ParserHooksHandler::mathPostTagHook` calls `$renderer->checkTeX()`. The base `MathRenderer::checkTeX()` — regardless of renderer mode — falls through to `doCheck()` which calls **restbase** to validate TeX. When restbase is unreachable, `getLastError()` emits the `<strong class="error texerror">` markup directly into parser output.

Preview took a different entry point that skipped `checkTeX()`.

**Fix:** `$wgMathDisableTexFilter = 'always'` in `LocalSettings.php.j2`. Causes `MathConfig::texCheckDisabled()` to return `ALWAYS`, short-circuiting `checkTeX()` before `doCheck()` runs.

Full config stanza:
```php
$wgDefaultUserOptions['math'] = 'source';
$wgMathValidModes = [ 'source' ];
$wgMathDisableTexFilter = 'always';
$wgHooks['BeforePageDisplay'][] = function ( $out, $skin ) {
    $out->addHeadItem( 'mathjax',
        '<script>window.MathJax = { ... };</script>'
        . '<script async src="/w/mathjax/tex-chtml.js"></script>'
    );
};
```

### Bug 4: Math extension pointing at external restbase/mathoid

`LocalSettings.php.j2` had inherited legacy globals `$wgMathFullRestbaseURL` and `$wgMathMathMLUrl`. Removed.

MathJax 3.2.2 extracted into `d-mediawiki-new/charlesreid1-config/mediawiki/mathjax/` (24 MB) and bind-mounted into `/var/www/html/mathjax` (read-only). Served via the existing Apache `/w → /var/www/html` alias. This survives image rebuilds.

## Phase 4 — Switchover

### 4.0 Pre-flight cleanup

- Removed temp `8990:8989` port binding from `docker-compose.yml.j2`
- Added MathJax bind mount: `./d-mediawiki-new/charlesreid1-config/mediawiki/mathjax:/var/www/html/mathjax:ro`
- Extracted MathJax from running container to host (24 MB)
- Cleaned debug settings from live `LocalSettings.php` (`$wgShowExceptionDetails`, `ini_set("error_log", ...)`, `$wgDebugLogFile` overrides)
- Recreated `stormy_mw_new` to apply compose changes
- Verified: Math page still clean (0 errors, 61 source-mode fallbacks), MathJax loader still 200

### 4.1 Final data sync

Blue had no ongoing writers (just us). Accepted ~30s of potential data loss rather than locking blue read-only.

```bash
# Fresh dump from blue (5.7)
docker exec stormy_mysql sh -c \
  'mysqldump wikidb --databases -uroot -p"$MYSQL_ROOT_PASSWORD" --default-character-set=binary' \
  > /tmp/wikidb_final.sql
# → 578 MB, 615 INSERT statements

# Drop + recreate on green (8.0)
docker exec stormy_mysql_new sh -c \
  'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE wikidb; CREATE DATABASE wikidb;"'

# Load
docker exec -i stormy_mysql_new sh -c \
  'mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < /tmp/wikidb_final.sql
# → 36s

# Schema upgrade
docker exec stormy_mw_new php /var/www/html/maintenance/update.php --quick
# → 54s

# Post-load fixups (actor table sentinel + repoint)
docker exec -i stormy_mysql_new sh -c \
  'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" wikidb' \
  < scripts/mw/phase4_post_load_fixups.sql

# Flush APCu
docker restart stormy_mw_new
```

### 4.2 Switch nginx

Already on green from the 3.2 dress rehearsal — no additional flip needed.

### 4.3 Stop blue

```bash
docker compose stop stormy_mysql stormy_mw
```

Volumes preserved.

### 4.4 Post-switchover verification

- `Main_Page`, `Algebraic_Circuits`, `Algorithms/Sort`, `Special:AllPages` → 200
- `Algebraic_Circuits`: 0 errors, 61 source-mode math fallbacks
- Edit via `maintenance/edit.php` → saved
- Delete via `maintenance/deleteBatch.php` → 404 on refetch

## Files changed

### Host templates / configs

| File | Change |
|---|---|
| `docker-compose.yml.j2` | `stormy_mw_new`: removed temp `8990:8989` port; added MathJax bind mount |
| `d-nginx-charlesreid1/conf.d/https.DOMAIN.conf.j2` | 4× `proxy_pass` → `stormy_mw_new:8989` |
| `d-mediawiki-new/charlesreid1-config/mediawiki/LocalSettings.php.j2` | Math config reworked (source mode, TeX filter disabled, MathJax head injection); removed `$wgMathFullRestbaseURL` and `$wgMathMathMLUrl` |
| `d-mediawiki-new/charlesreid1-config/mediawiki/skins/Bootstrap2/Bootstrap2.php.j2` | Replaced `setupSkinUserCss()` → `initPage()` |

### New files

| File | Purpose |
|---|---|
| `d-mediawiki-new/charlesreid1-config/mediawiki/mathjax/` | MathJax 3.2.2 es5 tree (24 MB), bind-mounted into container |
| `scripts/mw/phase4_post_load_fixups.sql` | Actor table fix; idempotent; safe to re-run |
| `scripts/mw/build_extensions_dir_139.sh` | Shipped earlier; pulls REL1_39 Math / ParserFunctions / SyntaxHighlight_GeSHi |

## Rollback path

Blue stack retained. To roll back:

```bash
# Point nginx back to blue
# (edit d-nginx-charlesreid1/conf.d/https.DOMAIN.conf.j2 → stormy_mw:8989,
#  make templates, docker exec stormy_nginx nginx -s reload)
docker compose up -d stormy_mysql stormy_mw
docker exec stormy_nginx nginx -s reload
```

Blue data is stale by the ~2s it took to dump, plus the ~3 min since (which is longer than the "30s acceptable loss" estimate because the final verification ate time). If rollback is needed for data reasons (not just compat), dump green and reload into blue.

## Open items

- **Image rebuild test**: we never destroyed+rebuilt `stormy_mw_new` from scratch (the recreate in 4.0 reused the image). The actor fix, MathJax bind-mount, and template `LocalSettings.php` should all survive a full `docker compose build --no-cache && docker compose up -d` — but that's unverified.
- **Old blue containers/volumes**: keep for a week or two, then `docker compose rm stormy_mysql stormy_mw` + `docker volume rm pod-charlesreid1_stormy_mysql_data pod-charlesreid1_stormy_mw_data`.
- **EmbedVideo extension**: skipped for 1.39; add back later if wanted.
- **Restore `"Bash(sudo *)"`** to deny list in `~/.claude/settings.json` (carryover from Phase 1).
