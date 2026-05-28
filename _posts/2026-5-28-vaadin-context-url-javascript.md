---
layout: post
title: "`context://` URLs in `@JavaScript` — loading static JS without Vite bundling"
---

[The original post](../Vaadin-difference-jsmodule-javascript/) lays out the modern split between `@JsModule` (bundled by Vite, lives under `frontend/` or jar `META-INF/resources/frontend/`) and `@JavaScript` (also bundled — its annotation path lands in `generated-flow-imports.js` and Rollup tries to resolve it as a module spec). There is a third option worth knowing about: the `context://` URL scheme.

## The problem

You want to ship a small JS helper in a library jar and have Vaadin's servlet serve it as-is — no bundling, no ES-module conversion, no `META-INF/resources/frontend/` placement. The natural attempt:

```java
@JavaScript("mylib/helper.js")
public final class MyComponent extends Component { ... }
```

with the file at `src/main/resources/META-INF/resources/mylib/helper.js`.

In Vite-based Vaadin (24+, 25+) this fails at frontend-bundle build time:

```
[vite]: Rollup failed to resolve import "mylib/helper.js" from
"…/generated-flow-imports.js". This is most likely unintended because it
can break your application at runtime.
```

`@JavaScript("mylib/helper.js")` emits `import 'mylib/helper.js';` into `generated-flow-imports.js`, and Vite treats the bare specifier as something it must resolve through `node_modules` or as a relative path under `frontend/`. The file is in neither place — it's a servlet-served static resource — so the bundle build aborts.

This is the asymmetry highlighted in the original post: `@StyleSheet("mylib/foo.css")` at `META-INF/resources/mylib/foo.css` works fine (it becomes a `<link href>` tag, no bundling); the equivalent `@JavaScript` does not.

## The fix: `context://`

Vaadin Flow's resource-loading machinery recognises a `context://` URL scheme (documented for `Page.addStyleSheet` in [Loading Resources](https://vaadin.com/docs/latest/flow/advanced/loading-resources), but also honoured by the `@JavaScript` annotation). When `@JavaScript`'s URL starts with `context://`, the annotation path is **not** added to `generated-flow-imports.js`; the resource is instead resolved against the servlet context path and dispatched by Vaadin's static-resource handler.

```java
@JavaScript("context://mylib/helper.js")
public final class MyComponent extends Component { ... }
```

File stays at `src/main/resources/META-INF/resources/mylib/helper.js` — the canonical servlet-served location, same shape `@StyleSheet` already uses.

## Verification

Drop the dev-bundle (`src/main/dev-bundle/`, `src/main/frontend/generated/`, `.vite/`) and start the app. Vaadin reports:

```
INFO BundleValidationUtil - A development mode bundle build is not needed
```

— no Vite invocation, no `generated-flow-imports.js` entry. In the browser, `window.myHelper` (registered by the IIFE in the helper) is defined, yet there is **no** network request for `/mylib/helper.js`: Vaadin's dependency loader inlines `context://` resources into the UIDL `?v-r=init` response and `eval`s them client-side. That's a different load path from `@StyleSheet`'s `<link>` tag, but the user-facing property is the same: not bundled, served by the servlet, drop-in for arbitrary plain JS (IIFE, `window.*` registration, anything you'd write in a `<script>` tag).

## When to reach for `context://` vs the other two

| Goal | Annotation | File location |
| --- | --- | --- |
| ES module, gets bundled, can `import` other modules | `@JsModule("./foo.js")` | `META-INF/resources/frontend/foo.js` (jar) or `src/main/frontend/foo.js` (app) |
| Plain script, gets bundled (and trips Vite if not under `frontend/`) | `@JavaScript("./foo.js")` | `META-INF/resources/frontend/foo.js` |
| Plain script, **not** bundled, served by Vaadin's servlet | `@JavaScript("context://foo.js")` | `META-INF/resources/foo.js` |

`context://` is the right tool when:

- You're shipping a small browser-side helper from a library jar and don't want the consumer's Vite bundle to grow with it.
- The JS is an IIFE that registers globals (or otherwise doesn't fit ES-module shape) and you don't want to rewrite it.
- You want symmetry with `@StyleSheet("foo.css")` at `META-INF/resources/foo.css` — both go through the servlet, both skip the bundler.

Use `@JsModule` when you actually want ES-module semantics (imports, exports, tree-shaking) or when the JS is sized such that bundling helps. Use `@JavaScript` without `context://` only if the file genuinely lives in `frontend/`.
