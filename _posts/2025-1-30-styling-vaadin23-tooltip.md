---
layout: post
title: Styling Vaadin 23 Tooltip
---

[Vaadin 23 Tooltip](https://vaadin.com/docs/v23/components/tooltip)
doesn't mention how to style the tooltip, neither via CSS nor programmatically.
This article documents how to style Vaadin 23 Tooltip and even how to add
themes to it, to create different brands of tooltips.

What we need is to style the vaadin-tooltip-overlay element, namely the overlay part.
To do that, create a file named `frontend/themes/my-theme/components/vaadin-tooltip-overlay.css`
with the following contents:
```css
:host #overlay {
  color: blue;
}
:host([theme ~= "red"]) #overlay {
  color: red;
}
```
Now, all tooltips will have blue text, except for the ones with the red theme.

## How to add a theme to tooltip

The `vaadin-tooltip-overlay` element isn't accessible from Java directly. Luckily,
`vaadin-tooltip` will automatically apply any theme attribute to `vaadin-tooltip-overlay`
as well, so all we need is to use a bit of reflection to retrieve `vaadin-tooltip`
element and set a theme to it:

```java
@Route
public class MainView extends VerticalLayout {
    public MainView() {
        Button button = new Button("Say hello");
        add(button);
        final Tooltip tooltip = button.setTooltipText("Hello I'm a greeting");
        setTheme(tooltip, "red");
    }

    private static void setTheme(Tooltip tooltip, String theme) {
        try {
            final Field f = Tooltip.class.getDeclaredField("tooltipElement");
            f.setAccessible(true);
            final Element element = (Element) f.get(tooltip);
            element.setAttribute("theme", theme);
        } catch (NoSuchFieldException | IllegalAccessException e) {
            throw new RuntimeException(e);
        }
    }
}
```
