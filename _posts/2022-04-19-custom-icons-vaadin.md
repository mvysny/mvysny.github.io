---
layout: post
title: Custom Icons With Vaadin 14
---

To use custom icons with Vaadin 14+, please see
[How to use Material icons in Vaadin Flow (14.6)](https://stackoverflow.com/questions/67981870/how-to-use-material-icons-in-vaadin-flow-14-6).
To embed SVGs as icons into your app, see
[Images and Icons](https://vaadin.com/docs/latest/flow/application/resources).

1. The SVG way is the easiest, just drop the svg file into `src/main/webapp/my.svg` then
   pass `new Icon("my.svg")` as an icon to any Vaadin component (e.g. button). The disadvantage of SVGs is that you
   [can't change their color easily](https://stackoverflow.com/questions/22252472/how-to-change-the-color-of-an-svg-element)
2. To embed icon font see [Custom Themes: Other Theme Assets](https://vaadin.com/docs/latest/ds/customization/custom-theme/#other-theme-assets)
   then create a `new Span()` which looks like `<span style='font-family: My Font'>&#e854;</span>` to insert an `add_shopping_cart` icon from [Google Icons](https://fonts.google.com/icons?icon.style=Outlined).
3. Do this VaadinIcons style, using iconset: see [FontAwesomeIconSet](https://github.com/FlowingCode/FontAwesomeIronIconset) sources
   for more details.
