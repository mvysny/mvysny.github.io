---
layout: post
title: Vaadin 8 - Who Steals My Focus? Where did my focus go?
---

Imagine typing something into your application's `TextField`, and suddenly *bam*:
the TextField loses the focus or something else gets focused instead, for no apparent reason.
This article will summarize a list of items to review, to find out which pesky
component or code steals your focus.

# 1. Figure out in the browser who has the focus now

You can run the `document.activeElement` command in your browser's dev tools javascript console (press F12, then select the `console` tab):

```
> document.activeElement
<div id="ember1457" class="embercom-composer-editor…text shim__composer-max" contenteditable="true">
```

That should print the newly focused element, and the browser will even highlight the element for you
if you hover over the `<div...>` text in the console. Sometimes this is enough
for you to remember that special focus hack in your Java code :)

# 2. Catch all calls to `focus()` on server-side.

When server-side Java code wishes to focus a component, it calls e.g.
`TextField.focus()` which in turn goes to `UI.setFocusedComponent(Focusable)`.
You can simply place a breakpoint into the `UI.setFocusedComponent(Focusable)` function,
or you can override the function
in your UI class and simply print the component getting the focus.

You can catch all server-side attempts to focus components; however unfortunately
you will not catch any focus changes if a JavaScript/GWT code requests a focus.

# 3. Debug GWT client-side in superdevmode

You can place a breakpoint into the client-side GWT code, for example into
the `VTextField.onBlur()` function. With a little debugging,
you can probably spot which component is receiving the focus, and
even which code requested the focus change.

Please read
[Debugging Your Widgetset Components With SuperDevMode For Dummies](../Debugging-your-widgetset-components-with-superdevmode-for-dummies/)
on how to debug the GWT code of your widgetset in superdevmode.

> This chapter is very short, incomplete, and just a general suggestion. If you gather
more experience in this area, please let me know - I'll update this text and
I'll reference you as a co-author.
