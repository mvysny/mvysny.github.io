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

## Loading classic scripts from your app

You currently can't use an annotation-based approach to load a classic script locally from your app:

1. `@HtmlImport` annotation is ignored in the npm mode - it does absolutely nothing. Keep that in mind and never
    use this annotation unless you're also targeting Vaadin 14 compatibility mode.
2. `@JsModule` always loads the script as a module script;
3. `@JavaScript` always loads the script as a module script when loading the script locally.
   You can't trick `@JavaScript` to load the script "as external" from your WAR `src/main/webapp` using
   the `context://` prefix since that's broken: [Flow bug #8290](https://github.com/vaadin/flow/issues/8290).

The only way to load a script as a classic script is to place the javascript file into
e.g. `src/main/webapp/js/test.js` and call `Page.addJavaScript("context://js/test.js")`.

## Loading the script as module script

You can use both `@JsModule` and `@JavaScript` to load script as a module script.
You should always prefer `@JsModule` over `@JavaScript` when loading module scripts:

* the `@JavaScript` only loads stuff from the `frontend/` folder, while `@JsModule` is able to
load the script both from `frontend/` and `node_modules/` folder;
* also, the name `@JsModule` clearly states that the script is going to be loaded as a module script.

Certain scripts won't work as module scripts though, because of strict mode.
In such case you'll have to load them as classic scripts.

### Publishing the function to `window`

You can publish the function to the `window` object as follows:

```javascript
window.test = function test(val){
    alert('Hi'+val);
}
```

Then the function should be callable via `UI.getCurrent().getPage().executeJs("test('User')");`,
since the javascript snippet runs in the context of the `window` object.

### Exporting the function

An alternative approach would be to load the script as a module script and export the `test` function as follows:

```javascript
export function test(val){
    alert('Hi'+val);
}
```

Unfortunately, such exported function is still not callable via `UI.getCurrent().getPage().executeJs("test('User')");`
simply because the code snippet running via `executeJs()` would have to import the module script first.
That is currently not possible, please see [Flow bug #5094](https://github.com/vaadin/flow/issues/5094)
for more details.

