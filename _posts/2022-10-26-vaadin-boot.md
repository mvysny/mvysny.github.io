---
layout: post
title: Vaadin Boot
---

It came as quite a surprise to me that many people are using Spring Boot just to
avoid having to launch their apps as WAR files in Tomcat. But then again, it makes sense:
simply running a `main()` function is far simpler than having to fiddle with WAR and Tomcat
deployment in your IDE, hoping that debugging would just work.

However, the WAR way of deployment has been long obsoleted by Docker. Today, no-one runs multiple
WARs in Tomcat anymore, everyone simply runs apps in a Docker image. It's simpler and
more secure to expose a port in Docker image than to expose Tomcat itself and hope that
the manager has been removed correctly.

So WARs are obsolete; what would be their replacement? Enter [Vaadin Boot](https://github.com/mvysny/vaadin-boot).
Vaadin Boot does the same thing as Spring Boot - it runs your Vaadin app via a `main()` function and
packages your apps as a zip file. Such a project has tremendous advantages over WARs:

* It's much easier to run your app in your IDE. You don't need to configure Tomcat then fiddle with WAR deployment details;
  you simply run the `main()` function and the app launches.
* You no longer need Intellij Ultimate to develop your app; all you need is the Intellij Community Edition (which is free).
* Debugging and code hot-redeployment works out-of-the-box.
* The project starts up much faster and consumes much less memory.

Obviously Vaadin requires a Servlet container; Vaadin Boot simply uses embedded [Jetty](https://www.eclipse.org/jetty/)
which has been battle-tested in production as well. But this is just an implementation detail -
you focus on your routes and views while Vaadin Boot focuses on having your app running smoothly.

You can start your new project from scratch easily with Vaadin Boot: check out the example videos:

* [Part 1](https://www.youtube.com/watch?v=vl8Dnh6FIYA)
* [Part 2](https://www.youtube.com/watch?v=0g_kfqECDvk)
