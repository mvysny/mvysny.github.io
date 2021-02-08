---
layout: post
title: JCenter is dead, long live Maven Central
---

According to Bintray blogpost, [Bintray and JCenter are dead effective May 2021](https://jfrog.com/blog/into-the-sunset-bintray-jcenter-gocenter-and-chartcenter/).
That's too bad - I've been using Bintray to avoid Maven Central ridiculously complex deployment process.
Looks like that can not be avoided anymore.

Here I've summarized the steps which a Gradle-based project needs to take in order
to be published successfully onto Maven Central.

First, read the [How to publish artifact to Maven Central via Gradle](https://www.albertgao.xyz/2018/01/18/how-to-publish-artifact-to-maven-central-via-gradle/)
blog post, it's a good starter and explains the entire process in a sane way.
Read it until the section "5.Set up your project to upload"
and stop there; the `com.bmuschko` plugin is not needed, in fact it's easier to not to use the
plugin. A couple of remarks:

1. I've put the signing key credentials and Sonatype nexus username/password
   into the `~/.gradle/gradle.properties`. That way, I will never commit
   the file accidentally into git and publish into github.
2. If you're stuck with the OSSRH registration, this blogpost can help:
   [How to publish artifacts on maven central](https://blog.10pines.com/2018/06/25/publish-artifacts-on-maven-central/).
3. You may need to publish the GPG key on a couple of key servers;
   the official [Maven Central: Working with PGP Signatures](https://central.sonatype.org/pages/working-with-pgp-signatures.html)
   documentation suggests `hkp://pool.sks-keyservers.net`.
4. Interesting - the key doesn't have to be signed by anyone from Sonatype, which
   sounds like anyone can generate those keys... well /shrug.

In order to sign the artifact and upload it to Maven Staging Repository please use the `signing` plugin and `maven-publish` plugin.
* A very simple one-module setup is outlined in this example project: [single-project build.gradle.kts](https://gitlab.com/mvysny/jdbi-orm/-/blob/master/build.gradle.kts)
* Multi-project setup can take advantage of a reusable closure as explained
  here: [multi-project build.gradle.kts](https://github.com/mvysny/karibu-testing/blob/master/build.gradle.kts)

## Official Guide

The official guide is ridiculously long and links to videos which are ridiculously
long: [OSSRH-Guide](https://central.sonatype.org/pages/ossrh-guide.html).
You can read it if you're hopelessly stuck, otherwise just ignore.
