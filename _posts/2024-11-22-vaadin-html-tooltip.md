---
layout: post
title: Vaadin - HTML Tooltip
---

The default Vaadin [Tooltip Component](https://vaadin.com/docs/latest/components/tooltip)
doesn't allow HTML contents by default. But, with a bit of hacking, it can be made
to show HTML. The usual warning: if not careful, showing unescaped HTML contents
may cause your app susceptible to XSS vulnerabilities.

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
