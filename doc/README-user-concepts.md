# Database User Concepts

This document explains how dante-wiki uses its two database accounts, why `install.php` is called
differently from what the MediaWiki documentation suggests, and what to watch out for.

The source references below are to MediaWiki branch `REL1_43`.


## The two accounts

| Variable                         | Role             | Privileges on `${MY_DB_NAME}`                                    | Used by |
|----------------------------------|------------------|-------------------------------------------------------------------|---------|
| `MY_DB_I_USER` / `MY_DB_I_PASS`  | installer        | `ALL PRIVILEGES` (but no `GRANT OPTION`)                          | `install.php`, `update.php` |
| `MY_DB_USER` / `MY_DB_PASS`      | normal operation | `SELECT, INSERT, UPDATE, DELETE, CREATE TEMPORARY TABLES`         | the running wiki (`$wgDBuser` in `LocalSettings.php`) |

Both accounts are created by `createDBandUsers` in `dantescript/common-defs.sh`, called from
`dantescript/prepare-database.sh`, using the database `root` account. They are defined for the
private network ranges `172.16.0.0/255.240.0.0` and `192.168.0.0/255.255.0.0` only.


## Two different models

### MediaWiki's model: separation between databases

MediaWiki assumes the installer is given the database superuser (the help text of `install.php` says
`--installdbuser  The user to use for installing (root)`). The installer then does all database
administration itself:

- it creates the database,
- it creates the wiki user (`--dbuser`, default `wikiuser`),
- it grants that user **all privileges on the wiki database**.

The wiki user may do anything inside its own database, but nothing outside of it.
The MediaWiki manual recommends exactly this when setting up the user by hand:
`GRANT ALL PRIVILEGES ON wikidb.* TO 'wikiuser'@...`.

This is a convenience default for the common case (shared hosting, or a single admin with `root`
who wants a working wiki in one step). It is not a bug.

### dante-wiki's model: separation between tasks

dante-wiki uses a stricter model:

- The database `root` account sets up the database and both users beforehand (`createDBandUsers`).
- The installer account `MY_DB_I_USER` may change the schema, but may not grant privileges.
- The running wiki uses `MY_DB_USER`, which may only read and write data.

The running wiki thus cannot change its own table structure. A compromise of the web server
does less damage.


## Where the two models clash

The documented call would be

```
install.php --installdbuser "$MY_DB_I_USER" --installdbpass "$MY_DB_I_PASS" \
            --dbuser        "$MY_DB_USER"   --dbpass        "$MY_DB_PASS"  ...
```

What MediaWiki does with this:

1. **`--installdbuser` also switches on account creation.**
   `includes/installer/CliInstaller.php` (around line 100): if `installdbuser` is given, the installer sets
   `_CreateDBAccount = true` ("Assume that if we're given the installer user, we'll create the account").

2. **An install step `user` runs before the step `tables`.**
   `includes/installer/MysqlInstaller.php`, `setupUser()` (around line 369):
   - If `wgDBuser == _InstallUser`, it returns immediately and does nothing.
   - Otherwise it builds the name `'<wgDBuser>'@'<wgDBserver>'` (`buildFullUserName()` uses the database
     server name as host part) and executes
     `GRANT ALL PRIVILEGES ON <dbname>.* TO '<wgDBuser>'@'<wgDBserver>'`.
     This GRANT is also done when no account is to be created (the `else` branch).
   - A failing GRANT is reported as `fatal`.

3. **A fatal step stops the installation.**
   `includes/installer/Installer.php`, `performInstallation()`: `if ( !$status->isOK() ) break;`
   This happens before any table is created.

In our setup this GRANT cannot work:

- `MY_DB_I_USER` has no `GRANT OPTION`, so the GRANT is refused and the installation aborts.
- The account `'<MY_DB_USER>'@'<MY_DB_HOST>'` does not exist (our accounts exist only for the network
  ranges above). MariaDB's default `sql_mode` contains `NO_AUTO_CREATE_USER`, so the GRANT would not
  create it either.
- Even if it worked, `MY_DB_USER` would get `ALL PRIVILEGES`, which defeats the purpose of the
  restricted account.

MediaWiki has no option meaning "the accounts already exist, do not create or grant anything".
Neither the CLI installer nor the web installer offers this: whenever the two accounts differ,
the GRANT is issued.


## The workaround used in dante-wiki

`dantescript/init.sh` calls

```
install.php --dbuser "$MY_DB_I_USER" --dbpass "$MY_DB_I_PASS" ...      # no --installdbuser
```

1. Without `--installdbuser`, `_InstallUser` is set to `wgDBuser`. Both are `MY_DB_I_USER`.
2. `setupUser()` therefore returns at once, no account is created and nothing is granted.
3. `install.php` creates the tables as `MY_DB_I_USER` and writes `LocalSettings.php` with
   `$wgDBuser` / `$wgDBpassword` set to the installer account.
4. `init.sh` then appends `$wgDBuser` / `$wgDBpassword` for `MY_DB_USER` to `LocalSettings.php`.
   The later assignment wins, so the wiki runs as the restricted account.

Result: install with the strong account, run with the weak one. This is the same goal MediaWiki
pursues, done by hand because MediaWiki's way fails in our setup.


## Things to watch

- **Installer password in `LocalSettings.php`.** The lines written by `install.php` (with
  `MY_DB_I_PASS`) remain in the file in plain text, even though they are overridden.
- **Schema changes need the installer account.** `update.php` must be run with
  `--dbuser "$MY_DB_I_USER" --dbpass "$MY_DB_I_PASS"`; `doMaintenanceUpdate` in `common-defs.sh` does this.
  Other maintenance scripts run without `--dbuser` use `$wgDBuser`, i.e. the restricted account.
- **`$wgDBadminuser` / `$wgDBadminpassword` are not set.** Setting them to the installer account would let
  maintenance scripts pick up the privileged account automatically, at the price of deliberately keeping
  the installer password in `LocalSettings.php`.
- **Extensions that create tables at runtime** would fail under `MY_DB_USER`. Their tables must be
  created via `update.php`.
