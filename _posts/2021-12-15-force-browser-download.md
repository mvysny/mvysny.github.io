---
layout: post
title: Force the browser to download the content
---

Unfortunately, it's not possible to tell [window.open](https://developer.mozilla.org/en-US/docs/Web/API/Window/open) to
force-download the target content. You have to use the [Content-Disposition` HTTP header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition) header.

This feature has been added to Vaadin 22, see [flow #5471](https://github.com/vaadin/flow/issues/5471) for more details.

