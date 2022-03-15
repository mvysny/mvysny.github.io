---
layout: post
title: Setting a background to Vaadin Grid
---

## Lumo

The color comes from the cell background. You’ll need to override
the color in a `vaadin-grid.css` file placed in your theme/components folder,
in order to be injected into Vaadin Grid's ShadowDOM:

```css
:host(.transparent) [part~='cell'] {
  background-color: rgba(0, 0, 0, 0);
}
```

Then add the `transparent` class to your Grid and voila!

## Material

Set the `--material-background-color` style to `rgba(0,0,0,0)` on the Vaadin Grid.
