---
layout: post
title: Setting a background to Vaadin Grid
---

## Lumo

The color comes from the cell background. You’ll need to override
the color in a `vaadin-grid.css` file placed in your theme/components folder,
in order to be injected into Vaadin Grid's ShadowDOM:

```css
:host(.red) [part~='cell'] {
  background-color: red;
}
```

Then add the `red` class to your Grid and voila!

## Material

Set the `--material-background-color` style to `red` on the Vaadin Grid.
