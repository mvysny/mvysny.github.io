---
layout: post
title: Docker buildx mount cache
---

The [docker buildx](https://docs.docker.com/reference/cli/docker/buildx/) build cache
documentation is surprisingly hard to find, so I'll write up all I learned here.

To speed up repeated builds of Gradle/Maven projects on your machine (think CI/CD server),
you can cache the contents of the `~/.m2` and/or `~/.gradle` folder. That will cause
jar dependencies downloaded from Maven Central to be cached between builds: they
do not have to be re-downloaded every time the build commences. That makes
your build run faster, but also decreases the load on the server hosting Maven Central.

The way to do this is to [use cache mounts](https://docs.docker.com/build/cache/optimize/#use-cache-mounts).
You need to add the [--mount=type=cache](https://docs.docker.com/reference/dockerfile/#run---mounttypecache) flag to your `RUN` instruction, e.g.

```dockerfile
FROM openjdk:17
RUN --mount=type=cache,target=/root/.m2 --mount=type=cache,target=/root/.vaadin ./mvnw clean package -Pproduction
RUN --mount=type=cache,target=/root/.gradle --mount=type=cache,target=/root/.vaadin ./gradlew clean build -Pvaadin.productionMode --no-daemon --info --stacktrace
```

The cache mount is persisted across builds, so even if you end up rebuilding the layer, you only download new or changed packages.
Any changes to the cache are persisted across builds, and the cache is shared between multiple builds.

## Keeping the cache in check

You can learn the size of the cache by running
```bash
$ docker system df
```
Clearing the cache:
```bash
$ docker system prune
```

## The cache is shared

By default, all docker builds use the same builder environment, and the cache is shared and keyed by the mount point (see the `id` option which defaults to `target`):

* `--mount=type=cache,target=/root/.m2` is a different cache than `--mount=type=cache,target=/root/.vaadin` because the target is different
* However, all builders using `--mount=type=cache,target=/root/.gradle` mount the same folder and gain parallel access to it.

Parallel builds access the same folder at the same time, which doesn't work well with build tools:

* Maven has no protection for this and would fail with random errors, potentially corrupting the cache
* Gradle will create `.lock` files; if the build running in one builder takes too long, Gradle in other builder
  will timeout obtaining the lock and will fail the build randomly.

There are multiple solutions:

* Use `sharing=locked` or `sharing=private` option: that causes `docker build` to get exclusive access to the cache, waiting for other
  concurrent builds if necessary.
  * Advantages: cache is shared, so the disk space occupied is low. Builds are faster since jar deps downloaded by one project
    are reused by other projects as well.
  * Disadvantages: fragile: if the project's `Dockerfile` doesn't mention `sharing=locked` then
    the cache is shared and may become corrupted. Also, it's possible for a rogue project to pollute `~/.m2/repository`
    cache by publishing infected jar dependencies. Also, the builds may need to wait to obtain exclusive access,
    causing the builds to run slower.
* Use multiple builder instances: [docker buildx create](https://docs.docker.com/reference/cli/docker/buildx/create/).
  * Solves the disadvantages of `sharing=locked`
  * Uses **way** more disk space: not only will the build cache be separated, but also the image cache: every builder will download its own `openjdk:17`,
    causing massive disk space usage.
  * Also, the builder builds the image into its own repository, and you need to pull the image into the main registry.
* Use the [external cache](https://docs.docker.com/build/cache/optimize/#use-an-external-cache): `--cache-to` and `--cache-from` to have the docker builder use separate caches for separate projects.
  * `local` cache is only supported by Docker 24+ when using containerd image store (see below)
* Use [--cache-id](https://dockerpros.com/wiki/dockerfile-cache-id/) to have separate caches per project
  * TODO does this actually work for cache mounts? If yes that's great - certainly simpler than having to manage external local cache.

For security reasons, when using CI/CD for many projects (and especially if you don't completely trust those projects),
it's better to use separate cache folders, one per every project.

## Multiple builders

Useful commands:
* Use `docker buildx create --name xyz` to create a new builder,
* Use `docker buildx ls` to list the builders,
* Use `docker buildx rm xyz` to delete a builder and all of its caches
* Use `docker buildx du --builder xyz` to get info on disk space occupied by caches for a particular builder
* Use `docker buildx build --builder xyz` to build a Docker image using given builder
* Use `docker buildx rm xyz` to stop and remove given builder completely, including its build caches, image caches and any images the builder has built.

## Separate local caches

The easiest way is to use `--cache-to` and `--cache-from` with the [Local cache](https://docs.docker.com/build/cache/backends/local/#cache-versioning).
You create a cache dir for every project you build, then you run, say, `/var/cache/mydockercaches/project1`; then:
```bash
$ docker build --cache-from type=local,src=/var/cache/mydockercaches/project1 --cache-to type=local,dest=/var/cache/mydockercaches/project1 -t test/vaadin-boot-example-maven:latest .
```

Notes:

* When you run `docker system prune -a`, the cache files will stay but next build will seem not to use them;
  * probably it's a good idea to nuke all local caches as well.
* You can delete the cache files simply via `rm -rf`; the cache will be re-populated on next run.
* Re-running the build seems to always add a couple of mb to the cache - probably the created app image is cached there as well.
* These caches are not gc-ed automatically by Docker, nor are they included in `docker system df`. You need to clear them yourself.
* The size of the cache is somewhere around 400mb when building a simple Maven project.

Maybe it's better to go next-level and use the [Depot](https://depot.dev) cache manager: to be seen.

## Troubleshooting

If `type=local` cache fails with
```
ERROR: Cache export is not supported for the docker driver.
Switch to a different driver, or turn on the containerd image store, and try again.
Learn more at https://docs.docker.com/go/build-cache-backends/
```
you need to [enable containerd image store](https://dille.name/blog/2023/05/10/testing-docker-with-containerd-image-store-without-docker-desktop/):
edit `/etc/docker/daemon.json` and make sure `containerd-snapshotter` is enabled:
```json
{
  "features": {
    "containerd-snapshotter": true
  }
}
```
Restart docker daemon:
```bash
$ systemctl restart docker.service
```
Verify that the setting took effect:
```bash
$ docker info|grep driver-type
  driver-type: io.containerd.snapshotter.v1
```
Note: this only works with Docker 24+.

## Further read

* [Cache strategies](https://dockerpros.com/wiki/dockerfile-cache-strategy/)
* [docker buildx build](https://docs.docker.com/reference/cli/docker/buildx/build/)
* [Depot](https://depot.dev)
