---
layout: post
title: "AsciiDoc Slides: One Gem, One Command"
date: 2026-08-20 12:36:41 +0300
---

Earlier today I wrote about [making Claude write decks as markdown](../claude-marp-slides/)
and letting Marp do the layout. The argument holds — but Marp is a node install,
and markdown's vocabulary is deliberately tiny. If you already have Ruby on the
box, and you want fragments, vertical slides and two-column layouts without
hand-rolling HTML, the other end of the same idea is AsciiDoc:
[asciidoctor-revealjs](https://github.com/asciidoctor/asciidoctor-reveal.js).

## The whole toolchain

```bash
$ gem install asciidoctor-revealjs rouge
```

That's it. The gem has exactly **one** runtime dependency — `asciidoctor`
itself — and `rouge` is optional (more on it below). No node, no browser, no
LaTeX. It installs into your per-user gem dir, which is
[the folder you already put on your PATH](../ruby/).

Then:

```bash
$ asciidoctor-revealjs deck.adoc
$ xdg-open deck.html
```

0.15 seconds for an 8-slide deck. `file://` is fine — no server needed.

## Is it worth trusting?

I check this before every `gem install`, and this one comes out clean:

* Lives in the **official Asciidoctor org**, MIT licensed, 313 stars.
* **26 releases** since 2016, currently 5.2.0, with 6.0.0-beta.2 cut three
  days ago. Not abandoned, not churning.
* 296k downloads, and **4** open issues.
* One runtime dependency. Nothing to audit.

## The deck is one file

```asciidoc
= No Tools, More Slides
Martin Vysny
:revealjs_theme: white
:revealjs_slideNumber: c/t
:revealjsdir: https://cdn.jsdelivr.net/npm/reveal.js@5.2.1
:source-highlighter: rouge
:experimental:

== Why AsciiDoc slides?

* Slides are *plain text* -- diffable, greppable, git-friendly
* One `.adoc` file in, one `.html` out

== Lists reveal one by one

[%step]
* First this
[%step]
* then this

== Code, highlighted

[source,ruby]
----
ARGF.each { |line| puts line unless line.strip.empty? }
----

Press kbd:[S] for speaker notes, kbd:[ESC] for the overview.

[.notes]
--
This is a speaker note -- only the speaker window shows it.
--

== Vertical slides

Sub-sections nest *downwards*: press the down arrow.

=== Down here

`==` makes a new slide to the right, `===` one below it.

== Two columns

[cols="2*a",frame=none,grid=none]
|===
|
The whole toolchain:

* one gem
* one command

|
image::pipeline.svg[Pipeline,420]
|===
```

Every line in that header does one thing, and the *body* is just AsciiDoc.
`==` is a slide, `===` is a slide *below* it (reveal.js gives you exactly two
axes — right and down, no deeper). `[%step]` on a list reveals it item by item.
`[.notes]` is the speaker note. A two-column layout is an AsciiDoc table with
no frame and no grid, which sounds like a hack until you notice you never have
to touch a `<div>`.

That's the difference from markdown, and it cuts both ways: a bigger vocabulary
buys you layouts, and it also buys you enough rope to write a bad slide.

## Four things that will bite you

**`:revealjsdir:` decides where reveal.js comes from.** Leave it out and the
generated HTML points at a local `reveal.js/` directory that doesn't exist —
you get unstyled text and no idea why. Point it at a pinned CDN version like
above, or download reveal.js once and build against it:

```bash
$ curl -L https://github.com/hakimel/reveal.js/archive/refs/tags/5.2.1.tar.gz | tar xz
$ mv reveal.js-5.2.1 reveal.js
$ asciidoctor-revealjs -a revealjsdir=reveal.js deck.adoc
```

7 MB on disk, and then every asset in the deck is local — which is what you
want for the conference wifi.

**`kbd:[S]` needs `:experimental:`.** Without that one header line, the keyboard
macro doesn't error — it renders the literal string `kbd:[S]` onto your slide.
Same for `btn:[]` and `menu:[]`. I only caught it by looking at the rendered
page.

**`rouge` is a separate gem.** `:source-highlighter: rouge` without it prints
`WARNING: optional gem 'rouge' is not available` and silently drops all
highlighting. It's worth installing, because rouge highlights at *build* time —
the alternative, `highlight.js`, ships a CDN script that highlights in the
browser on every load. Server-side is one less runtime dependency in a file
you'll open on someone else's laptop.

**Keep code lines short.** There's no wrapping and no auto-shrink: a long line
in a `[source]` block just runs off the right edge of the slide, and you find
out in front of the room. My first draft lost half a one-liner that looked fine
in the editor.

## If you do need PDF

The gem only emits HTML — PDF means printing that HTML with a browser, and the
tool that does it properly is `decktape`:

```bash
$ PUPPETEER_EXECUTABLE_PATH=/snap/bin/chromium \
  npx --yes decktape reveal http://127.0.0.1:8765/deck.html deck.pdf
```

One page per slide, 960x540 pt, fragments flattened. The env var stops puppeteer
downloading a second Chrome when you already have one. Two things that don't
work: `decktape` against a `file://` URL (serve the directory — `ruby -run -e
httpd . -p 8765` is already on your box), and Chromium's non-interactive
`--headless --print-to-pdf`, which produced a single blank page for me every
time. If you want it by hand, `deck.html?print-pdf` plus Chrome's own print
dialog is the documented route.

## Why I like this one

The Marp post ended on *the format is the prompt*, and that's still the point.
What AsciiDoc changes is who's holding the tools: no node in the tree, no
watcher process, no export step — a text file, a gem, and a browser tab I
refresh myself. The build is fast enough that a refresh *is* the loop.

And the deck ends up being the only artifact I own. `deck.adoc` is 1.3 kB and
diffs like source, because it *is* source.
