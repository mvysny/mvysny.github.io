---
layout: post
title: Safe JavaScript Keyboard Shortcuts
---

Having e.g. `Alt+Z` bound to certain functionality in your webapp helps users
to control the app quickly. However, certain browsers may reserve certain
key combinations (e.g. `Ctrl+W` to close a tab) and will not pass those combinations
to your app.

There is no general consensus on which shortcuts are safe to use and which are not.
Certain key combination might work on Firefox/Linux but not on Firefox/Mac or Firefox/Windows;
the blocked key combinations might even change between browser versions.

There are bits and pointers:

* For example [What are cross-browser and cross-OS safe keyboard shortcuts usable for web application?](https://stackoverflow.com/questions/3329420/what-are-cross-browser-and-cross-os-safe-keyboard-shortcuts-usable-for-web-appli)
  lists a couple of pointers.
* You can also try whether a particular key combo works, on the [hotkeys.js](https://wangchujiang.com/hotkeys/) page.

I think generally the safest option is to follow shortcuts used by big players:

* [keyboard scheme used by Facebook](https://www.facebook.com/help/156151771119453?helpref=faq_content)
* [Jira](https://confluence.atlassian.com/agile066/jira-agile-user-s-guide/using-keyboard-shortcuts#UsingKeyboardShortcuts-modifierkeys)
  and also here: [Jira keyboard shortcuts](https://support.atlassian.com/jira-core-cloud/docs/use-keyboard-shortcuts/)

Jira uses a concept of modifier keys which differ based on browser + OS, so perhaps
this is the best way?

| Web Browser | Mac OS X | Windows | UNIX/Linux |
|-------------|----------|---------|------------|
| Firefox     | Ctrl | Alt + Shift | Alt + Shift |
| Internet Explorer | Alt | | |
| Safari | Ctrl + Alt | Ctrl | |
| Chrome | Ctrl + Alt/Option | Alt + Shift | Alt + Shift |

TODO Edge
