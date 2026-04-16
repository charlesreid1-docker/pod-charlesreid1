# MediaWiki/MySQL Upgrade — Phase 2c Execution Log

Executed: 2026-04-15

## Status

Green stack is now rendering Bootstrap2 cleanly AND serving Parsoid REST output. Two bugs were fixed in this phase:

1. **Bootstrap2 skin** was fatal-erroring on `Sanitizer::escapeId()` (removed method).
2. **Image volume** was nested one level deeper than MW expected (`images/images/...` instead of `images/...`), which broke Parsoid's UUID generator writes to `images/tmp/`.

Both are fixed. Bootstrap2 is back as the default skin, `/wiki/Main_Page` returns 200 via Bootstrap2 with zero PHP errors, and `/w/rest.php/v1/page/Main_Page/with_html` returns 200 with rendered HTML.

## Bugs fixed

### Bug 1: Bootstrap2 `Sanitizer::escapeId` fatal

**Real root cause** (after the red herring in Phase 2b — see that log):

```
Error: Call to undefined method Sanitizer::escapeId()
  at /var/www/html/skins/Bootstrap2/Bootstrap2.php:149
#0 SkinTemplate::generateHTML
#1 SkinTemplate::outputPage
#2 OutputPage::output
```

`Sanitizer::escapeId()` was removed from MW; the replacement is `Sanitizer::escapeIdForAttribute()`. The `headelement` deprecation warning I chased in Phase 2b was noise — it's a `trigger_error(E_USER_DEPRECATED)`, not a fatal.

The "Class SkinBootstrap2 not found" stack in Phase 2b was from MW's exception handler trying to render the error page through the same broken skin, triggering a nested `ContextSource->getSkin()` that couldn't resolve the skin at that stage of request teardown. With `$wgDefaultSkin = "vector"` set, the exception handler could finally render through a working skin — which is how I ultimately got the real stack via an injected `error_log()` in `MWExceptionHandler::handleException`.

**Instances of `Sanitizer::escapeId`** in `Bootstrap2.php`:

| Line | Status | Notes |
|---|---|---|
| 75 | `$this->html('headelement')` → `echo $this->data['headelement']` | Silences 1.39 deprecation, not a fatal |
| 149 | Patched to `escapeIdForAttribute` | Live, caused the fatal |
| 332 | Patched to `escapeIdForAttribute` | Live, would have fatal'd on any page with RSS feeds |
| 426, 434 | Untouched | Inside `customBox()`, which `execute()` never calls — dead code |

**Files edited on host** (both `.php` and `.php.j2`):

- `d-mediawiki-new/charlesreid1-config/mediawiki/skins/Bootstrap2/Bootstrap2.php`
- `d-mediawiki-new/charlesreid1-config/mediawiki/skins/Bootstrap2/Bootstrap2.php.j2`

The patched files were then `docker cp`'d into the running container for verification.

**Verification**: `curl http://localhost:8989/wiki/{Main_Page,Special:Version,Special:AllPages,Special:RecentChanges}` — all returned HTTP 200, response sizes 15115 / 49347 / 49350 / 44194 bytes, `/tmp/php_errors.log` empty.

### Bug 2: Nested `images/` directory breaking Parsoid REST

**Discovered** while running Tier 1.5 from the testing strategy. `/w/rest.php/v1/page/Main_Page/with_html` returned 500 with:

```
RuntimeException: Could not open '/var/www/html/images/tmp/mw-GlobalIdGenerator33-UUID-128'
  at GlobalIdGenerator.php:458
```

**Root cause**: Phase 2's image copy command was:

```bash
docker run --rm \
  -v pod-charlesreid1_stormy_mw_data:/old:ro \
  -v pod-charlesreid1_stormy_mw_new_data:/new \
  alpine cp -a /old/images /new/images
```

At the time of the copy, `/new/images` already existed as a directory (created by `mediawiki:1.39`'s image baseline), so `cp -a /old/images /new/images` placed the copied tree at `/new/images/images/` instead of `/new/images/`. Result: real wiki files lived at `/var/www/html/images/images/{0..f,tmp,archive,thumb,...}` and MW couldn't find any of them. Main_Page still rendered because it happens not to embed any images; Parsoid failed because it tries to write to `images/tmp/`.

**Correct form** (for future upgrades): `cp -a /old/images/. /new/images/` OR pre-remove `/new/images` and use `cp -a /old/images /new/`.

**Fix applied**:

```bash
docker exec stormy_mw_new sh -c '
  cd /var/www/html/images
  mv images/.htaccess .htaccess
  mv images/README README
  for f in images/*; do mv "$f" .; done
  rmdir images
'
```

Unnest moved all 27 top-level entries (hex dirs `0`..`f`, `archive`, `thumb`, `tmp`, etc.) up one level, overwriting the stub `.htaccess` + `README` that the MW image shipped. Ownership and permissions were preserved (`www-data:www-data`, mode 755).

**Verification**: `/w/rest.php/v1/page/Main_Page/with_html` → HTTP 200, 8340 bytes, response JSON contains `"html"` key (rendered Parsoid output). `/wiki/Main_Page` still HTTP 200 with zero PHP errors.

## Remaining steps

### Phase 2 cleanup (before Phase 3)

1. **Sync live container edits back to host templates.** The running container has debug settings the host `.j2` doesn't, and a rebuild would lose them. Specifically:
   - `LocalSettings.php` in container has `$wgDebugLogFile = "/tmp/mw_debug.log"` and a now-orphaned `wfLoadSkin("Vector")` left from debugging — the host `.j2` is clean and will wipe these on rebuild (desired).
   - Bootstrap2 patches are already on host. Good.
   - **Image unnesting is only in the container volume** — the host has no source-of-truth here because it's a data volume.
2. **Fix the underlying image-copy command** in the Phase 2 plan (`cp -a /old/images /new/images` → should be `cp -a /old/images/. /new/images/` or `cp -a /old/images /new/` with pre-cleared parent) so next time we don't re-nest.
3. **Rebuild `stormy_mw_new` from the host templates** to confirm the host `.j2` files produce a working container (i.e., that my live edits weren't load-bearing). After rebuild, re-run the image unnest if necessary.

### Phase 3 (test green stack) — per `MediaWikiMySqlUpgrade_TestingStrategy.md`

4. **Tier 0** — pre-flight sanity: container health, MySQL version, row-count parity, schema artifacts.
5. **Tier 1** — in-container HTTP smoke tests: API, search, REST/Parsoid (now passing), Math, SyntaxHighlight, ParserFunctions, clean error log.
6. **Tier 2** — write-path test via `maintenance/edit.php`, verify row lands in DB, delete test page, run `runJobs.php`.
7. **Tier 3** — temporary host port `8990:8989`, real browser checks: login, edit/revert, upload/delete, search.
8. **Tier 4** — nginx switchover dress rehearsal: prep blue/green confs, `nginx -t`, `nginx -s reload`, 5-minute soak on real traffic, verify MCP end-to-end, rollback test.

### Phase 4 (switchover, ~2 s downtime)

9. **Final data sync**: re-dump production, drop+reload green `wikidb`, re-run `update.php --quick` to catch any edits made since Phase 2.
10. **Flip nginx** `proxy_pass` from `stormy_mw:8989` → `stormy_mw_new:8989` in `d-nginx-charlesreid1/conf.d/https.DOMAIN.conf.j2`, `make templates`, `nginx -s reload`.
11. **Stop old containers** (optional, can defer): `docker compose stop stormy_mysql stormy_mw`. Keep volumes.

### Phase 5 (retention / rollback window)

12. **Keep blue containers and volumes for 2+ weeks** before removing them. Rollback is instant during that window: edit `proxy_pass` back, `nginx -s reload`.
13. **After 2 weeks stable**: `docker compose rm stormy_mysql stormy_mw` and `docker volume rm stormy_mysql_data stormy_mw_data`.

### Post-upgrade cleanup

14. **Restore `"Bash(sudo *)"`** to the deny list in `~/.claude/settings.json` (outstanding from Phase 1).
15. **Prune the per-service sudo allows** in `.claude/settings.local.json` if desired.
16. **Decide on EmbedVideo** — REL1_39-compatible fork exists; was intentionally skipped in Phase 1.
17. **Plan the next hop**: MW 1.39 → 1.42 using the same blue-green approach, reusing this testing strategy and the Bootstrap2 patches.

### Known deferred items

- `Bootstrap2.php:426,434` still reference `Sanitizer::escapeId` but are inside `customBox()`, which `execute()` never calls. Dead code. Will fatal only if anything ever invokes that method.
- `skin.json` for Bootstrap2 has no `manifest_version` — benign deprecation, not blocking.

## Debug artifacts still live in the container (not on host)

- `/var/www/html/LocalSettings.php` — has `$wgShowExceptionDetails = true` and `$wgDebugLogFile = "/tmp/mw_debug.log"` enabled from debugging. Host `.j2` is clean; rebuild will reset these.
- `/var/www/html/LocalSettings.php.bak` — pre-edit snapshot.
- `/tmp/php_errors.log`, `/tmp/mw_test.html`, `/tmp/bs2.html`, `/tmp/vector_test.html`, `/tmp/rest.json`, etc. — scratch files from the debugging session. Harmless.
- `/var/www/html/includes/exception/MWExceptionHandler.php` — had a diagnostic `error_log()` call injected into `handleException()`, then removed. Clean now.
