---
layout: post
title: Debugging Your Widgetset Components With SuperDevMode For Dummies
---

When trying to fix some browser-side issue in your GWT components,
it is often useful to modify those component sources while your app is running, then
refresh your browser with F5
and immediately see the changes done in Vaadin Button. This blogpost describes
how to configure Intellij to do just that.

> Note: Here I'm assuming that you're using your own custom widgetset.
If you're using Vaadin default pre-compiled `com.vaadin.DefaultWidgetSet` widgetset located in
`vaadin-client-compiled.jar`,
please read [Debugging Built-in Vaadin 8 Components With SuperDevMode For Dummies](../Debugging-builtin-Vaadin-8-components-with-superdevmode-for-dummies/)

We will need two things:

* Your Vaadin WAR project, Maven or Gradle, doesn't matter.
  If you want to experiment on a fresh project, you can easily generate one
  at [https://vaadin.com/maven](https://vaadin.com/maven) - in the "Create an empty project"
  select "Vaadin 8 LTS" and run the Maven archetype command.
* Your widgetset sources. They can either be present in the WAR project above,
  or in a separate jar artifact, doesn't matter.

First, start by running your Vaadin-based WAR application from your IDE as you usually do.

Now that your app is up and running and accessible via the browser at, say, [http://localhost:8080](http://localhost:8080),
we are going to employ GWT *superdevmode*. Generally, the
idea here is that once a special Vaadin switch is activated
(`?superdevmode` added to your url), the browser will be configured
by the Vaadin Framework to serve widgetset javascript not
from your project's WAR, but instead from a GWT so-called *codeserver*
which we will launch in a minute. The codeserver does two things:

* when you press F5 in your Chrome, the codeserver will perform a
  hot javascript recompilation of Vaadin client-side widgets modified by you,
  and it will feed the compiled javascript to your Chrome.
* the codeserver will also provide so-called *sourcesets* for
  Chrome browser so that you will see an actual original Java
  sources in Chrome and you will be able to debug them from Chrome.

In order to run the codeserver, go into the project which contains
your widgetset sources and run this from the command-line:

```bash
$ mvn vaadin:run-codeserver
```

> Note: Maven Vaadin plugin doesn't have a documentation page, but it inherits goals from
the [GWT Maven Plugin](https://gwt-maven-plugin.github.io/gwt-maven-plugin). For example,
here is the [documentation on the vaadin:run-codeserver Maven goal](https://gwt-maven-plugin.github.io/gwt-maven-plugin/run-codeserver-mojo.html)
and here is the [documentation on all GWT Maven Plugin Goals](https://gwt-maven-plugin.github.io/gwt-maven-plugin/plugin-info.html).

The codeserver should eventually print something like this to the console:
```
[INFO] --- vaadin-maven-plugin:8.1-SNAPSHOT:run-codeserver (default-cli) @ vaadin-client-compiled ---
[INFO] Turning off precompile in incremental mode.
[INFO] Super Dev Mode starting up
[INFO]    workDir: /tmp/gwt-codeserver-1604961084994240944.tmp
[INFO]    [WARN] Deactivated PrecompressLinker
[ERROR] SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder".
[ERROR] SLF4J: Defaulting to no-operation (NOP) logger implementation
[ERROR] SLF4J: See http://www.slf4j.org/codes.html#StaticLoggerBinder for further details.
[INFO]    Loading Java files in com.vaadin.DefaultWidgetSet.
[INFO]    Module setup completed in 14374 ms
[INFO]
[INFO] The code server is ready at http://127.0.0.1:9876/
```

Now that the codeserver is running, let us use it. In your Chrome,
navigate to [http://localhost:8080?superdevmode](http://localhost:8080?superdevmode)
(or [http://localhost:8080?superdevmode#!someview](http://localhost:8080?superdevmode#!someview)
if you are using views + Navigator). The browser should say that it
is *recompiling the widgetset*, and after a while, your app
should appear as usual.

To prove that the app is indeed using the
codeserver, you can modify any of your component, e.g. by adding
the following Java code to its constructor:
```java
addStyleName("woot-my-style");
```
Save and hit recompile `CTRL+F9`. All widgetset components will be hot-redeployed to the codeserver.

Now, head to the browser, press `F5`, then inspect your component and observe
that it now has the `woot-my-style` class.

This concludes the hot-compilation part. Now for the debugging part. Press `F12`
in Chrome and head to the `Sources` tab. Now patiently unpack
`foo.bar.baz.YourWidgetSet` / `127.0.0.1:9876` / `sourcemaps/foo.bar.baz.YourWidgetSet` / `foo` / `baz` / `YourComponent.java`.
You see java sources in a browser. Cool. Now place a breakpoint at the `addStyleName("woot-my-style")`
and press F5. Chrome should now stop at that line. You can use
leftmost debugger buttons to fiddle with the execution flow.

# FAQ

### Q: The codeserver fails to start with
```
[INFO] [ERROR] cannot start web server
[INFO] java.net.BindException: Address already in use
```

A: CodeServer loves to stay running even when killed by Intellij.
Just do `netstat -tnlp|grep 9876` and then kill the offending `java CodeServer` process.

### Q: The codeserver does not pick up the changes I made
A: Make sure you are launching the codeserver in Debug mode.
Then, make sure you saved the java file and hit `CTRL+F9`.

### Q: The codeserver fails to compile widgetset because of some ridiculous compilation error
Just let me know if you find a workaround, I'll update this tutorial.

### Q: Skipping over `assert`s
Use the `-da` JVM switch: run `MAVEN_OPTS="-da" mvn vaadin:codeserver`.

### Q: Breakpoints do not work in Safari

I don't know why yet. As a workaround, you can enforce breakpoints by adding
`GWT.debugger();` call to your java code. According to GWT docs:

> Emits a JavaScript "debugger" statement on the line that called this method.
     If the user has the browser's debugger open, the debugger will stop when the
     GWT application executes that line. There is no effect in Dev Mode or in
     server-side code.
