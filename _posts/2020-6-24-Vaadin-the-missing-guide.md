---
layout: post
title: Vaadin - The missing guide
---

The [Vaadin documentation](https://vaadin.com/docs/v14/flow/Overview.html)
is a good source of initial info for Vaadin, but unfortunately in certain cases
it simply doesn't go deep enough. This is especially true with respect
of the toolchain Vaadin uses, and the files it relies on. Therefore, this blog post.

## Basic Vaadin concepts

All Vaadin components are generally web components, following the
[Web Component](https://www.webcomponents.org/introduction) specification.

Web Component API is supported by all ever-green browsers (Firefox, Chrome, Safari, MS Edge).

> **Note:** Ever-green means that the browser endlessly updates itself and you generally
> use the newest version.

Web Component API can be emulated, by the means of the [Polyfill](https://polyfill.io/v3/) library - that's how
IE 11 is able to "support" Web Components even though IE 11 offers no Web Component support natively.
However, Polyfills emulation is very slow and leads to 5-10 times worse performance
(for example documented in [Vaadin dropped IE11 support in Vaadin 15+](https://vaadin.com/blog/vaadin-14-is-the-last-major-version-to-support-ie11);
also see
[Vaadin Release Notes, section "Known Issues and Limitations" / "Performance"](https://github.com/vaadin/platform/releases/tag/14.2.1) - very well hidden Vaadin!!)

Vaadin controls the web components from server side, by setting DOM HTML attributes,
Polymer properties (kinda deprecated since Polymer will go away)
and [Lit Properties](https://lit-element.polymer-project.org/guide/properties) (Vaadin 15+);
Vaadin is also able to listen on DOM events and pass them through to the server-side. The
Vaadin part responsible for this is called [Vaadin Flow](https://github.com/vaadin/flow/).

Read [Vaadin Overview](https://vaadin.com/docs/v14/flow/introduction/introduction-overview.html) for more details.

> **Note:** You can still use non-webcomponent libraries: you simply create a `<div>`
> client-side, you hook the javascript library to that div and then you can control the
> `<div>` from the server-side.

## Basic JavaScript concepts

* [node.js](https://nodejs.org/en/) - a virtual machine able to run JavaScript code, akin to JVM
* [npm](https://www.npmjs.com/) - a package manager akin to Maven
* [pnpm](https://pnpm.js.org/) - a package manager akin to Maven; same as `npm` but much faster since it's able
  to cache downloaded packages locally.
* [Bower](https://bower.io/) - a package manager akin to Maven, now deprecated and superseded by npm

For best results, use `pnpm`. In the text below, `npm` will be used as a reference to both
npm and pnpm.

## The Compatibility/bower mode versus the npm mode

Vaadin is able to run in two modes: so-called _compatibility_ or _bower_ mode, and the _npm_ mode. Vaadin 13 and lower
only supported bower mode; Vaadin 14 supports both modes; Vaadin 15+ will only support npm mode.

In compatibility mode, Vaadin Servlet will use the old way of using
JavaScript modules packaged as webjars (jars deployed in Maven Central, containing client-side JavaScript code).
The packaging manager is [Bower](https://bower.io/). Generally the [webjars](https://www.webjars.org/)
site is used, to create webjar out of a bower package. What the webjars page does
is that it parses bower descriptor, creates a Maven `pom.xml` out of it (so that
transitive dependencies are "working") and that's it: from your server-side perspective
you can forget about Bower entirely and just use Maven to manage the dependencies.

Well, not entirely: Bower versioning (especially the 1.x+ scheme) works differently
than Maven one, and thus Vaadin had to introduce vaadin-bom to work around these issues.

Bower mode is deprecated and will go away in future Vaadin versions, do not use it for
new projects - always use the npm mode.

### new npm mode

In npm mode, Vaadin does not use webjars at all; instead it relies on JavaScript programs
to do all the work:

1. It uses the `npm`/`pnpm` package manager to gather all packages Vaadin+your app needs,
   into the `node_modules` folder.
2. [webpack](https://webpack.js.org/) is then used to compress all modules and custom js files into one
   huge javascript file, both in development mode and in production mode.
3. (In Vaadin production mode): the javascript file is then stored into the WAR file
   into the `WEB-INF/classes/META-INF/VAADIN/build/` folder and served by VaadinServlet
   from there.

> **Note:** In npm mode, Vaadin does not use webjars at all. However in Vaadin 14 webjars
> are transitive dependencies of the `vaadin` and `vaadin-core` Maven artifacts.
> While there is no harm
> in having webjars on classpath (Vaadin will simply ignore them), it's best to
> exclude them in order to decrease the result WAR file size. See
> example [build.gradle.kts](https://github.com/mvysny/karibu10-helloworld-application/blob/master/build.gradle.kts)
> on how to do that.

npm configures itself via the `package.json` and `package-lock.json` files,
and produces the `node_modules` folder.
The `package.json` and `package-lock.json` files are generated by Vaadin, but you
are free to modify those files to include additional packages if need be. However
there's a better way to do it: by using the `@NpmPackage` Java annotation you declare
that you need this and this npm package for your server-side component. Vaadin plugin
then performs classpath scanning, gathers all `@NpmPackage` annotations and produces
appropriate `package.json`/`package-lock.json` files.

Webpack basically takes all npm modules and the content of your `frontend/` folder,
and produces one huge javascript file. Webpack is configured via two files:
`webpack.config.js` and `webpack.generated.js`. You can add your custom config into the
`webpack.config.js` file, however I never needed to do that so far. Both files
are generated by Vaadin.

## Development vs production mode

In development mode, Vaadin doesn't bundle the javascript files into the WAR file since
that would prevent them from being hot-redeployed when modified. Instead,
Vaadin Servlet will run webpack as a child process; webpack will then monitor
`frontend/` for changes and is able to communicate with Vaadin Servlet internally
so that Vaadin Servlet can correctly serve JavaScript code. That's why any changes
made to the `frontend/` folder are immediately visible when you refresh the page.

In production mode however, Vaadin Servlet doesn't launch webpack (since that would
require node.js and npm on your production machine); instead it relies on Vaadin Plugin
to run webpack, in order to produce the one huge JavaScript file. Vaadin Plugin
then packages the produced JavaScript file onto classpath, into the `META-INF/VAADIN/build/` package;
Vaadin Servlet is then able to serve those files to the browser, in order to
initialize the client-side properly.

The `META-INF/VAADIN/build/` contents should look like this (the hash is going to differ on every build):

```
├── vaadin-2-18d67c4ccff7e93b081a.cache.js
├── vaadin-2-18d67c4ccff7e93b081a.cache.js.gz
├── vaadin-3-b0147df339bf18eb7618.cache.js
├── vaadin-3-b0147df339bf18eb7618.cache.js.gz
├── vaadin-4-ee1d2e45569f7eca4292.cache.js
├── vaadin-4-ee1d2e45569f7eca4292.cache.js.gz
├── vaadin-5-5e9292474e82143d0a27.cache.js
├── vaadin-5-5e9292474e82143d0a27.cache.js.gz
├── vaadin-bundle-19a00eae62ad7cddd291.cache.js
├── vaadin-bundle-19a00eae62ad7cddd291.cache.js.gz
├── vaadin-bundle.es5-b1c1a3cc054c62ad7949.cache.js
├── vaadin-bundle.es5-b1c1a3cc054c62ad7949.cache.js.gz
└── webcomponentsjs
    ├── bundles
    │   ├── webcomponents-ce.js
    │   ├── webcomponents-ce.js.map
    │   ├── webcomponents-sd-ce.js
    │   ├── webcomponents-sd-ce.js.map
    │   ├── webcomponents-sd-ce-pf.js
    │   ├── webcomponents-sd-ce-pf.js.map
    │   ├── webcomponents-sd.js
    │   └── webcomponents-sd.js.map
    ├── custom-elements-es5-adapter.js
    ├── LICENSE.md
    ├── package.json
    ├── README.md
    ├── src
    │   └── entrypoints
    │       ├── custom-elements-es5-adapter-index.js
    │       ├── webcomponents-bundle-index.js
    │       ├── webcomponents-ce-index.js
    │       ├── webcomponents-sd-ce-index.js
    │       ├── webcomponents-sd-ce-pf-index.js
    │       └── webcomponents-sd-index.js
    ├── webcomponents-bundle.js
    ├── webcomponents-bundle.js.map
    └── webcomponents-loader.js
```

## Vaadin Configuration

The most important file is the `flow-build-info.json` file: Vaadin Servlet
reads that file and configures itself from it at runtime.
The file resides on the classpath, in the
`META-INF/VAADIN/config/` package. The file is produced by Vaadin Plugin.
It looks like this (development mode example):

```json
{
  "compatibilityMode": false,
  "productionMode": false,
  "npmFolder": "/home/mavi/work/my/vok/karibu10-helloworld-application",
  "generatedFolder": "/home/mavi/work/my/vok/karibu10-helloworld-application/target/frontend",
  "frontendFolder": "/home/mavi/work/my/vok/karibu10-helloworld-application/frontend",
  "pnpm.enable": true,
  "require.home.node": false
}
```

The most important settings are `compatibilityMode` and `productionMode`.

Production mode example:
```json
{
  "compatibilityMode": false,
  "productionMode": true,
  "enableDevServer": false,
  "chunks": {
    "fallback": {
      "jsModules": [
        "@vaadin/vaadin-icons/vaadin-icons.js",
        "@vaadin/vaadin-grid/src/vaadin-grid-tree-toggle.js",
// etc etc
        "frontend://ironListConnector.js"
      ],
      "cssImports": [
        
      ]
    }
  }
}
```

It's very important to have this file on classpath. If it's not, Vaadin Servlet
will then try to auto-configure itself and sometimes wrongly so. For example when launching
WAR in Tomcat from Intellij, the `frontendFolder` setting will be "auto-detected"
to Tomcat's `bin/` folder, which will cause webpack to fail later on, because of missing files.

If the file is present multiple times on the classpath (sometimes Vaadin addons
incorrectly include the `flow-build-info.json` file in the jar file - that's a bug in the addon packaging),
then Vaadin employs some black box code to try to choose which one is the right one (which one is coming
from the main project). That's unfortunate since sometimes the black magic fails and
backfires unexpectedly.

Just keep in mind to have this file on the classpath EXACTLY ONCE, and always coming
from your project. The file is generated by Vaadin plugin, in the `prepare-frontend` task,
therefore it's very important to always run that task before launching your app in development mode.

## What to read next

Read the [Vaadin Plugin: under the hood](../Vaadin-Plugin-under-the-hood/) for more
info on how these files are prepared.
