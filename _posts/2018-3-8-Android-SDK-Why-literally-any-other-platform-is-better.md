---
layout: post
title: Android SDK - Why literally any other platform is better
---

There are lots of [Android SDK sucks](https://www.google.com/search?q=android+sdk+sucks)
and [android development is a pain](https://www.google.com/search?q=android+development+is+a+pain)
rants indicating that development on Android is a horrible experience. Instead
of repeating the same thing over and over again, I'll try to sum up why I
will definitely prefer Vaadin-based PWA for my next project over Android SDK:

* Vaadin has no Fragments - no crazy lifecycle of create/start/resume/whatever.
  The app simply always runs. In Vaadin, components are used for everything;
  nesting components is perfectly fine as opposed to nesting fragments, which
  tend to produce weird random crashes (the famous `moveToState()` method).
* Since in Vaadin there is no crazy lifecycle, you are not required to code
  defensively. You do not have to be always prepared to be passivated by the
  Android system; you do not need to shatter your algorithm into multiple
  methods, always having to be prepared to save state into some Bundle when
  Android decides to passivate your app. Google guys are apparently obsessed
  by passivation and making your code fragmented, defensive and really hard
  to maintain.
* Vaadin components are lightweight - they don't use any native resources,
  they just produce html for the browser to draw. There is no complex
  lifecycle - the components simply attach and detach to the screen
  (represented by the `UI` class) as the user uses the app.
  Since the components do not use any native resources, they are simply
  garbage-collected when not needed anymore.
* All UI components are Serializable; in a rare case when the session passivation
  is needed, they are automatically saved along with the http session when
  there are no requests ongoing.
* Components are the unit of reuse - you compose components into more powerful
  components, into forms, or even into views. The component
  may be as small as a Button, or as big as a VerticalLayout with a complete form in it.
* You use Java code to create and nest components; even better you can use
  Kotlin code to build your UIs in a DSL fashion. You structure the code as
  you see fit; no need to have 123213 layout XMLs for 45 screen sizes in
  one large folder.
* You use a single file CSS to style your app - you don't have to analyze
  Android Theme shattered into 3214132 XML files.
* You don't need Emulator nor a device - the browser can render the page
  as if in a mobile phone; you can switch
  between various resolutions in an instant.
* No DEX compilation. The compilation is fast.
* No fragmentation: you develop for Chrome and Firefox. You can ignore the
  Internet Explorer crap.
* No need to fetch stuff in background thread. You actually have two UI threads:
  the Vaadin UI thread lives server-side, while the browser has its own UI thread;
  those two threads are completely separated.
  It is quite typical for a Vaadin app to block in the UI code until the data
  is fetched, since blocking server-side does not block the UI in the browser.
* PWAs do not have to be installed. Your users can simply browse your site;
  if they like the app, they can use their browser to easily create a
  shortcut to your app on their home screen.
* You will support both Android and iPhone with one code base.
* Avoid the trouble of publishing your app on the app stores: the app does
  not need to be reviewed by anybody; you will not need to pay $100 yearly to Apple.
* No data syncing necessary since the data will reside on the server.
* Android's way of requesting for runtime permissions is *so* horrible:
  it will call back not your Runnable, but your Activity/Fragment.
  That disallows you from spliting your code as you see fit; instead you
  have to keep all of your logic in an Activity/Fragment, shattered because
  of Fragment-based method callbacks.
  And since [runtime permissions will be required for all Android apps at Google Play](https://android-developers.googleblog.com/2017/12/improving-app-security-and-performance.html)
  at the end of 2018, instead of having to port your app to runtime permissions
  you can move to another platform.
* You can find more components at [https://vaadin.com/directory](https://vaadin.com/directory).
  Since Vaadin 10 uses Web Components, you can find even more components
  at [https://www.webcomponents.org/](https://www.webcomponents.org/) which
  can then be turned into Vaadin 10 components simply by implementing the server-side code.

Of course there is no silver bullet. This approach has the following disadvantages:

* No access to native APIs - only the browser-provided APIs are available.
  While you can access GPS, you can't access for example the SD card (with
  local user photos), can't make calls etc.
* No offline mode unless you develop your app fully or in partial in JavaScript,
  as a part of the service worker.
* Vaadin app lives server-side and uses a browser. Because of that, you
  won't be able to achieve the same performance as with the native app. It's
  probably not a good fit for, say, an immersive 3D game since the browser
  is obviously slower than the native code. However, this approach is perfectly
  fine for a chat client (say, Slack), or a banking app or the like.
* You will need a SSL certificate since PWAs only work over https
* You will need to pay for cloud hosting, SSL certificate and DNS domain yourself.
  The most easy way to set up all that is with Heroku; you can also pay for
  a virtualized Linux server, get the SSL certificate for free from Let's
  Encrypt and setup Tomcat to host your app.
* You are responsible for your app's security; when your app is hacked, all
  of your user data may be compromised.
* All of your users will use the same VM; 10000+ users can kill your server
  unless you load-balance. Luckily it's quite easy with most good cloud providers.

Switching to literally any other platform puts you in charge of code structure.
It's as if Google was poised to create a horrible developer hell - eventually
you'll develop a Stockholm Syndrome with Android SDK. Just leave that horrible
crap behind.
