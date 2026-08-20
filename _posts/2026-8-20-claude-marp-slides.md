---
layout: post
title: "Claude Makes Slides: Markdown In, Deck Out"
date: 2026-08-20 12:20:14 +0300
---

When you want a deck, the tempting move is to ask the model for the thing you
actually want to end up with — a `.pptx`. Don't. Asking an LLM for a
presentation *file* turns it into a layout engine: it invents a grid, picks font
sizes, decides how much whitespace a bullet deserves, and quietly negotiates
with itself about where the box goes. Every token spent on that is a token not
spent on your argument, and the output drifts between decks because nothing
holds it to a shape.

Give it markdown instead and let a real tool do the layout. That tool is
[Marp](https://marp.app).

## The whole toolchain

There's no `apt` package, and the `marp-cli` in the snap store is a third-party
build sitting at 1.1.1 while upstream is at **4.5.0** — so this one is a node
install:

```
npx @marp-team/marp-cli@latest deck.md -o deck.html
```

`npx` while you're curious; `npm i -g @marp-team/marp-cli` once you're sold.
There are also standalone binaries on the releases page if you want no node on
the box at all. HTML export needs nothing else — no browser, no LaTeX. PDF,
PPTX and PNG shell out to Chrome/Chromium.

## The deck is one file

That file, in full, is what Claude writes:

````markdown
---
marp: true
theme: default
paginate: true
---

<!-- _paginate: false -->

# Composition Over Inheritance
## and the one place to break it

---

## The rule

- inherit to *be* a thing
- compose to *share* a thing

```kotlin
class Foo : JComponent() { }
```

<!-- This is a speaker note. Nobody sees it on the slide. -->

---

<!-- _class: invert -->

## The carve-out

UI components. Every time.
````

Everything you need is in there. `---` separates slides. Front matter is
written once. A comment starting with `_` is a **scoped directive** — it applies
to that one slide only, so `_paginate: false` de-numbers the title page and
`_class: invert` gives you a dark slide for the moment you want the room to
shut up. A comment *without* the underscore is a speaker note; `--notes` dumps
them all to a text file for your presenter monitor.

Then `--pdf` when you need something to email.

## The loop that actually earns the setup

This is the part worth the install:

```
marp -w deck.md -o deck.html
```

Watch mode injects a WebSocket into the generated HTML — I checked, it's
`__marpCliWatchWS` in there — so the browser reloads itself the instant the
markdown changes. Put the browser on one half of the screen and Claude on the
other, and you *watch the deck assemble* while you argue with it about slide
four. No export step, no refresh, no clicking.

## Three things that will bite you

**Always pass `--no-stdin`.** Run marp-cli from a script, a Makefile or an
agent and it blocks forever waiting on stdin. My first automated run hung for
three minutes in total silence before finally admitting `finished reading. (Pass
--no-stdin option if it was not intended)`. Nothing about the symptom points at
the cause.

**Point `CHROME_PATH` at your browser.** If the only Chromium you have is the
snap, PDF export needs `CHROME_PATH=/snap/bin/chromium` to find it. HTML export
doesn't care.

**Don't keep local images under `/tmp`.** Snap-confined Chromium can't see the
host's `/tmp`, so `![bg right:40%](logo.png)` from a scratch directory silently
degrades to `The local file is missing and will be ignored`. The identical deck
in `~/` renders the image fine. Keep decks in a real project directory.

## Tell Claude the rules once

Drop this in `CLAUDE.md` next to the deck and stop repeating yourself:

```
Decks are `deck.md`, rendered by marp-cli. When editing one:
- One idea per slide. Max 5 bullets, max ~10 words each.
- Slides split by `---`. Never write raw HTML to fake a layout.
- Stick to front matter + `---` + headings/bullets/code fences.
- Prose belongs in speaker notes, not on the slide.
- Always invoke marp with `--no-stdin`.
```

The bullet-count line is doing more work than it looks. Left alone, a model
writes *documents* — full sentences, eight bullets deep — and markdown will
happily render a wall of text at 12pt. The format stops the layout disasters;
you still have to stop the essays.

## Why this works

It isn't the themes, and it isn't the PDF export. It's that markdown makes the
bad deck **unwriteable**. Claude can't hand me a fourteen-bullet slide with a
hand-rolled two-column div and a font size chosen by vibes, because there is no
syntax in which to say it. The vocabulary is headings, bullets, code and a
slide break, so the only variable left is whether the content is any good —
which is the only thing I wanted to review in the first place.

The format is the prompt.
