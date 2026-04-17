# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal Jekyll blog for Martin Vysny, published via GitHub Pages at https://mavi.vaadin.com (see `CNAME`). Based on the Jekyll Now template. Posts focus on Vaadin, Kotlin, Java, Linux, and first-principles engineering topics.

## Local development

GitHub Pages builds the site automatically on push to `master`. For local preview:

```
gem install github-pages   # one-time, mirrors GitHub Pages plugins
jekyll serve               # serves on http://127.0.0.1:4000/
```

`Gemfile`/`Gemfile.lock` are gitignored — install gems globally or generate a Gemfile locally.

## Adding a post

Create a file in `_posts/` named `YYYY-M-D-slug-or-Title.md` (the existing corpus mixes `lower-case-dashed` and `Title-Case-Dashed`; either works). Required front-matter:

```
---
layout: post
title: Post Title
---
```

The URL path is derived from `title` via `permalink: /:title/` in `_config.yml`, **not** from the filename slug. When linking between posts, use the title-derived path (e.g., `../fedex-sucks/`), not the filename.

## Architecture

Standard Jekyll Now layout — nothing custom beyond a Google Analytics snippet injected in `_layouts/default.html`:

- `_config.yml` — site name, description, footer social links, kramdown/rouge settings. `url` is empty and `baseurl` is `""` because this is a user site (mvysny.github.io / custom domain).
- `_layouts/` — `default.html` (masthead + footer wrapper, loads `style.css`, embeds GA tag `G-F8ZSX2CWKG`), `post.html`, `page.html`.
- `_includes/` — `meta.html`, `svg-icons.html` (footer social icons driven by `footer-links` in `_config.yml`), `analytics.html`, `disqus.html`.
- `_sass/` — `_reset.scss`, `_variables.scss`, `_highlights.scss` (rouge/pygments theme), `_svg-icons.scss`. Imported by top-level `style.scss`.
- `index.html` — home page, lists all posts with excerpts in reverse chronological order.
- `images/` — post images and site assets.
- `CNAME` — custom domain for GitHub Pages.

## Conventions observed in existing posts

- Markdown with GFM, fenced code blocks, rouge highlighting (`css_class: 'highlight'`).
- Cross-post links use the permalink slug (the title-derived one), commonly as a relative link from another post: `[text](../other-post-title/)`.
- Images referenced from `/images/<subdir>/<file>`.
