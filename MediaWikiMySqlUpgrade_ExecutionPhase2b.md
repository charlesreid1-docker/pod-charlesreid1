# MediaWiki/MySQL Upgrade — Phase 2b Execution Log

Executed: 2026-04-15

## TL;DR

- **MW 1.39 + MySQL 8 + Parsoid is fully working end-to-end.** With `$wgDefaultSkin = "vector"`, `curl http://localhost:8989/wiki/Main_Page` returns **HTTP 200, 20676 bytes** of valid rendered HTML with correct title.
- **The only blocker is the Bootstrap2 skin.** With Bootstrap2 as default, every page (including MW's own exception pages) returns HTTP 500 with a truncated body.
- **Root cause of the Bootstrap2 500 is now known**: `Error: Class "SkinBootstrap2" not found`, thrown by `ObjectFactory::getObjectFromSpec` when `SkinFactory` tries to instantiate the skin. NOT the `headelement` deprecation — that's just a warning.
- Bootstrap2 restoration is a cosmetic follow-up; Vector unblocks Phase 3/4 right now.

## Current state

| Component | State |
|---|---|
| `stormy_mysql_new` | MySQL 8.0.45 up, `wikidb` loaded and verified (4631/29237/30081) |
| `stormy_mw_new` | MW 1.39.17 up, schema upgraded, rendering fine with Vector |
| `LocalSettings.php` | Live-edited inside container: `$wgDefaultSkin = "vector"` |
| `LocalSettings.php.bak` | Saved inside container before edit |
| `d-mediawiki-new/charlesreid1-config/.../LocalSettings.php.j2` | **Not yet changed** — still sets Bootstrap2. Image rebuild will lose the live edit. |
| Production (blue) | Untouched, serving normally |

## What I found

### Deprecation warnings (not fatal, confirmed benign)

PHP error log shows only two deprecations, no fatals:

```
PHP Deprecated:  Bootstrap2's extension.json or skin.json does not have manifest_version,
    this is deprecated since MediaWiki 1.29
PHP Deprecated:  Use of QuickTemplate::(get/html/text/haveData) with parameter
    `headelement` was deprecated in MediaWiki 1.39.
    [Called from QuickTemplate::html in .../QuickTemplate.php at line 168]
```

I initially assumed the `headelement` deprecation was fatal-ing the page. It's not — it's emitted via `trigger_error(..., E_USER_DEPRECATED)` and is only a warning.

### The real exception (from Bootstrap2 body, tail -c 800)

With `$wgShowExceptionDetails = true` and the response captured after setting Vector as default (so MW's own exception handler could render through a working skin), the response finally includes the full stack:

```
Error: Class "SkinBootstrap2" not found
#0 /var/www/html/vendor/wikimedia/object-factory/src/ObjectFactory.php(152):
   Wikimedia\ObjectFactory\ObjectFactory::getObjectFromSpec(array, array)
...
#5 /var/www/html/includes/exception/MWExceptionRenderer.php(183): OutputPage->output()
#6 /var/www/html/includes/exception/MWExceptionRenderer.php(102): MWExceptionRenderer::reportHTML(Error)
#7 /var/www/html/includes/exception/MWExceptionHandler.php(134): MWExceptionRenderer::report(Error, integer)
#8 /var/www/html/includes/exception/MWExceptionHandler.php(251): MWExceptionHandler::handleException(...)
```

That's an **exception inside exception handler** — when the skin fails to instantiate, MW tries to render an exception page, which instantiates the same broken skin, which throws again. That's why the body is truncated mid-`<link rel="EditURI" ... href="...api` at exactly 1959 bytes when Bootstrap2 is the default skin (no functional fallback renderer).

### Why `Class "SkinBootstrap2" not found` — this is the unsolved bit

I verified via an `error_log` diagnostic injected right after the skin's `require_once`:

```php
error_log("BS2-CHECK before=" . (class_exists("SkinBootstrap2",false) ? "y" : "n")
    . " SkinTemplate=" . (class_exists("SkinTemplate",false) ? "y" : "n"));
```

Output: `BS2-CHECK before=y SkinTemplate=y`. Both classes exist at the end of LocalSettings.php. But when `SkinFactory->makeSkin()` runs later in the request cycle, ObjectFactory reports `SkinBootstrap2` not found.

Relevant SkinFactory wiring (`includes/ServiceWiring.php:1784`):

```php
foreach ( $names as $name => $skin ) {
    if ( is_array( $skin ) ) {
        $spec = $skin;
        ...
    } else {
        $spec = [
            'name' => $name,
            'class' => "Skin$skin"     // 'Bootstrap2' → 'SkinBootstrap2'
        ];
    }
    $factory->register( $name, $displayName, $spec, $skippable );
}
```

So the spec is `['class' => 'SkinBootstrap2']`, which is the class we defined and loaded. Why ObjectFactory can't find it at request time — when it *is* defined globally — is the mystery. This is where I stopped to ask the user for help. Possibilities not yet investigated:

- Two `wgValidSkinNames` entries exist (`Bootstrap2` from skin.json, `bootstrap2` lowercase from LocalSettings manual assignment). The factory may be trying both in unexpected order.
- `wfLoadSkin` uses ExtensionRegistry, which may be memoizing an older skin.json snapshot that overrides the `require_once` + manual `$wgValidSkinNames` pair.
- The skin.json's `"ValidSkinNames": {"Bootstrap2": "Bootstrap2"}` short-form may route through a different code path than expected in manifest_version-1 mode.
- opcache could be holding a stale class table between processes, but `class_exists` diagnostic ran in the same request.

## The ten-dollar rabbit hole (what I should have skipped)

Time order of what I did after the user said "please proceed, attempt to fix the bootstrap skin incompatibilities":

1. Read `MWExceptionHandler::handleFatalError` (lines 361–410) to understand the 500 trigger. **Wasted** — there was no fatal, only deprecations, which this function ignores.
2. Looked at `SkinTemplate::generateHTML` and `outputPage` to understand how `$useHeadElement` interacts with the `$this->html('headelement')` call in the execute() template. **Partially useful** — confirmed `$useHeadElement` is no longer consulted in 1.39; `bodyOnly` is the new mechanism. But this wasn't the bug.
3. Followed the truncation point (`href="https://charlesreid1.com/w/api`) into `OutputPage::headElement` and `buildCssLinksArray` looking for a spot where output could be interrupted mid-`Html::element` call. **Wasted** — the truncation is because the exception handler output went through the same broken skin, not because `headElement` itself truncated.
4. Checked php.ini live values (`display_errors`, `output_buffering`), looked at `MWExceptionRenderer::reportHTML`, followed the `useOutputPage` branch. **Partially useful** — this is how I realized the 1959-byte body was MW's error page re-rendered through Bootstrap2 and exploding again, which is why enabling `$wgShowExceptionDetails` didn't show anything useful until I switched the default skin.
5. Finally: switched `$wgDefaultSkin` to Vector, hit with `?useskin=bootstrap2`, and got a clean exception stack — **which is what I should have done first.** The skin-swap diagnostic took ~2 minutes once I actually tried it. Everything before that was speculating from symptoms.

**Lesson for the memory file**: when MW returns a truncated 500 and `$wgShowExceptionDetails = true` shows nothing useful, the most likely cause is that **the skin itself is broken and the exception handler is trying to render through the same broken skin**. Fix: switch to a known-good default skin (Vector) first, then hit the bad skin via `?useskin=X` so exceptions render through the working one.

## Debug artifacts left inside the container

- `/var/www/html/LocalSettings.php` — live-edited:
  - `wfLoadSkin( "Vector" );` added before Bootstrap2 load
  - `$wgDefaultSkin = "vector";` (was `"Bootstrap2"`)
  - Bootstrap2's `wfLoadSkin` and `require_once` are still present so `?useskin=bootstrap2` still works for debugging
  - `$wgDebugLogFile = "/tmp/mw_debug.log";` enabled (unused, MW logger was silent)
- `/var/www/html/LocalSettings.php.bak` — pre-edit snapshot
- `/tmp/php_errors.log` — PHP error log (deprecations only)
- `/tmp/vector_test.html` — verified 200 response (20676 bytes)
- `/tmp/bs2_test.html` — verified 500 response with full stack trace (2765 bytes)

**These are all live edits inside the container. An image rebuild will wipe them.** See "Next steps" for what needs to move back into `d-mediawiki-new/charlesreid1-config/`.

## Decision point

Two paths forward, waiting on user:

**Path A — Vector now, Bootstrap2 as follow-up (recommended).**
1. Update `d-mediawiki-new/charlesreid1-config/mediawiki/LocalSettings.php.j2` to set `$wgDefaultSkin = "vector"` and `wfLoadSkin( 'Vector' )`.
2. Rebuild `stormy_mw_new` image (or bind-mount during testing).
3. Proceed to Phase 3 (direct browser test and nginx switchover test) with Vector.
4. Proceed to Phase 4 switchover — production now serves MW 1.39 + Vector + working Parsoid REST API.
5. File Bootstrap2 skin modernization as a separate task to tackle later without upgrade pressure.

**Path B — fix Bootstrap2 before Phase 3.**
1. Figure out why `SkinBootstrap2` isn't visible to `ObjectFactory` despite being globally defined. Likely fix: rewrite `skin.json` to manifest_version 2 with an explicit `AutoloadClasses` entry and drop the manual `require_once`. (Similar pattern to MonoBook's skin.json which uses `SkinMustache` — but Bootstrap2 uses the old `QuickTemplate` pattern, not Mustache, so it's more like the old MonoBook structure pre-1.35.)
2. Patch `Bootstrap2.php:75` to replace `$this->html('headelement')` — the call still works but emits a deprecation every request. Long-term fix is to migrate the skin away from `QuickTemplate::html` and toward the SkinMustache pattern, but that's a substantial rewrite.
3. Patch `Bootstrap2.php:393` — already done (`Hooks::run` in place of `wfRunHooks`).
4. Patch `Bootstrap2.php:432` — already done (`wfMessage()->isDisabled()/->text()` in place of `wfMsg`/`wfEmptyMsg`).

Path A unblocks the upgrade in under 30 minutes. Path B is probably 2–4 hours of skin.json + class-loader archaeology plus testing, with uncertain success.

## Files untouched on disk (still need real edits if we go forward)

These are on the host filesystem in `d-mediawiki-new/`, NOT in the container. An image rebuild pulls from these:

- `d-mediawiki-new/charlesreid1-config/mediawiki/LocalSettings.php.j2` — still sets Bootstrap2 as default skin
- `d-mediawiki-new/charlesreid1-config/mediawiki/skins/Bootstrap2/Bootstrap2.php` / `.j2` — `headelement` call still present (warning only, harmless)
- `d-mediawiki-new/charlesreid1-config/mediawiki/skins/Bootstrap2/skin.json` — still manifest_version-1 short form

## Production posture

Production (blue) is completely untouched and serving normally. We can tear down the green stack with zero impact if needed.
