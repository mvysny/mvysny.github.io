---
layout: post
title: Try out TeamCity quickly with Docker
---

[Teamcity](https://www.jetbrains.com/teamcity) is quite a nice continuous integration server from Jetbrains. The set up is not that easy though since you typically need to install the TeamCity server itself, and at least one agent which will perform the building itself.

Luckily, with Docker, you can set up TeamCity very easily on any PC, without the fuss of installing the server and the agent. The following `docker-compose.yml` configuration file will direct Docker to download appropriate images both for TC server and for TC agent and run them. Create a folder named `teamcity` and drop the `docker-compose.yml` file in there:

```
version: "2.1"
services:
  server:
    image: jetbrains/teamcity-server:latest
    ports:
      - "8111:8111"
    volumes:
      - ./datadir:/data/teamcity_server/datadir
      - ./logs:/opt/teamcity/logs
  agent:
    image: jetbrains/teamcity-agent:latest
    volumes:
      - ./agent_conf:/data/teamcity_agent/conf
    environment:
      - SERVER_URL=http://server:8111
```

Then, create the following folders inside of the `teamcity` folder which will store both the server and the agent persistent folders:
```
datadir
logs
agent_conf
```

Now just start the containers with:
```
docker-compose up
```

Now you can direct your browser to http://localhost:8111 and configure TC to use the embedded database; then just head to agents and authorize the `teamcity-agent` so that TC server will trust it and will run the builds there.

## Building Android APKs with TeamCity

Building an Android app requires the Android SDK to be preinstalled in the Agent itself. That can be done quite easily - we will extend the `teamcity-agent` docker image and add the SDK on top of that. In the `teamcity` folder above, create a folder named `agent-android-docker` and put the following `Dockerfile` there:
```
FROM jetbrains/teamcity-agent

ENV ANDROID_HOME "/sdk"
ENV SDK_HOME "/opt"

ENV PATH "$PATH:${ANDROID_HOME}/tools"
ENV DEBIAN_FRONTEND noninteractive

COPY sdk /sdk

RUN apt-get -qq update && \
    apt-get install -qqy --no-install-recommends \
      curl \
      html2text \
      libc6-i386 \
      lib32stdc++6 \
      lib32gcc1 \
      lib32ncurses5 \
      lib32z1 \
      unzip \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p $ANDROID_HOME/licenses/ \
  && echo "8933bad161af4178b1185d1a37fbf41ea5269c55" > $ANDROID_HOME/licenses/android-sdk-license \
  && echo "84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_HOME/licenses/android-sdk-preview-license

ADD packages.txt /sdk
RUN mkdir -p /root/.android && \
  touch /root/.android/repositories.cfg && \
  ${ANDROID_HOME}/tools/bin/sdkmanager --update && \
  (while [ 1 ]; do sleep 5; echo y; done) | ${ANDROID_HOME}/tools/bin/sdkmanager --package_file=/sdk/packages.txt

RUN chmod -R a+rwx ${ANDROID_HOME}
```

You will also need the `packages.txt` along the `Dockerfile` itself, with the following contents:
```
add-ons;addon-google_apis-google-24
build-tools;25.0.3
extras;android;m2repository
extras;google;google_play_services
extras;google;m2repository
extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2
platform-tools
platforms;android-25
```

Then, download the [Android SDK Tools for Linux](https://developer.android.com/studio/index.html) (Not the whole Studio, just the SDK Tools; the download links are at the bottom of the page). As of the writing of this article, the direct link to the SDK Tools is this: https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip . Unpack the zip file to `agent-android-docker/sdk`, so that the contents of the `sdk` folder contain the folder `tools`.

To use this new Agent Image, we will simply direct the Docker Compose to build it - just modify the `docker-compose.yml` file and change it as follows:
```
version: '2'
services:
  teamcity-server:
    image: jetbrains/teamcity-server:2019.2
    environment:
     - TEAMCITY_SERVER_MEM_OPTS=-Xmx2g -XX:MaxPermSize=270m -XX:ReservedCodeCacheSize=350m
    ports:
     - "127.0.0.1:8111:8111"
    volumes:
     - ./server/datadir:/data/teamcity_server/datadir
     - ./server/logs:/opt/teamcity/logs
  teamcity-agent:
    build: agent-android-docker
    environment:
     - SERVER_URL=http://teamcity-server:8111
    volumes:
     - ./agent/conf:/data/teamcity_agent/conf

```

Done - just run `docker-compose up`.
