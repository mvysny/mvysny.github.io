---
layout: post
title: Launch your Vaadin-on-Kotlin app quickly in cloud/docker
---

So you have built your first awesome VoK app - congratulations! You will probably want to launch it outside of your IDE, or even deploy it somewhere on the interwebz. Just pick up any virtual server provider with your favourite Linux distribution.

There are following options to launch your app:

## From Gradle, using the Gretty plugin

With proper configuration and `build.gradle` file, you can simply use the [Gretty Gradle](http://akhikhl.github.io/gretty-doc/Getting-started.html) plugin to launch wars. Gretty comes pre-configured in the sample quickstarter [VoK HelloWorld App](https://github.com/mvysny/vok-helloword-app), so you can grab the Gradle configuration from there:

```bash
git clone https://github.com/mvysny/vok-helloword-app
cd vok-helloworld-app
./gradlew web:appRun
```

You can configure Gretty to launch your app either in Jetty or Tomcat, please read more here: http://akhikhl.github.io/gretty-doc/Gretty-configuration.html . To launch it in cloud, just ssh to your virtual server, install openjdk 8, `git clone` your app to the server and run `./gradlew appRun`.

## From Docker, using the Tomcat image

Really easy - just head to the folder where your `my-fat-app-1.0-SNAPSHOT.war` file is, and run the following line:
```bash
docker run --rm -ti -v "`pwd`:/usr/local/tomcat/webapps" -p 8080:8080 tomcat:9.0.5-jre8
```
This command will start the Tomcat docker image and will mount your local folder with your war app into Tomcat's `webapps/` folder. Your app will then run at http://localhost:8080/my-fat-app-1.0-SNAPSHOT . To run at http://localhost:8080 just rename your war to `ROOT.war`. To launch in your virtual server, just copy the WAR into your server, install docker and run the abovementioned command.

You can also create a Tomcat-based Docker image with your app easily. Just drop the following `Dockerfile` next to your war file:
```docker
FROM tomcat:9.0.5-jre8
RUN rm -rf /usr/local/tomcat/webapps/*
COPY *.war /usr/local/tomcat/webapps/ROOT.war
VOLUME /usr/local/tomcat/logs
```
Then, just run this in the directory with the `Dockerfile`:
```bash
docker build -t my-app .
docker run --rm -ti -p 8080:8080 my-app
```

Or even better, just use `docker-compose.yml`:
```docker
version: '2'
services:
  web:
    build: .
    ports:
     - "8080:8080"
```

Then all you need to run is just
```bash
docker-compose up --build --force-recreate
```
(`--build` will always rebuild the image so that you can play around with the `Dockerfile`; `--force-recreate` will delete old containers and create new ones so that Tomcat won't try to restore sessions from previous run).

**Note:** the Tomcat docker image now comes with unlimited JCE policy: `println("Cipher strength: ${Cipher.getMaxAllowedKeyLength("AES")}")` prints `Cipher strength: 2147483647`

## Fat jar

The easiest option is to embed Jetty into your app, then have Jetty launch your app.
You can build an uberjar (jar with all dependencies) or a zip file with a start script
and a folder with all jars. See the [vaadin14-embedded-jetty-gradle](https://github.com/mvysny/vaadin14-embedded-jetty-gradle)
project for more details.

Beware though: fat jars may not work for apps that package multiple files into the
same location: for example there will be only one MANIFEST.MF. You can read about
the pitfalls here: [The Fault in Our JARs: Why We Stopped Building Fat JARs](https://product.hubspot.com/blog/the-fault-in-our-jars-why-we-stopped-building-fat-jars).

It is also possible to package Tomcat into the WAR itself, add a launcher class and then simply run it
via `java -jar your-app.war`, thus making an executable WAR. You can read more about this option here:
[StackOverflow: Embed Tomcat with App in One Fat Jar](https://stackoverflow.com/questions/13333867/embed-tomcat-with-app-in-one-fat-jar).
Unfortunately I have no experience in this regard.

## Docker-Compose

You can use Docker-Compose to launch both the app and the database in one go.
See the [vaadin-kotlin-pwa example app documentation](https://github.com/mvysny/vaadin-kotlin-pwa)
for more details.
