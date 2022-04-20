---
layout: post
title: Setting a background to Vaadin Grid
---

Grid background may be tricky, and the approach differs for Lumo and for the Material
theme.

## Setting the background for the entire grid

The easiest way is to wrap grid in a div and set the background to the div itself.
If that's not possible, read on.

### Lumo

The color comes from the cell background. You’ll need to override
the color in a `vaadin-grid.css` file placed in your theme/components folder,
in order to be injected into Vaadin Grid's ShadowDOM:

```css
:host(.red) [part~='cell'] {
  background-color: red;
}
```

Then add the `red` class to your Grid and voila!

### Material

Set the `--material-background-color` style to `red` on the Vaadin Grid.

## Grid rows

Read [Styling Rows and Columns](https://vaadin.com/docs/latest/ds/components/grid/#styling-rows-and-columns)
and call `grid.setClassNameGenerator()`.
Note that you need to inject the css with styles into the `<vaadin-grid>` component,
either by placing `components/vaadin-grid.css` into your theme, or loading the css
via `@CssImport("./css/my-grid.css", themeFor="vaadin-grid")`.

## Grid columns

Call `column.setClassNameGenerator()`. Inject the css as mentioned above.
