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
* Use `--cache-to` and `--cache-from` to have the docker builder use separate caches for separate projects.

For security reasons, when using CI/CD for many projects (and especially if you don't completely trust those projects),
it's better to use separate cache folders, one per every project.

## Multiple builders

Useful commands:
* Use `docker buildx create --name xyz` to create a new builder,
* use `docker buildx ls` to list the builders,
* use `docker buildx rm xyz` to delete a builder and all of its caches
* use `docker buildx du --builder xyz` to get info on disk space occupied by caches for a particular builder
* use `docker buildx build --builder xyz` to build a Docker image using given builder

TODO more
