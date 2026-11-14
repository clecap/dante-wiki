# DanteWiki Upgrade Analysis: MediaWiki 1.39 → 1.40 → 1.43

This document lists the changes DanteWiki needs to run on MediaWiki 1.40 and on 1.43 LTS. It was written on 2026-11-04 and starts from MediaWiki 1.39.0, the version in [includes/Defines.php](includes/Defines.php).

## Scope and method
 
The following code was checked:
     
- Parsifal
- the Dante extensions (`extensions/Dante*`)
- the Dante settings files (`Dante*.php`, `LocalSettings.php`)
- the custom skins DantePresentationSkin and skinny
- the patched MediaWiki core files

The code was searched for the APIs that these release notes list as removed, changed or deprecated:

- [RELEASE-NOTES-1.40](https://github.com/wikimedia/mediawiki/blob/REL1_40/RELEASE-NOTES-1.40)
- [RELEASE-NOTES-1.41](https://github.com/wikimedia/mediawiki/blob/REL1_41/RELEASE-NOTES-1.41)
- [RELEASE-NOTES-1.42](https://github.com/wikimedia/mediawiki/blob/REL1_42/RELEASE-NOTES-1.42)
- [RELEASE-NOTES-1.43](https://github.com/wikimedia/mediawiki/blob/REL1_43/RELEASE-NOTES-1.43) (the current point release is 1.43.11)

The patched core files were compared with upstream 1.39.0, REL1_40 and REL1_43.

**Nothing in this analysis was tested by running the wiki on 1.40 or 1.43.**

In this document, **"breaks in 1.4x"** means the code stops working from that version on. **"Warns from 1.4x"** means the code still works but writes deprecation warnings to the logs from that version on.

## Target version and platform

- **1.40 is end-of-life.** It was a short-lived release (June 2023) that stopped receiving security fixes in 2024.
- **1.39 LTS is also end-of-life.** Its support ended in December 2025.
- **The recommended target is 1.43 LTS**, which is supported until late 2027.
- **You can upgrade directly from 1.39 to 1.43.** You don't need to install 1.40, 1.41 or 1.42 in between: one run of `update.php` handles the database schema changes of all the intermediate versions.

| | 1.39 (current) | 1.40 | 1.43 LTS |
|---|---|---|---|
| PHP | 7.4.3 or later | 7.4.3 to 8.1 officially | 8.1 or later; the point releases contain fixes for PHP 8.4 |
| MySQL / MariaDB | 5.7 / 10.3 | 5.7 / 10.3 | 5.7 / 10.3 |
| Security support | ended Dec 2025 | ended 2024 | until late 2027 |

The container runs **PHP 8.4.27** and uses `$wgDBtype = "mysql"`. Neither 1.39 nor 1.40 supports PHP 8.4. 1.43 is the first version that is a reasonable fit for this container.

## Summary of required changes

| # | What | Where | Breaks in |
|---|---|---|---|
| 1 | `PageProps::getInstance()` was removed | [DantePresentations.php:322](extensions/DantePresentations/DantePresentations.php#L322) | 1.40 |
| 2 | Core patch UploadBase.php (not documented) | [includes/upload/UploadBase.php](includes/upload/UploadBase.php) | every upgrade |
| 3 | Core patch SVGReader.php (probably has no effect) | [includes/media/SVGReader.php](includes/media/SVGReader.php) | every upgrade |
| 4 | Core patch WikiImporter.php | [includes/import/WikiImporter.php](includes/import/WikiImporter.php) | every upgrade |
| 5 | Maintenance scripts are called directly | DanteBackup | warns from 1.40 |
| 6 | `WikiPage::factory()` was removed | [Snippets.php:126](extensions/DanteSnippets/Snippets.php#L126) | 1.41 (warns in 1.40) |
| 7 | `ResourceLoaderSkinModule` alias was removed | both custom skins (`skin.json`) | 1.42 |
| 8 | `jquery.cookie` module was removed | [DanteTree extension.json](extensions/DanteTree/extension.json) | 1.42 |
| 9 | `DB_MASTER` constant was removed | [TreeAndMenu_body.php](extensions/DanteTree/TreeAndMenu_body.php) lines 346, 374 | 1.43 |

## Required changes in detail

### 1. `PageProps::getInstance()` was removed (breaks in 1.40)

- **File:** [extensions/DantePresentations/DantePresentations.php:322](extensions/DantePresentations/DantePresentations.php#L322)
- **Problem:** the method no longer exists, so this line causes a fatal error.
- **Fix:** replace it with:

  ```php
  MediaWikiServices::getInstance()->getPageProps()->getProperties( $title, 'displaytitle' );
  ```

### 2. Core patch in `UploadBase.php`

- **The patch:** in the `$validNamespaces` list, the entry `''` is replaced by `'http://www.w3.org/1999/xhtml'`. It is marked `// patched CHC`.
- **Problem:** this patch is **not documented** in [README-dantepatch.md](README-dantepatch.md). Add it there.
- **Fix:** re-apply the patch after every core upgrade.

| Version | Location |
|---|---|
| 1.39 (current) | around line 1572 |
| 1.40 | line 1554 |
| 1.43 | `$validNamespaces` starts at line 1633 |

### 3. Core patch in `SVGReader.php`

- **The patch:** `libxml_disable_entity_loader(false);  // CHC DANTE PATCH`, placed just before `$this->reader->open(...)`.
- **The patch probably has never had an effect.** Even in the current 1.39 code, the `SVGReader` constructor calls `@libxml_disable_entity_loader( true )` at line 91. This happens right after the patched `open()` call and before anything is read, so it undoes the Dante patch. 1.43 has the same structure: `open()` at line 81, `libxml_disable_entity_loader( true )` at line 96.
- **More reasons to doubt it:**
  - `libxml_disable_entity_loader()` has been deprecated since PHP 8.0, so on PHP 8.4 the patch also produces a deprecation warning.
  - Since libxml 2.9, external entities are not loaded by default.
- **Before porting the patch again:** test whether importing drawio SVGs from a dump works without it. If it does, drop the patch and remove it from README-dantepatch.md.

| Version | `reader->open` call |
|---|---|
| 1.39 (current) | line 79 (patch at line 78) |
| 1.40 | line 78 |
| 1.43 | line 81 |

### 4. Core patch in `WikiImporter.php`

- **The patch:** `throw new MWException( 'Missing text field in import.' )` is replaced by `$contentInfo['text'] = "NO-TEXT-SUPPLIED";`.
- **Fix:** re-apply the patch after every core upgrade. In 1.43 the line throws `InvalidArgumentException` instead of `MWException`, but the fix is the same.

| Version | Location |
|---|---|
| 1.39 (current) | line 1054 |
| 1.40 | line 1045 |
| 1.43 | line 1034 |

### 5. Maintenance scripts are called directly (warns from 1.40)

- **Change:** from 1.40 on, maintenance scripts should be run through `maintenance/run.php`.
- **Effect:** calling them directly still works, but prints deprecation warnings. These warnings end up in the command output that DanteBackup logs.
- **Fix:** change `php $IP/maintenance/importDump.php ...` to `php $IP/maintenance/run.php importDump ...`, and do the same for the other scripts.

Calls to change:

| File | Lines | Scripts |
|---|---|---|
| [extensions/DanteBackup/DanteRestore.php](extensions/DanteBackup/DanteRestore.php) | 261–263 | `importDump.php` |
| [extensions/DanteBackup/DanteRestore.php](extensions/DanteBackup/DanteRestore.php) | 282 | `rebuildImages.php` |
| [extensions/DanteBackup/DanteRestore.php](extensions/DanteBackup/DanteRestore.php) | 488–493 | `rebuildrecentchanges.php`, `initSiteStats.php`, `rebuildImages.php`, `rebuildall.php`, `checkImages.php`, `refreshFileHeaders.php` |
| [extensions/DanteBackup/DanteDump.php](extensions/DanteBackup/DanteDump.php) | 127 | `dumpBackup.php` |

These scripts load `maintenance/Maintenance.php` themselves:

- [extensions/DanteCommon/importDirectory.php](extensions/DanteCommon/importDirectory.php)
- [extensions/DantePresentations/php/creator.php](extensions/DantePresentations/php/creator.php)
- [extensions/DantePresentations/php/creator2.php](extensions/DantePresentations/php/creator2.php)
- [extensions/DantePresentations/php/pageCreator.php](extensions/DantePresentations/php/pageCreator.php)

They still work in 1.43. They don't use any of the `Maintenance` members removed in 1.41 (`$mArgList`, `shouldExecute()`, `globals()`, `loadSettings()` and others). Run them through `maintenance/run.php` as well.

### 6. `WikiPage::factory()` was removed (warns in 1.40, breaks in 1.41)

- **File:** [extensions/DanteSnippets/Snippets.php:126](extensions/DanteSnippets/Snippets.php#L126)
- **Fix:** replace it with:

  ```php
  MediaWikiServices::getInstance()->getWikiPageFactory()->newFromTitle( $title );
  ```

### 7. `ResourceLoaderSkinModule` alias was removed (breaks in 1.42)

- **Files:** [skins/DantePresentationSkin/skin.json](skins/DantePresentationSkin/skin.json) and [skins/skinny/skin.json](skins/skinny/skin.json)
- **Problem:** in 1.42, all class aliases for namespaced classes that were added in or before 1.39 were removed. The skins' style modules can no longer be loaded.
- **Fix:** change `"class": "ResourceLoaderSkinModule"` to `"class": "MediaWiki\\ResourceLoader\\SkinModule"` in both files. The new class name already exists in 1.39, so you can make the change now.

### 8. `jquery.cookie` module was removed (breaks in 1.42)

- **File:** [extensions/DanteTree/extension.json](extensions/DanteTree/extension.json), module `ext.fancytree`
- **Problem:** the module lists `jquery.cookie` as a dependency. A missing dependency stops the whole `ext.fancytree` module from loading, so the DanteTree menus break.
- **Code that needs cookies:** [jquery.fancytree.persist.js](extensions/DanteTree/fancytree/jquery.fancytree.persist.js) uses `Cookies` if it exists, and otherwise `$.cookie`.
- **Fix:** replace `jquery.cookie` with `mediawiki.cookie`. From 1.41 on, `mediawiki.cookie` contains what used to be the `jquery.cookie` module. Then check that saving the tree state still works.

### 9. `DB_MASTER` constant was removed (breaks in 1.43)

- **File:** [extensions/DanteTree/TreeAndMenu_body.php](extensions/DanteTree/TreeAndMenu_body.php), lines 346 and 374
- **Fix:** use `DB_PRIMARY`. Line 346 also uses `wfGetDB()` (see the next section). The recommended replacement is:

  ```php
  MediaWikiServices::getInstance()->getConnectionProvider()->getPrimaryDatabase()
  ```

## Deprecations and cleanups

These still work in 1.43, but they will break in a later release. The ones marked "warns from" write deprecation warnings to the logs from that version on.

| Item | Where | Status | Fix |
|---|---|---|---|
| `wfGetDB()` | [DantePolyfill.php](DantePolyfill.php) (2 uses), [TreeAndMenu_body.php](extensions/DanteTree/TreeAndMenu_body.php) | warns from 1.42 | `getConnectionProvider()->getReplicaDatabase()` or `->getPrimaryDatabase()` |
| `ContentHandler::getContentText()` | DantePolyfill, InfoExtractor, Translate, SubTranslate, danteEndpoint, TreeAndMenu_body, Parsifal (FullPage, TeXGenerator) | warns from 1.43 | `$content instanceof TextContent ? $content->getText() : null` |
| Dynamic properties on `Parser` | [TexProcessor.php:78](extensions/Parsifal/php/TexProcessor.php#L78) (`$parser->storePreamble`), [danteEndpoint.php:189](extensions/DantePresentations/endpoints/danteEndpoint.php#L189) (`$parser->danteTag`) | warns from 1.42 | Store the value with `ParserOutput::setExtensionData()`, or in a static or service property. |
| `ParserOutput::setPageProperty()` with a non-string value | [TexProcessor.php:140](extensions/Parsifal/php/TexProcessor.php#L140) (passes an integer for "Parsifals") | deprecated in 1.42, warns from 1.43 | Use `setNumericPageProperty()`. |
| `mediawiki.ui.icon`, `mediawiki.ui.button` | [DantePresentationSkin skin.json](skins/DantePresentationSkin/skin.json), [skinny skin.json](skins/skinny/skin.json) | console warnings from 1.41 | Remove them, or use Codex CSS components. |
| `MWException` | [Snippets.php](extensions/DanteSnippets/Snippets.php) | deprecated in 1.40 | Use `Exception` or `RuntimeException`. |
| `$wgTitle` | [Parsifal.php:85](extensions/Parsifal/Parsifal.php#L85), inside the `SkinTemplateNavigation::Universal` handler | fragile | Use `$skin->getTitle()`. |
| `$wgOut` | DanteTree (TreeAndMenu_body), DantePresentations (Translate, SubTranslate), Parsifal (TexProcessor) | fragile | Use the context's `OutputPage`. |
| `new WikiPage(...)` | Several Dante files | works | `WikiPageFactory` is preferred. |
| `jquery.ui` | [DanteLinks extension.json](extensions/DanteLinks/extension.json), [DanteTree extension.json](extensions/DanteTree/extension.json) | still available in 1.43 | Plan to replace it eventually. |
| `manifest_version: 1` | [DanteHideSection extension.json](extensions/DanteHideSection/extension.json) | still supported | Move it to version 2. |

### Heading and table-of-contents markup

These are not needed for 1.43 with its default settings, but they matter for a later upgrade.

- **New heading markup:** 1.43 adds `$wgParserEnableLegacyHeadingDOM`, which defaults to `true`. With the default, the old heading markup with `span.mw-headline` is kept. The new markup is used only if you set the option to `false` and the skin opts in with `supportsMwHeading`. A later MediaWiki release will make the new markup the default.
- **Code that depends on `.mw-headline`:**
  - [ext.dantehidesection.js](extensions/DanteHideSection/resources/ext.dantehidesection.js) (lines 155, 164)
  - [ext.dantehidesection.css](extensions/DanteHideSection/resources/ext.dantehidesection.css)
  - [tags.css](extensions/DantePresentations/modules/tags.css)
- **Table of contents:** [DantePresentations.php:271](extensions/DantePresentations/DantePresentations.php#L271) checks for `<div id="toc"`. Test this with the 1.43 parser output, because the table-of-contents handling has changed internally since 1.40.

## Checked and unaffected

- **Hooks:** none of the hooks used by Parsifal, the Dante extensions, the custom skins or DanteSettings.php were removed or deprecated in 1.40–1.43.
  - Hooks in use: `ArticleViewHeader`, `AuthChangeFormFields`, `BeforePageDisplay`, `CategoryAfterPageAdded`, `CategoryAfterPageRemoved`, `EditPage::attemptSave:after`, `EditPage::showEditForm:initial`, `GetDoubleUnderscoreIDs`, `GetPreferences`, `HtmlPageLinkRendererEnd`, `LinkerMakeExternalLink`, `OutputPageAfterGetHeadLinksArray`, `OutputPageBeforeHTML`, `PageDeleteComplete`, `PageSaveComplete`, `ParserAfterParse`, `ParserBeforeInternalParse`, `ParserFirstCallInit`, `SiteNoticeAfter`, `SkinAddFooterLinks`, `SkinBuildSidebar`, `SkinEditSectionLinks`, `SkinTemplateNavigation::Universal`, `UserSaveSettings`.
  - Some hook interface classes moved into new namespaces in 1.42. This doesn't matter here, because handlers are registered by name in `extension.json`.
- **`$wgHooks`:** the `AuthChangeFormFields` entry in [DanteSettings.php:12](DanteSettings.php#L12) is set at configuration time, which is still allowed. Only changing `$wgHooks` at runtime has been deprecated since 1.40.
- **`$wgParser`:** appears only in comments in the settings files.
- **`Hooks` class:** it was removed in 1.42, but nothing here uses it (`Hooks::run`, `Hooks::register` and so on).
- **Parsifal:** besides the items listed above, no removed API is used.
  - [FullPage.php](extensions/Parsifal/php/FullPage.php) contains `FullPageAction`. It already passes both `$article` and `$context` to the `Action` constructor, as 1.40 requires.
  - `FullPageAction` is not registered under `Actions` in `extension.json`, so it is dead code.
  - `$article->mTitle` in [TexProcessor.php](extensions/Parsifal/php/TexProcessor.php) is inside a commented-out block.
- **Parser internals:** none of the Parser properties made private in 1.40 (such as `mShowToc` or `mRevisionId`) are accessed. No TOC placeholder markers (`<mw:toc>`, `<mw:tocplace>`) are parsed directly.
- **Class aliases:**
  - Besides `ResourceLoaderSkinModule`, none of the aliases removed in 1.42 are used. These include `DBError`, `DBQueryError`, `LoadBalancer`, `LinksUpdate`, `Blob`, `Block` and the other `ResourceLoader*` classes.
  - Classes that were moved into namespaces in 1.40 and 1.41 (`Title`, `Html`, `Linker`, `EditPage`, `PageProps`, `MagicWord`, `User`, `SpecialPage`, …) still have their old names as aliases in 1.43.
- **Custom skins:**
  - Both DantePresentationSkin and skinny extend `SkinMustache`. They use none of the removed Skin methods (`getFooterLinks`, `getSiteFooterLinks`, `getAfterPortlet`, `get`/`setSearchPageTitle`).
  - The mustache template keys they use (`html-title-heading`, `html-body-content`, `html-after-portal`, `array-indicators`, `html-user-language-attributes`, …) are not listed as removed. `html-hello` is a key the skins define themselves.
- **Database access:**
  - `newSelectQueryBuilder()` and `PageStore::getSelectFields()` in Parsifal and Translate/SubTranslate are the current API. `Title::getSelectFields()`, which was removed in 1.41, is not used.
  - `getDBLoadBalancer()->getConnection( DB_REPLICA )` still works.
- **User options:** `getUserOptionsLookup()->getOption()` in DanteBackup is the current API.
- **Page properties:** `PageProps::getProperties()` in [Parsifal.php:125](extensions/Parsifal/Parsifal.php#L125) is called on a `PageProps` service instance, which is fine.
- **Configuration:** none of the configuration variables removed or changed in 1.40–1.43 are set in LocalSettings.php, DanteSettings.php or DanteDynamicInstalls.php. `$wgLogo` is still valid; only `$wgLogoHD` was removed (in 1.42).

## Other work around the upgrade

### Bundled and third-party extensions

All bundled extensions need the branch for the target version (REL1_40 or REL1_43): AbuseFilter, Cite, VisualEditor, Scribunto, MobileFrontend, Math and the others.

These third-party extensions each need a release that supports the target version:

| Extension | Current version | Requires MediaWiki |
|---|---|---|
| DrawioEditor | 3.0.0-alpha | ≥ 1.39.0 |
| DynamicPageList3 | 3.5.2 | ≥ 1.39.0 |
| WikiMarkdown | 1.1.3 | ≥ 1.34 |
| SubPageList3 | 1.4 | ≥ 1.39.0 |
| SubPageList (composer) | 3.0.1 | ≥ 1.36.0 |
| NativeSvgHandler | 1.4.0 | ≥ 1.35.0 |
| WikiCategoryTagCloud | 1.4 | ≥ 1.34.0 |
| RandomSelection | 2.3.0 | ≥ 1.31.0 |
| RevisionSlider | (bundled) | ≥ 1.39.0 |

### Composer

[composer.local.json](composer.local.json) pulls in `symfony/http-client ^8.1`, which requires PHP 8.4. Run `composer update` early, because it may conflict with the Symfony versions pinned by MediaWiki core. Other dependencies to check:

- `openai-php/client`
- `deeplcom/deepl-php`
- `nyholm/psr7`
- the Parsedown packages

### Configuration changes

**From 1.40:**

- **`$wgParserEnableLegacyMediaDOM`:** check whether the default switched to the new `<figure>`-based image markup. If so, CSS that targets `.thumbinner`, `.thumbcaption` and similar classes stops matching. No such selectors were found in the Dante code. Check the bundled skins.
- **`$wgShellboxUrl`:** removed. It is not used here.
- **`$wgPrivilegedGroups`:** new. Add any custom user groups you define.
- **PBKDF2 passwords:** these now use OpenSSL when it is available.

**From 1.43:**

- **`$wgParserEnableLegacyHeadingDOM`:** leave it at `true` until the heading code listed under "Heading and table-of-contents markup" has been adapted.
- **`$wgEnableProtectionIndicators`:** new and optional.

### Database update

After switching the code, run:

```
php maintenance/run.php update
```

## Upgrade procedure

This repository holds all of MediaWiki core plus the Dante files, in a single commit. It is easier to upgrade the way [README-dante-delta.md](README-dante-delta.md) describes:

1. Install a clean MediaWiki 1.43 core. Use 1.40 only if you need it as an intermediate step.
2. Copy over these Dante files:
   - `extensions/Dante*`
   - `extensions/Parsifal` (a separate git repository)
   - `skins/DantePresentationSkin` and `skins/skinny`
   - `Dante*.php`, `LocalSettings.php`, `mediawiki-PRIVATE.php`
   - `composer.local.json`
3. Make required changes 1 and 5–9 in the Dante code.
   - Changes 1, 6, 7 and 9 also work on 1.39, so you can make them before the upgrade.
   - Changes 5 and 8 can't be made in advance. `maintenance/run.php` exists only from 1.40 on, and `mediawiki.cookie` provides the `$.cookie` functions only from 1.41 on.
4. Re-apply the core patches for UploadBase and WikiImporter (changes 2 and 4). For SVGReader (change 3), first test whether the patch is needed at all.
5. Install the matching branches of the bundled and third-party extensions.
6. Run `composer update`, then `php maintenance/run.php update`.
7. Test these areas:
   - **DanteBackup:** dump and restore, including importing drawio SVGs (with and without the SVGReader patch)
   - **Parsifal:** TeX rendering, format precompilation, and the "Parsifals" page property
   - **DantePresentations:** translation, endpoints, displaytitle handling (change 1) and the TOC injection
   - **DanteSnippets:** snippet jobs (change 6)
   - **DanteTree:** sidebar menus, and whether the tree state is still saved (change 8)
   - **DantePresentationSkin and skinny:** style loading (change 7)
   - **Logs:** check for any remaining deprecation warnings
