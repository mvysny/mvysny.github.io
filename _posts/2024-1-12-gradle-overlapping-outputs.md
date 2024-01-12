---
layout: post
title: Gradle - Overlapping Outputs
---

The documentation for [Gradle Overlapping Outputs](https://docs.gradle.org/current/userguide/build_cache_concepts.html#concepts_overlapping_outputs)
is a bit misleading: it explicitly states that you need two tasks, overwriting each other outputs.
However, the overlapping outputs behavior can easily be reproduced with just one task.

You can play with the build cache easily, by following my previous blogpost [Gradle: Understanding Build Cache](../gradle-build-cache/).

## Reproducing Overlapping Outputs

You can easily reproduce this behavior using e.g. the Java Compiler plugin. Prepare any
Gradle project which compiles java sources; for example [jdbi-orm-playground](https://gitlab.com/mvysny/jdbi-orm-playground)
is small and therefore perfect for this kind of experiment.

Now, run `./gradlew --build-cache --info clean compileJava` and focus on the `compileJava` task. During the first run,
the task is run in full since nothing is cached:

```bash
$ ./gradlew --build-cache --info clean compileJava
> Task :compileJava
Build cache key for task ':compileJava' is ce864edaed586425c96101bb691844fa
Task ':compileJava' is not up-to-date because:
  Output property 'destinationDirectory' file /home/mavi/work/my/jdbi-orm-playground/build/classes/java/main/playground/DatabaseUtils.class has been removed.
The input changes require a full rebuild for incremental task ':compileJava'.
Full recompilation is required because no incremental change information is available. This is usually caused by clean builds or changing compiler arguments.
```

Now we modify the output file ourselves:

```bash
$ echo "foo" >build/classes/java/main/playground/DatabaseUtils.class
$ ./gradlew --build-cache --info compileJava
> Task :compileJava
Caching disabled for task ':compileJava' because:
  Gradle does not know how file 'build/classes/java/main/playground/DatabaseUtils.class' was created (output property 'destinationDirectory'). Task output caching requires exclusive access to output paths to guarantee correctness (i.e. multiple tasks are not allowed to produce output in the same location).
Task ':compileJava' is not up-to-date because:
  Output property 'destinationDirectory' file /home/mavi/work/my/jdbi-orm-playground/build/classes/java/main/playground/DatabaseUtils.class has changed.
The input changes require a full rebuild for incremental task ':compileJava'.
```

## The Vaadin Plugin Case

TODO
