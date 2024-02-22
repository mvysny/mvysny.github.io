---
layout: post
title: Vaadin - Troubleshooting the Browser
---

Sometimes Vaadin 14 fails mysteriously, which is very unfortunate: it now uses
LOTS of JavaScript code, frameworks and tools. Those things are unfamiliar to server-side
guys, and it's really hard to tell what to do, should one of JavaScript toolchain fail.

This article is a follow-up of the [Vaadin Troubleshooting](../Vaadin-troubleshooting/) article
which focused on issues caused by the server-side code. This article will focus
on the client-side issues.

## What to verify in your browser

Two tips before we begin: you should at some point learn how to use your browser's dev tools:

* [Firefox Dev Tools Guide](https://developer.mozilla.org/en-US/docs/Tools)
* [Chrome Dev Tools Guide](https://developers.google.com/web/tools/chrome-devtools)

Second tip: To remove the possibility of random issues caused by corrupted `node_modules`
or inproper javascript package versions in `package.json` and `package-lock.json`/`pnpm-lock.yaml`,
it's always good to start the bug hunting with the **Vaadin Dance**. See
[Vaadin Troubleshooting](../Vaadin-troubleshooting/) for more details.

Now, press F12 in your browser to fire up dev tools, then switch to the "Console"
tab and let's go!

## Investigating Exceptions

Search the JavaScript Console for any
red-line logs, indicating JavaScript execution errors or JavaScript exceptions.
Such exceptions prevent any further JavaScript execution which could cause any
of the following:

* Prevent initialization of the theming. Such issues may prevent
  the theme from being loaded in your app, causing your app to look like a
  black-text-on-white-background.
* Prevent initialization of other components, causing lots of
  `Cannot read property x of undefined` further on.

Fixing the root cause can then cause a domino effect and can fix all follow-up errors
like theming and `undefined`-related issues. Therefore, it's important to always investigate the
first exception in the JavaScript console log. The red line can usually be unwrapped
which reveals the stacktrace. Having the stacktrace is very important to quickly locate the
origin of the issue.

If the stacktrace points into a non-obfuscated JavaScript code (say a Vaadin add-on), then you can
proceed into the code and try to diagnose the root of the problem.

## Obfuscated Stacktraces

**NOTE TO THE FUTURE ME:** Before you start wasting time deobfuscating JavaScript: check whether there's a line
`"The error has occurred in the JS code:"` above the exception. If yes, Flow is
simply trying to execute whatever the server sent. Calm down & read below & start searching on the server-side.

Obfuscated stacktraces looks like following (see+vote [Vaadin Bug 8872](https://github.com/vaadin/flow/issues/8872)):

```js
(ReferenceError) : Polymer is not defined client-5F17FE7D56927576AB18BC8D06949321.cache.js:212:20
    XC client-5F17FE7D56927576AB18BC8D06949321.cache.js:212
    Xn client-5F17FE7D56927576AB18BC8D06949321.cache.js:1003
    Wn client-5F17FE7D56927576AB18BC8D06949321.cache.js:774
    Yn client-5F17FE7D56927576AB18BC8D06949321.cache.js:594
    cu client-5F17FE7D56927576AB18BC8D06949321.cache.js:1016
    bu client-5F17FE7D56927576AB18BC8D06949321.cache.js:973
    _t client-5F17FE7D56927576AB18BC8D06949321.cache.js:575
```

Such obfuscated stacktrace usually comes from Vaadin Flow, since Flow's code is written
in GWT and compiled in an obfuscated way. Read more on what could cause Flow to
blow up/throw exceptions with such obfuscated stacktraces.

### Incorrect JavaScript code in `Page.executeJavaScript()`

Flow can throw an exception if the server sends an invalid JavaScript code by the means of calling
`Page.executeJavaScript()` or `Page.executeJs()`.

If this is so, there is a yellow warning line in the JavaScript console above,
starting with `The error has occurred in the JS code: xyz`. To remedy this issue,
search for the JavaScript code snippet `xyz` in your Java code-base and perform
corrections as necessary.

See+vote [Vaadin Bug 8872](https://github.com/vaadin/flow/issues/8872) for more details.

### Deobfuscating JavaScript

It's possible to turn off the webpack minifier when building for production, to see the original deobfuscated code.
Edit the `webpack.config.js` file in your Vaadin project, and modify the `module.exports` stanza
as following:

```js
module.exports = merge(flowDefaults, {
    optimization: {
        minimize: false
    }
});
```

Now rebuild in production mode; the exception stacktrace should now point towards a much
clearer JavaScript code. Then:
 
* from the code you can learn e.g. the element tag name (for example `vcf-progress-spinner`) or the add-on name;
* from the element tag name you can learn the add-on name / homepage (e.g. [vcf-progress-spinner](https://github.com/vaadin-component-factory/vcf-progress-spinner)),
* and from there you can open a bug report (e.g. [vcf-progress-spinner #3](https://github.com/vaadin-component-factory/vcf-progress-spinner/issues/3)).

### Deobfuscating GWT

At the moment you need to build your own deobfuscated `flow-client.jar` then
replace the obfuscated one in your local Maven repo with the deobfuscated version. See+vote for
[Issue 13644](https://github.com/vaadin/flow/issues/13644).

## Others

Search the [Vaadin Flow Bug tracker](https://github.com/vaadin/flow/issues) for
any issue you will find in the JavaScript console. If the issue is not yet reported,
please report it so that it can be investigated (or Vaadin's error messages can be improved).

Please let me know at mavi@vaadin.com and I'll update this guide.
