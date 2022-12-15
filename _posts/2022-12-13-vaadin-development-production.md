---
layout: post
title: Vaadin Production/Development mode and flow-build-info.json
---

Vaadin offers two concepts, which are orthogonal (can be combined independently):

1. **Development** and **production** mode
2. Building the JavaScript bundle **on-the-fly** (also known as *DevServer*) VS **prebuilt** upfront.

Vaadin can therefore run in the following modes (essentially all combinations of the above):

1. **Dev mode** with JavaScript bundle built **on-the-fly**. This is the default mode when you run the Vaadin app from your IDE.
2. **Dev mode**, JavaScript bundle **pre-built** upfront. In some environments (say remote development) it's not possible for Vaadin Servlet
   to access local disk files - in such case you should use this mode.
3. **Production mode**, JavaScript bundle built **on-the-fly** -> Doesn't make much sense so let's just skip this.
4. **Production mode**, JavaScript bundle **prebuilt** upfront - this is what we should run in production.

By default, Vaadin runs in development mode and builds webpack on-the-fly.

## Development VS Production mode

The development mode is active by default, unless you switch to production mode via `mvn -Pproduction`
or `./gradlew -Pvaadin.productionMode`.

* Building for production produces an "obfuscated"/minified javascript bundle which is quicker to load and to run in the browser,
  but the Javascript code can not be read by the developer anymore. This is good for production environment,
  but bad for development environment (since you can't debug the JS code easily anymore).
* In development mode, the JavaScript sources are kept as-is: they are not optimized nor obfuscated nor minified,
  and therefore they are much easier to debug in browser's JavaScript console.

The developers should definitely use the development mode on their development machines.

## Building JavaScript bundle on-the-fly VS prebuilt

By default, Vaadin builds the JavaScript Bundle on-the-fly. The bundle is basically one huge javascript
file containing contents of all JS files, but also CSS files injected into webcomponents.
The bundle always needs to be built at some point,
otherwise it would be hard to transfer all those javascript files to the browser.

Webpack (Vaadin 14, 22, 23.0.0-23.1.x) or Vite (Vaadin 23.2+) is used to build the bundle.

### On-The-Fly mode

In this mode, the bundle is not built upfront. Instead, VaadinServlet starts the webpack (or vite) process
which rebuilds JavaScript files on-the-fly as they're changed on the disk. This is also called the
*Development Server mode*. It then communicates with Vaadin Servlet
and transfers the completed bundle file to the Vaadin Servlet, which then serves it to the browser on-the-fly.

This way, the bundle is rebuilt immediately when any files are changed on disk, which is great for development.
The downside is that the startup is a bit slower since an initial bundle build needs to run first.
This is the "Building front-end development bundle" black pill-like badge, shown in the browser when you open
the app for the first time.

### Prebuilt mode

In this mode, Vaadin Servlet expects pre-built bundle files in the `META-INF/VAADIN/build/` folder.
Vaadin Servlet therefore doesn't start the DevServer/WebPack/Vite in this mode.

You can enable this mode by running `mvn vaadin:prepare-frontend vaadin:build-frontend`
or `./gradlew vaadinBuildFrontend` to build the JavaScript bundle.
That will modify `flow-build-info.json` and set `enableDevServer` to false, which configures
Vaadin for the prebuilt mode.

## How to check which mode is active

Vaadin Servlet configures itself from the `flow-build-info.json` file, which is located in the `target/**/META-INF/VAADIN/config/` folder.
Please check the `flow-build-info.json` contents on the current configuration:

1. When production mode is active, `"productionMode": true`. Otherwise, the development mode is active.
2. When the JavaScript bundle is built on-the-fly, `"enableDevServer": true`. Otherwise, the bundle is expected
   to have been built up-front and packaged into the `META-INF/VAADIN/build/` folder.

## More Documentation

I left a lot of information out of this blog post, to keep things focused on the modes themselves.
Please make sure to read the following articles, to get more insight:

1. [Official Vaadin Troubleshooting](https://vaadin.com/docs/latest/production/troubleshooting)
2. [My Vaadin Troubleshooting](../Vaadin-troubleshooting/)
