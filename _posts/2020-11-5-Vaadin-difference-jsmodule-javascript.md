---
layout: post
title: Vaadin 14 - difference between `@JsModule` and `@JavaScript` in npm mode
---

The problem is usually that you have a script such as

```javascript
function test(val){
    alert('Hi'+val);
}
```

You try to load it via `@JavaScript` then call the function as `UI.getCurrent().getPage().executeJs("test('User')");`
and it doesn't work. See [Flow bug #8285](https://github.com/vaadin/flow/issues/8285) and this
[Vaadin Forum question](https://vaadin.com/forum/thread/18116726/javascript-function-defined-in-jsfile-used-by-javascript-annotation-is-n)
for more details.

The reason is that the script has been loaded as module script; and since the `test` function was not published,
it is internal in the module and nobody can access it.

## Module Scripts versus Classic Scripts

When you read the javadoc on `@JsModule` and `@JavaScript` and/or read the
[Storing and Loading Resources](https://vaadin.com/docs/v14/flow/importing-dependencies/tutorial-ways-of-importing.html)
documentation, it's not clear what the difference between the two are, apart maybe from
the loading order.

The main difference is that `@JsModule` always loads the script as the module script,
while `@JavaScript` loads the script either as the module script (if the path to script is prefixed with `./` - then the script will be loaded from the `frontend/` folder),
or as a classic script (if loading from the external URL such as `https://`).

The difference between the module script and the classic script is summarized at the
[Classic scripts v/s module scripts in Javascript Stack Overflow Answer](https://stackoverflow.com/a/53821485/377320).
Quoting:

1. Modules are singleton. They will be loaded and executed only once.
2. Modules can use import and export.
3. Modules are always executed in strict mode.
4. All objects (class, const, function, let or var) are private unless explicitly exported.
5. The value of "this" is undefined at the outer scope (not window).
6. Modules are loaded asynchronously.
7. Modules are loaded using CORS. see Access-Control-Allow-Origin: *.
8. Modules don't send cookies and authentication info by default. See crossorigin="use-credentials".
9. imports are resolved statically at load time rather than dynamically at runtime.
10. html comments are not allowed.

You should always prefer js code which loads as the module script - you can find such libraries in the npmjs
repository. However, certain old scripts won't work as module scripts (most probably because of the strict mode);
then you will need to load them as old scripts.

## Loading Classic Scripts

You currently can't use annotation-based approach to load a classic script locally from your app:

1. `@HtmlImport` annotation is ignored in the npm mode - it does absolutely nothing, keep that in mind!
2. `@JsModule` always loads the script as a module script;
3. `@JavaScript` always loads the script as a module script when loading the script locally.
   You can't use `@JavaScript` to load the script as if "external" from your WAR `src/main/webapp` using
   the `context://` prefix since that's broken: [Flow bug #8290](https://github.com/vaadin/flow/issues/8290).

The only way to load a script as a classic script is to place the javascript file into
e.g. `src/main/webapp/js/test.js` and call `Page.addJavaScript("context://js/test.js")`.

Alternatively, you can load the script as a module script and publish the function as follows:

```javascript
window.test = function test(val){
    alert('Hi'+val);
}
```

However, certain scripts won't work as module scripts because of strict mode.
You'll have to load those via `Page.addJavaScript`.
