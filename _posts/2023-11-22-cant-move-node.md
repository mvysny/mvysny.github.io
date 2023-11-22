---
layout: post
title: IllegalStateException Can't move a node from one state tree to another.
---

If you have been bitten by Vaadin's
`IllegalStateException: Can't move a node from one state tree to another. If this is intentional, first remove the node from its current state tree by calling removeFromTree`,
read on.

The problem is that a component, which is already attached to one UI, is being inserted into
another UI as well. This usually happens when:

* using DI scopes in a bad way on a component, e.g. [SessionScoped or Singleton scoped component - a very bad idea](../session-scoped-route/) 
* placing a component (e.g. VaadinIcon) into a static field (or into an enum)

Moving a component from one UI to another will cause the component to disappear from the original UI
for no apparent reasons, causing a lot of headscratching for the developer, and therefore this is definitely not a good practice.

A [Vaadin ticket 9376](https://github.com/vaadin/flow/issues/9376) discusses the problem in deeper detail.

What you need to do is:

* Figure which component is causing this issue (is moved to another UI)
* Fix scopes for that component.

You can figure out the offending component [using debugger](https://github.com/vaadin/flow/issues/9376#issuecomment-1807618311);
you can even [track where the component was created and inserted](https://github.com/vaadin/flow/issues/9376#issuecomment-1807633143).

In the future, Vaadin will print this information in the exception message itself.
