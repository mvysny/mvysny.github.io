---
layout: post
title: Building Docker Multi-Platform images of Vaadin apps on Ubuntu Linux
---

A multi-platform build refers to a single build invocation that targets multiple different
operating system or CPU architecture combinations. When building images, this lets you
create a single image that can run on multiple platforms, such as `linux/amd64`, `linux/arm64`.

However, when you start reading the official documentation at [Dockerdocs: Multi-platform](https://docs.docker.com/build/building/multi-platform/),
things start to get complicated fast. When reading the documentation, it looks like there are
three options:

- Using emulation via QEMU: this option gets complicated fast. The guide tells you to install some third-party
  `tonistiigi/binfmt` image in privileged mode. [There is a much easier way](https://www.staldal.nu/tech/2023/02/10/how-to-enable-multi-platform-docker-builds-on-ubuntu-22-04/),
  but unfortunately the QEMU emulation seems to be bothering Vite (which builds Vaadin frontent):
  when building x86_64 image on arm64, Vite in QEMU crashes with a nasty stacktrace. On top of that,
  the build is really slow (understandably).
  So, we need to rule out this option.
- Multiple native modes: requires you to have multiple machines running on all target platforms.
  That sounds complicated too.
- Cross-compilation: it requires the build tool to run on one architecture
  while producing binaries for some other architecture. It sounds uber-complicated until
  you realize that this is exactly what Java and Vite does. Let's pursue this option.

## Cross-compilation

Cross-compilation is the process of compiling code for one computer system,
often referred to as the target, on a different system, called the host.

This means that we could build the app on the native platform, then package
the resulting binaries into multiple Docker images, one for every target architecture.

With Java, JavaScript and Vaadin, this is actually even simpler than it sounds:
both Java and JavaScript toolchain produce the same result, capable of running
on any architecture, regardless of where you compile. In other words,
javac can run on any platform and it always produces a bunch of jar files, which are then
capable of running on any platform too. The same goes for Vite and the JavaScript toolchain.

Let's take advantage of this and let's build a simple app,
[vaadin-boot-example-gradle](https://github.com/mvysny/vaadin-boot-example-gradle/).

## Setup

Before we start, we need two things:

- You need to install docker buildx extension: `$ sudo apt install docker-buildx`
- You need to enable containerd image store, otherwise the multi-platform docker build fails with
  "ERROR: Multi-platform build is not supported for the docker driver. Switch to a different driver, or turn on the containerd image store, and try again."

Fixing the latter is very easy: edit `/etc/docker/daemon.json` and use the following contents:
```json
{
  "features": {
    "containerd-snapshotter": true
  }
}
```
In order for the settings to take effect, restart the docker daemon:
```bash
$ systemctl restart docker
```

## Building

Now, cross-compiling a Vaadin app is as easy as:
```bash
$ git clone https://github.com/mvysny/vaadin-boot-example-gradle/
$ cd vaadin-boot-example-gradle
$ docker build -t test/vaadin-boot-example-gradle:latest --platform linux/amd64,linux/arm64 .
```
If you open project's `Dockerfile`, you can see the line
```
FROM --platform=$BUILDPLATFORM openjdk:21-bookworm AS BUILD
```
The `--platform` enables the cross-compilation: it tells Docker to run this build step
only once per build (and not once per target platform), natively on your native architecture;
the build step calls Gradle to build the app and produce a zip file with runnable
bash scripts and jar files. The second step then runs for every architecture,
unpacking the app zip file and creating a runnable docker image for every architecture.

We are done.

## Verifying that things do work

You can list the docker images, to see that they have indeed been built for multiple
platforms:
```
$ docker image ls --tree
IMAGE                                    ID             DISK USAGE   CONTENT SIZE
test/vaadin-boot-example-gradle:latest   359b22018b0c       1.59GB          752MB
|- linux/amd64                           93020af1d033        377MB          377MB
\- linux/arm64                           ef9345e888b3       1.21GB          375MB
```

TODO mavi publish them on Docker Hub and test on another machine.
