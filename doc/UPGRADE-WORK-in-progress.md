# DanteWiki Upgrade Analysis: MediaWiki 1.39 → 1.40 → 1.43


get-dante.sh loads a parametrized branch of dante-delta which me must adjust.  in common-defs.sh we have:
# the name of the branch to which we will clone
DANTE_BRANCH=master

and then get-dante.sh is an unfortunate loading rpocess..




Adjust the php.ini and other files in docker home area. especially the php8.2 directory


Fi xin get-dante.sh
# The default operational mode after a get-dante.sh always is production mode
## cp $MOUNT/$TARGET/DanteSettings-production.php $MOUNT/$TARGET/DanteSettings-used.php
cp $MOUNT/$TARGET/DanteSettings-development.php $MOUNT/$TARGET/DanteSettings-used.php

ENSURE that the irght startign stuff is copied in!


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





## Deprecations and cleanups

These still work in 1.43, but they will break in a later release. The ones marked "warns from" write deprecation warnings to the logs from that version on.

| Item | Where | Status | Fix |
|---|---|---|---|

| `ContentHandler::getContentText()` | DantePolyfill, InfoExtractor, Translate, SubTranslate, danteEndpoint, TreeAndMenu_body, Parsifal (FullPage, TeXGenerator) | warns from 1.43 | `$content instanceof TextContent ? $content->getText() : null` |



| Dynamic properties on `Parser` | [TexProcessor.php:78](extensions/Parsifal/php/TexProcessor.php#L78) (`$parser->storePreamble`), [danteEndpoint.php:189](extensions/DantePresentations/endpoints/danteEndpoint.php#L189) (`$parser->danteTag`) | warns from 1.42 | Store the value with `ParserOutput::setExtensionData()`, or in a static or service property. |



| `mediawiki.ui.icon`, `mediawiki.ui.button` | [DantePresentationSkin skin.json](skins/DantePresentationSkin/skin.json), [skinny skin.json](skins/skinny/skin.json) | console warnings from 1.41 | Remove them, or use Codex CSS components. |



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


- **Parsifal:** besides the items listed above, no removed API is used.
  - [FullPage.php](extensions/Parsifal/php/FullPage.php) contains `FullPageAction`. It already passes both `$article` and `$context` to the `Action` constructor, as 1.40 requires.
  - `FullPageAction` is not registered under `Actions` in `extension.json`, so it is dead code.
  - `$article->mTitle` in [TexProcessor.php](extensions/Parsifal/php/TexProcessor.php) is inside a commented-out block.

- **Custom skins:**
  - Both DantePresentationSkin and skinny extend `SkinMustache`. They use none of the removed Skin methods (`getFooterLinks`, `getSiteFooterLinks`, `getAfterPortlet`, `get`/`setSearchPageTitle`).
  - The mustache template keys they use (`html-title-heading`, `html-body-content`, `html-after-portal`, `array-indicators`, `html-user-language-attributes`, …) are not listed as removed. `html-hello` is a key the skins define themselves.


## Other work around the upgrade

### Bundled and third-party extensions

These third-party extensions each need a release that supports the target version:

| Extension | Current version | Requires MediaWiki |
|---|---|---|

| WikiMarkdown | 1.1.3 | ≥ 1.34 |
| SubPageList (composer) | 3.0.1 | ≥ 1.36.0 |

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


## Upgrade procedure

7. Test these areas:
   - **DanteBackup:** dump and restore, including importing drawio SVGs (with and without the SVGReader patch)
   - **Parsifal:** TeX rendering, format precompilation, and the "Parsifals" page property
   - **DantePresentations:** translation, endpoints, displaytitle handling (change 1) and the TOC injection
   - **DanteSnippets:** snippet jobs (change 6)
   - **DanteTree:** sidebar menus, and whether the tree state is still saved (change 8)
   - **DantePresentationSkin and skinny:** style loading (change 7)
   - **Logs:** check for any remaining deprecation warnings


TROUBLE SECURITY WISE: Every changed extension is unpinned since it is installed ad lib over github and
anybody could smuggle stuff inside !!!!!



Use newest MariaDB compatible.

Use phpmyadmin.


TODO:
CAVE: Every Database dump contains the ASW and github tokens. This is not what we want !!!


Make and check test pages for every extension and all the features in the extension.



Add semantic mediawiki extension.

Bluespice:
 An enterprise-ready distribution built directly on top of MediaWiki that adds formal workflow approvals, PDF bookmakers, extended rights management, metadata forms, and technical documentation portals tailored for quality management



The Dante content was never loaded into this wiki. The database had only one page, Main_Page. The sidebar is built from MediaWiki:Sidebar and its subpages, and none of them existed. init.sh tries to import the Sidebar page, but that step failed without any error message. No script loads minimal-initial-contents.xml at all. As you chose, I imported the whole XML file (82 pages: the MediaWiki: config pages, the sidebar subpages, Common.js, gadgets, Parsifal templates, and the Help/Test pages). I then rebuilt Recent Changes and the site statistics, and deleted the stale sidebarcache file.





We need to expire the ParserCache whenever we change a template.

We need to clean up the parsifal cache regularly.
Have a special whcih does this for Parsifal: Bulk purge: run php maintenance/run.php purgeParserCache to remove old entries or which
does a purge for all pages with a parisfal tag.