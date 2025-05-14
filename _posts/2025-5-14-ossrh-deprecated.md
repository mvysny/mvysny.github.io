---
layout: post
title: OSSRH deprecated in favor of Maven Central
---

The [Legacy OSSRH oss.sonatype.org](https://oss.sonatype.org/)
is [going to go away 30th June 2025](https://central.sonatype.org/news/20250326_ossrh_sunset/),
which means it will not be possible to release your libraries using the Legacy OSSRH API.
Users are [advised to migrate to Maven Central](https://central.sonatype.org/faq/what-is-different-between-central-portal-and-legacy-ossrh/#gradle).
The documentation suggests JReleaser to release to Maven Central, but JReleaser is a bloated nightmare.
Read more on a good alternative.

To summarize the madness, there are three endpoints when releasing to Maven Central:

1. The [Legacy OSSRH ossh.sonatype.org](https://oss.sonatype.org/) which is going to go away.
2. The new [Maven Central Publisher](https://central.sonatype.com/publishing) portal
   ([Gradle docs](https://central.sonatype.org/publish/publish-portal-gradle/)).
   It uses a new REST API incompatible with the Legacy OSSRH API. You need
   JReleaser to release via this API.
3. The [OSSRH Staging API](https://central.sonatype.org/publish/publish-portal-ossrh-staging-api/)
   which uses the same API as the Legacy OSSRH, but this one
   is NOT scheduled to be deprecated (yet).

I tried to use JReleaser and failed (too complex). Then I realized I can use existing Gradle plugins to
release using the OSSRH REST API protocol, but to Maven Central (the third option).
In order to do that, you need:

1. [Migrate your namespaces to Maven Central](https://central.sonatype.org/faq/what-is-different-between-central-portal-and-legacy-ossrh/#gradle)
2. Generate User Token at your [Maven Central Publisher Account](https://central.sonatype.com/account):
   you need this token to publish to the OSSRH Staging API.
3. Update your Gradle plugin to release to `https://ossrh-staging-api.central.sonatype.com/service/local/`

I'm using the [Gradle Nexus Publish Plugin](https://github.com/gradle-nexus/publish-plugin)
which not only is capable of uploading your released library to a staging repository,
but also close and release the repository as well, allowing you to upload
your library to Maven Central purely via Gradle command line.

To achieve that:

1. See [konsume-xml](https://gitlab.com/mvysny/konsume-xml) `build.gradle.kts` for an example.
2. After the plugin is fully configured, simply run `/gradlew clean build publish closeAndReleaseStagingRepositories`
   to release to Maven Central.
3. While the command is running, you can follow the progress at [Maven Central Publisher](https://central.sonatype.com/publishing)
