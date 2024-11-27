---
layout: post
title: Vaadin - HTML Tooltip
---

The default Vaadin [Tooltip Component](https://vaadin.com/docs/latest/components/tooltip)
doesn't allow HTML contents by default. But, with a bit of hacking, it can be made
to show HTML. The usual warning: if not careful, showing unescaped HTML contents
may cause your app susceptible to XSS vulnerabilities.

## Popover

When on Vaadin 24+, it's much better to use the new `Popover` component, since it
can attach to any Vaadin component - Tooltip only works with components that implement
the `HasTooltip` interface. See below for a bunch of tips. But, if you're on Vaadin 23,
read on.

## Tooltip

This code works in Vaadin 23+:

```java
@Route("")
public class MainRoute extends VerticalLayout {
    public MainRoute() {
        final Button b = new Button("OK");
        Tooltip tooltip = setTooltipHtml(b, "This is a <b>tooltip</b>");
        tooltip.setPosition(Tooltip.TooltipPosition.START);
        add(b);
    }

    public static Tooltip setTooltipHtml(HasTooltip component, String html) {
        final Tooltip tooltip = component.setTooltipText(html);
        final Element tooltipElement;
        try {
            final Field f = Tooltip.class.getDeclaredField("tooltipElement");
            f.setAccessible(true);
            tooltipElement = ((Element) f.get(tooltip));
        } catch (NoSuchFieldException | IllegalAccessException e) {
            throw new RuntimeException(e);
        }

        tooltipElement.executeJs("""
        function htmlTooltipRenderer(root) {
            var contentInHTML = this.text;
            if (contentInHTML !== undefined) {
                root.innerHTML = contentInHTML;
            } else {
                root.textContent = "";
            }
        };

        this._renderer = htmlTooltipRenderer.bind(this);
        """);
        return tooltip;
    }
}
```
Thanks Samuli Penttilä for this awesome tip!

## Tooltip with any Vaadin Component

Making a component implement `HasTooltip` won't cause the tooltip to magically start working:
the component client-side needs to support the tooltip machinery as well. However,
you can nest the component in a `CustomField` which does support tooltip.
An example of a wrapper class (which works as a `Div` replacement) follows:

```java
public class ComponentWithTooltip extends CustomField<Void> implements HasOrderedComponents, ClickNotifier<ComponentWithTooltip> {
    public ComponentWithTooltip() {
        setWidthFull();
    }

    @Override
    protected Void generateModelValue() {
        return null;
    }

    @Override
    protected void setPresentationValue(Void newPresentationValue) {
    }

    @Override
    public void add(Component... components) {
        HasOrderedComponents.super.add(components);
    }

    @Override
    public void remove(Component... components) {
        HasOrderedComponents.super.remove(components);
    }
}
```

## Rich Tooltip

Alternatively, try out the [rich-tooltip](https://github.com/TatuLund/rich-tooltip-demo) from Tatu.
