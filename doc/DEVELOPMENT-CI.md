# Continuous Integration

## Version numbers

The version of DanteWiki has the form `MAJOR.MINOR.PATCH` and lives in **git tags** of the form `vMAJOR.MINOR.PATCH`
(e.g. `v0.1.0`). There is no version file in the repository. Numbering started at `0.0.0`.

### How to raise the version

The first line of a commit message decides. Start it with one of these keywords (lowercase, followed by a colon):

| Commit message starts with | Effect                                        | Example                                       |
|----------------------------|-----------------------------------------------|-----------------------------------------------|
| `bump:`                    | increase PATCH                                | `bump: fix typo in login page`  0.1.4 → 0.1.5 |
| `feat:`                    | increase MINOR, reset PATCH to 0              | `feat: add LDAP login`          0.1.5 → 0.2.0 |
| `break:`                   | increase MAJOR, reset MINOR and PATCH to 0    | `break: new configuration format` 0.2.0 → 1.0.0 |
| anything else              | no new version                                | `Fixes`                                       |

* A push with several commits raises the version **once**, by the highest kind found
  (`bump:` and `feat:` together give one MINOR increase).
* Commits without a keyword are collected and become part of the next version that is raised.
* The very first run (no version tag yet) only looks at the commits of that push, not at the older history.

### What happens on a push

On every push to `master`, the workflow [docker-multiarch-build.yml](../.github/workflows/docker-multiarch-build.yml) runs two jobs:

1. **`version`**: [.github/scripts/next-version.sh](../.github/scripts/next-version.sh) reads the commit messages since
   the last version tag and computes the next version. If there is one, the job creates the tag on the pushed commit and
   pushes the tag. The run page shows the result ("New version: v…" or "No new version").
2. **`build-and-push`**: builds the docker image and pushes it to dockerhub as `clecap/dante-wiki:latest` and
   `clecap/dante-wiki:dev`, plus `clecap/dante-wiki:MAJOR.MINOR.PATCH` if a new version was created.
   Git tag and image tag thus always belong to the same commit.

A manual run (*Actions → Build and push multi-arch image → Run workflow*) only builds; it does not create a version.

Pushes in quick succession are processed one after the other, so two runs never claim the same version number.

### Working locally

Only a tag is created, never a commit, so the branch does not change and **no pull is needed** after a push.
To see the version tags locally:

```bash
git fetch --tags                 # get the tags created by GitHub
git describe --tags --abbrev=0   # show the current version, e.g. v0.1.0
```

To preview which version the next push would create:

```bash
.github/scripts/next-version.sh   # prints e.g. 0.1.1, or nothing if no commit asks for a new version
```

(Run `git fetch --tags` first, otherwise the script does not know the latest version.)

### Version inside the docker image

Every build passes the version of the checked out source into the image as build argument `DANTE_VERSION`.
It is computed by `git describe --tags --always --match 'v[0-9]*.[0-9]*.[0-9]*'`:

| Built from                          | `DANTE_VERSION`        |
|-------------------------------------|------------------------|
| a commit with a version tag         | `v0.1.0`               |
| 3 commits after that tag            | `v0.1.0-3-gabc1234`    |
| before the first version tag        | `abc1234` (commit hash)|
| outside a git repository / not set  | `unknown`              |

All builds do this the same way: the workflow, `build` and `buildNoCache` in [bin/library.sh](../bin/library.sh)
and [generate-cache.sh](../images/dante-wiki/bin/generate-cache.sh) / [generate-nocache.sh](../images/dante-wiki/bin/generate-nocache.sh).

The software reads the version in one of three ways:

| Where                          | How                                                                                         |
|--------------------------------|---------------------------------------------------------------------------------------------|
| PHP, MediaWiki                 | `trim(file_get_contents('/etc/dante-version'))`                                             |
| shell scripts in the container | `$DANTE_VERSION`                                                                            |
| from outside the container     | `docker inspect --format '{{index .Config.Labels "org.opencontainers.image.version"}}' IMAGE` |

PHP should use the file: php-fpm clears the environment of its workers by default (`clear_env`),
so `getenv('DANTE_VERSION')` may return nothing.

The version is set at the very end of the [Dockerfile](../images/dante-wiki/src/Dockerfile). Keep it there: a changed
build argument invalidates the docker cache of every later step, so near the top every new version would rebuild
everything, including the TeX Live installation.
