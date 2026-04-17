# mvysny.github.io

Personal Jekyll blog for Martin Vysny, hosted at <https://mvysny.github.io/>. Based on the Jekyll Now template. Posts focus on Vaadin, Kotlin, Java, Linux, and first-principles engineering topics.

## Local development

```
gem install github-pages   # one-time, mirrors GitHub Pages plugins
jekyll serve               # serves on http://127.0.0.1:4000/
```

`Gemfile`/`Gemfile.lock` are gitignored — install gems globally or generate a Gemfile locally.

## Architecture

Standard Jekyll Now layout — nothing custom beyond a Google Analytics snippet injected in `_layouts/default.html`:

- `_config.yml` — site name, description, footer social links, kramdown/rouge settings. `url: "https://mvysny.github.io"` and `baseurl: ""` (user site, no project path, no custom domain).
- `_layouts/` — `default.html` (masthead + footer wrapper, loads `style.css`, embeds the GA tag), `post.html`, `page.html`.
- `_includes/` — `meta.html`, `svg-icons.html` (footer social icons driven by `footer-links` in `_config.yml`), `analytics.html`, `disqus.html`.
- `_sass/` — `_reset.scss`, `_variables.scss`, `_highlights.scss` (rouge/pygments theme), `_svg-icons.scss`. Imported by top-level `style.scss`.
- `index.html` — home page, lists all posts with excerpts in reverse chronological order.
- `images/` — post images and site assets.

## Conventions observed in existing posts

- Markdown with GFM, fenced code blocks, rouge highlighting (`css_class: 'highlight'`).
- Cross-post links use the permalink slug (the title-derived one), commonly as a relative link from another post: `[text](../other-post-title/)`.
- Images referenced from `/images/<subdir>/<file>`.
