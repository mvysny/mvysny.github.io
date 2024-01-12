---
layout: post
title: Gradle - Understanding Build Caching
---

The documentation for [Gradle Build Cache](https://docs.gradle.org/current/userguide/build_cache.html)
is great and goes in depth but it lacks a quick "getting started" examples. Let me therefore explain the difference between UP-TO-DATE and FROM-CACHE,
and reach out to the official documentation if you have any further questions.

## UP-TO-DATE

When a task declares its inputs and outputs, Gradle will calculate the hashes of all input and output files.
Upon next run, if all output files are there and no file has been changed (detected by the remembered hash),
Gradle may decide to skip the task since output files are already there. Say, if we're compiling java files and the class files
are already present in `build/classes/java/main`, we can skip the compilation and speed up
the build process. This is what happens when the task is marked `UP-TO-DATE`:

```bash
> Task :compileJava UP-TO-DATE
Build cache key for task ':compileJava' is ce864edaed586425c96101bb691844fa
Skipping task ':compileJava' as it is up-to-date.
```

To force the re-run of the task, just remove the output files, e.g. by running `./gradlew clean`. Now the
java compiler will print:
```bash
Task ':compileJava' is not up-to-date because:
  Output property 'destinationDirectory' file /home/mavi/work/my/jdbi-orm-playground/build/classes/java/main/playground/DatabaseUtils.class has been removed.
```
and will run fully.

## FROM-CACHE

Additionally, Gradle can store the output files in its build cache. That way, even if `build/` folder is
deleted via `./gradlew clean`, Gradle will simply fill in the output class files from its
cache and will skip the actual run of the `compileJava` task. This behavior is not enabled by default and
is enabled via `--build-cache`. This is what happens when the task is marked `FROM-CACHE`:

```bash
> Task :compileJava FROM-CACHE
Build cache key for task ':compileJava' is ce864edaed586425c96101bb691844fa
Task ':compileJava' is not up-to-date because:
  Output property 'destinationDirectory' file /home/mavi/work/my/jdbi-orm-playground/build/classes/java/main/playground/DatabaseUtils.class has been removed.
Loaded cache entry for task ':compileJava' with cache key ce864edaed586425c96101bb691844fa
```

Even though the task was not up-to-date (since we deleted the `build/` folder via `./gradlew clean`), Gradle was still
able to avoid running the task since it re-used the build cache and copied the output files from its cache.

To force the re-run of the task, either omit the `--build-cache` command-line switch,
or delete the build cache:

```bash
./gradlew --stop
rm -rf ~/.gradle/caches/build-cache-1
```

## Playing with Build Cache

You can use any Java project to play with this; [jdbi-orm-playground](https://gitlab.com/mvysny/jdbi-orm-playground)
is perfect for our purposes since it contains only a couple of Java soources and has only a handful of dependencies.

First we'll run the task in full:
```bash
$ ./gradlew --info clean compileJava
> Task :compileJava
Caching disabled for task ':compileJava' because:
  Build cache is disabled
Task ':compileJava' is not up-to-date because:
  Output property 'destinationDirectory' file /home/mavi/work/my/jdbi-orm-playground/build/classes/java/main/playground/DatabaseUtils.class has been removed.
The input changes require a full rebuild for incremental task ':compileJava'.
Full recompilation is required because no incremental change information is available. This is usually caused by clean builds or changing compiler arguments.
```

The task ran in full since there's no `UP-TO-DATE` nor `FROM-CACHE`, the build cache is disabled
(since we haven't used `--build-cache`) and output files were missing (since `clean` deleted the `build/` folder).

Now let's run the command without cleaning up the `build/` folder:
```bash
$ ./gradlew --info compileJava
> Task :compileJava UP-TO-DATE
Caching disabled for task ':compileJava' because:
  Build cache is disabled
Skipping task ':compileJava' as it is up-to-date.
```

Caching is still disabled, but Gradle detected that all output files are already present in the `build/` folder,
and therefore it knows that the task can be skipped since it is up to date.

Now let's enable the build cache and run the task again:
```bash
$ ./gradlew --build-cache --info clean compileJava
> Task :compileJava
Build cache key for task ':compileJava' is ce864edaed586425c96101bb691844fa
Task ':compileJava' is not up-to-date because:
  Output property 'destinationDirectory' file /home/mavi/work/my/jdbi-orm-playground/build/classes/java/main/playground/DatabaseUtils.class has been removed.
The input changes require a full rebuild for incremental task ':compileJava'.
Stored cache entry for task ':compileJava' with cache key ce864edaed586425c96101bb691844fa
```

The task was not up-to-date since we cleaned the `build/` folder, but now we see that the output
files have been stored into Gradle build cache.

> If the task says FROM-CACHE, the build cache might be populated from previous experiments.
> Clean the cache by running `./gradlew --stop; rm -rf ~/.gradle/caches/build-cache-1`

Finally, let's run the same command:
```bash
$ ./gradlew --build-cache --info clean compileJava
> Task :compileJava FROM-CACHE
Build cache key for task ':compileJava' is ce864edaed586425c96101bb691844fa
Task ':compileJava' is not up-to-date because:
  Output property 'destinationDirectory' file /home/mavi/work/my/jdbi-orm-playground/build/classes/java/main/playground/DatabaseUtils.class has been removed.
Loaded cache entry for task ':compileJava' with cache key ce864edaed586425c96101bb691844fa
```
The task is not up-to-date since `clean` deleted the `build/` folder, however Gradle
found a build cache entry for the input files and was able to copy the output files
from the build cache, therefore skipping the execution of the task and marking it `FROM-CACHE`.
