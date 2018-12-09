---
layout: post
title: Using JavaFX embedded browser for TestBench
---

If you ever used Selenium (or [TestBench](https://vaadin.com/add-ons/testbench), which is based on Selenium), you know the pain of configuring the testing browser driver:

* One simply cannot use the preinstalled Firefox since the Driver <-> Firefox protocol breaks basically on every Firefox release
* Selenium developers eventually gave up supporting newer Firefoxes directly and started to use Gecko Driver which is pain to build
* Setting up PhantomJS on every dev+test machine is a pain
* Using other browsers require appropriate drivers preinstalled

Basically, every machine has different browser preinstalled, on different path, and when you throw in different OSes the configuration starts to get nasty.

Fortunately, there is a browser, installed on every machine with Java 8 - the JavaFX Browser component. It's not a full-blown browser per se, but it can render html pages, is webkit-based and works regardless of OS. Luckily, there is a specialized Selenium driver based on this browser: the [JBrowserDriver](https://github.com/MachinePublishers/jBrowserDriver). We can take advantage of that.

You can find the demo project here: https://github.com/mvysny/testbench-simplest-demo . It's a simplest project possible, with just one UI class and one testing class. To get it up and running, just follow these steps:

1. Obtain TestBench license at the [TestBench AddOn Page](https://vaadin.com/add-ons/testbench) - just search for "Trial license"
2. `git clone https://github.com/mvysny/testbench-simplest-demo`
3. `mvn clean verify`
4. Find the proof that the test ran, in `target/screenshot.png`

## Headless mode

The browser even works in headless mode. You can quick-proof this by running the test in the Docker. First, run:

```bash
docker run -it --rm -v "$PWD":/usr/src/mymaven -w /usr/src/mymaven -v "$HOME/vaadin.testbench.developer.license":/root/vaadin.testbench.developer.license maven:3.3.9-jdk-8 /bin/bash
```
in the `testbench-simplest-demo` directory. Then, in the docker:

1. We'll need to install the JavaFX to the docker container. Run `apt update` and `apt install openjfx`, press `y` when prompted
2. Still in Docker, run `mvn clean verify`
3. Docker will run maven using your host OS's filesystem and will produce `target/screenshot.png`. Just open the `target/screenshot.png` file with your favourite image viewer.
