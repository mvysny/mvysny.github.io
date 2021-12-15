---
layout: post
title: Force the browser to download the content
---

Unfortunately, it's not possible to tell [window.open](https://developer.mozilla.org/en-US/docs/Web/API/Window/open) to
force-download the target content:

* using `window.location.href = [url]` instead of `window.open` might seem to be working (it works for PDF and CSV files), but
  HTML and JSON files are still displayed inline in the browser, rather than being downloaded.
* The same by setting target to `_parent`.


The only way is to set the [Content-Disposition` HTTP header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition) header
to `attachment`.

This feature has been added to Vaadin 22, see [flow #5471](https://github.com/vaadin/flow/issues/5471) for more details.

