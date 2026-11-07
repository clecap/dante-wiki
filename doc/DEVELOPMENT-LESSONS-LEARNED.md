# Development: Lessons Learned

Things that cost time to find out, so nobody has to find them out again.

## Dockerfile

### ARGs and build stages

* An `ARG` inside a stage is visible only in that stage.
* An `ARG` before the first `FROM` has global scope, but is visible only in the `FROM` lines. To use it inside a
  stage, the stage must redeclare it with a bare `ARG NAME` (no value); it then inherits the global default or the
  `--build-arg` value.

```dockerfile
ARG TL_YEAR=2026              # global: one place for the value

FROM debian:... AS texlive-ready
ARG TL_YEAR                   # needed, otherwise TL_YEAR is empty in this stage
```

* A changed `ARG` value invalidates the docker cache of every later step that uses it. Therefore the version
  (`DANTE_VERSION`) is set at the very end of the Dockerfile (see [DEVELOPMENT-CI.md](DEVELOPMENT-CI.md)).

### Options in a variable must be expanded without quotes

To use a variable holding several options, write `curl ${CURL_OPTS} ...`, not `curl "${CURL_OPTS}" ...`.
Quoted, curl receives all options as one single argument and fails.

### curl: retry also "permanent" errors

Downloads failed with `curl: (35) Recv failure: Connection reset by peer` (connection reset during the TLS handshake).
`--retry` alone does not help, since curl considers this error permanent. All downloads therefore use

```
curl --retry 5 --retry-delay 10 --retry-all-errors ...
```

### TeX Live: fixed mirror instead of mirror.ctan.org

`mirror.ctan.org` redirects every request to a random mirror. Some mirrors had broken TLS certificates, and the ISO,
its `.sha512` and its `.sha512.asc` could come from mirrors at different states. We use one fixed mirror. This is safe,
since the ISO is checked against the GPG-signed sha512 hash.

### TeX Live: the ISO download

The ISO is about 6 GB. The docker layer cache does not avoid downloading it again in many cases:

* `--no-cache` builds (`buildNoCache`, `generate-nocache.sh`) always download again.
* A multi-arch build (amd64 + arm64) runs the stage once per platform and downloads twice.
* `docker builder prune` or a full disk removes the cached layer.
* On GitHub Actions every run starts on a fresh machine with an empty cache.

The solution is a **BuildKit cache mount**:

```dockerfile
RUN --mount=type=cache,id=texlive-iso,target=/cache,sharing=locked  ...
```

* `/cache` is a directory of the local builder. It survives from build to build, also `--no-cache` builds, and is
  shared by all platforms. Its content never ends up in the image, which also saves a 6 GB layer.
* Every build downloads only the small `.sha512` and `.sha512.asc` files and verifies the signature. If the cached ISO
  matches the hash, it is used; otherwise (missing, damaged, other TeX Live year, reissued upstream) it is downloaded
  again. Files of other years are deleted from the cache.
* The ISO is downloaded to `….part` and renamed only when complete, so an interrupted download never looks complete.
* `sharing=locked`: amd64 and arm64 build in parallel; one waits until the other has downloaded, then reuses the file.
* On GitHub Actions the cache is empty on every run, so it still downloads there (fast in the data center).
* Show and clear the cache:

```bash
docker buildx du --verbose | grep -A3 texlive-iso        # size of the cache
docker builder prune --filter type=exec.cachemount       # clear all cache mounts
```

### sudo in the image is needed

The image runs as `www-data`, and the startup scripts (`run-apache.sh`, `install-webserver-certificate.sh`, ...)
call `sudo` to configure and start apache. Removing sudo from the image breaks the container start.

### PHP does not see environment variables

php-fpm clears the environment of its workers by default (`clear_env`), so `getenv('DANTE_VERSION')` may return
nothing. Information for PHP goes into a file instead, e.g. `/etc/dante-version`.

## GitHub Actions

### Pushes by the workflow do not start workflows

A tag or commit pushed with the default `GITHUB_TOKEN` does not trigger other workflows. This avoids endless loops,
but means a tag created by the version job cannot start a build; the build therefore runs in the same workflow as
a second job.

### git describe needs the full history

`actions/checkout` fetches only the last commit and no tags by default. For `git describe` and for finding the last
version tag, the checkout needs `fetch-depth: 0`.

### git describe picks up any tag

`git describe --tags` uses every tag, e.g. a stray tag `test`. Version computations therefore use
`--match 'v[0-9]*.[0-9]*.[0-9]*'`.
