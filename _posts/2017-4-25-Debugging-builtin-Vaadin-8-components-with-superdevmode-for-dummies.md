---
layout: post
title: Debugging Built-in Vaadin 8 Components With SuperDevMode For Dummies
---

When trying to fix some browser-side issue in Vaadin built-in components, it is often useful to modify those component sources while your app is running. This way, you can modify e.g. `VButton.java`, refresh your browser with F5 and immediately see the changes done in Vaadin Button. This blogpost describes how to configure Intellij to do just that.

We will need two things:

* A standard Java Vaadin WAR project which employs the component we are going to modify, e.g. `com.vaadin.ui.Button`. You can use your own project; if you don't have one, for the purpose of this article you can easily generate one at https://vaadin.com/maven
* The Vaadin Framework sources checked out from git. I'll guide you later on.

First, start by running your Vaadin-based WAR application from your IDE as you usually do. I assume here that you use only the default widgetset, with no added widgets; I need to write another blogpost on how to debug your custom widgetset.

Now that your app is up and running and accessible via the browser at, say, http://localhost:8080, we are going to employ GWT *superdevmode*. Generally, the idea here is that once a special Vaadin switch is activated (`?superdevmode` added to your url), the browser will be configured by the Vaadin Framework to serve widgetset javascript not from your project's WAR, but instead from a GWT so-called *codeserver* which we will launch in a minute. The codeserver does two things:

* when you press F5 in your Chrome, the codeserver will perform a hot javascript recompilation of Vaadin client-side widgets modified by you, and it will feed the compiled javascript to your Chrome.
* the codeserver will also provide so-called *sourcesets* for Chrome browser so that you will see an actual original Java sources in Chrome and you will be able to debug them from Chrome.

Let us start by grabbing Vaadin sources:
```bash
$ git clone git@github.com:vaadin/framework.git
```
Make sure that you checkout appropriate branch (e.g. `8.0` if you use Vaadin 8.0.x, `7.7` if you use Vaadin 7.7.x etc), then compile:
```bash
$ mvn clean install -DskipTests
```
Then just open the main `framework/pom.xml` in Intellij. There will be compilation errors regarding `import elemental.json.JsonObject` missing, you can safely ignore those.

Launching the codeserver properly is tricky and produces lots of errors when not done right. To put it bluntly, codeserver is a bitch, prepare for lots of cursing and wasted time, you've been warned. The easiest option is to use maven vaadin plugin. Just open the *Maven* tool window in the Intellij in which you have the framework sources opened, go into *vaadin-client-compiled / Plugins / vaadin / vaadin:run-codeserver*, right-click and select *Create "vaadin-client-compiled..." launch configuration*. The most important part is the *Resolve Workspace artifacts*:

* When it is unchecked, Maven will use `vaadin-client.jar` from `~/.m2/repository`, meaning that you will need to run `mvn clean install` inside the `client` project every time you modify Vaadin GWT sources. This is definitely suboptimal and we can do better.
* When it is checked, Maven will prefer `client` sources over jars from `~/.m2/repository`. However, activating this mode and *Debugging* this launch configuration will sometimes fail to compile the `DefaultWidgetSet` with some ridiculous error message. If this happens, just read below for a workaround.

Workaround for `vaadin:run-codeserver` not starting: So, what now? Simple - just attach the sources as resources :-) Uncheck the *Resolve Workspace artifacts*, save the launch configuration. Then, open the `client-compiled/pom.xml` file and add the following snippet right below the `<build>` element:

```xml
		<resources>
			<resource>
				<directory>../client/src/main/java</directory>
			</resource>
		</resources>
```

Now it will be possible to launch the `vaadin:run-codeserver` task, and with it, the codeserver. The codeserver should eventually print something like this to the console:
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

Now that the codeserver is running, let us use it. In your Chrome, modify the URL to http://localhost:8080?superdevmode (or http://localhost:8080?superdevmode#!someview if you are using Navigator). The browser should say that it is *recompiling the widgetset*, and after a while, your app should appear as usual. To prove that the app is indeed using the codeserver, we will modify the `VButton.java` a bit.

Open the `VButton.java` in Intellij where the codeserver is running, and head to the constructor. At line 118, at the end of the constructor, just add the following line:
```java
addStyleName("woot-my-style");
```
Save and hit recompile `CTRL+F9`. There may be compilation errors regarding `import elemental.json.JsonObject` missing, you can safely ignore those - the `VButton.java` will be hot-redeployed to the codeserver anyway.

Now, head to the browser, press `F5`, then `Ctrl+Shift+C` and click any Vaadin button. The appropriate div should now have the `woot-my-style` class. If not, kill the codeserver and make sure you are using the `<resources>` workaround above, with *Resolve Workspace artifacts* unchecked.

This concludes the hot-compilation part. Now for the debugging part. Press `F12` in Chrome and head to the `Sources` tab. Now patiently unpack `com.vaadin.DefaultWidgetSet` / `127.0.0.1:9876` / `sourcemaps/com.vaadin.DefaultWidgetSet` / `com` / `vaadin` (at this point I start to wonder whether coping with all this is really worthwile, now that we have Kotlin2JS) / `client` / `ui` / `VButton.java`. You see java sources in a browser. Cool. Now place a breakpoint at line 118 where the `addStyleName()` resides, and press F5. Chrome should now stop at that line. You can use leftmost debugger buttons to fiddle with the execution flow.

# FAQ

### Q: The codeserver fails to start with
```
[INFO] [ERROR] cannot start web server
[INFO] java.net.BindException: Address already in use
```

A: CodeServer loves to stay running even when killed by Intellij. Just do `netstat -tnlp|grep 9876` and then kill the offending `java CodeServer` process.

### Q: The codeserver does not pick up the changes I made
A: Make sure you are launching the codeserver in Debug mode. Then, make sure you saved the java file and hit `CTRL+F9`. Also make sure you are using the `<resources>` workaround above, with *Resolve Workspace artifacts* unchecked.

### Q: The codeserver fails to compile widgetset because of some ridiculous compilation error
Make sure you are using the `<resources>` workaround above, with *Resolve Workspace artifacts* unchecked.
