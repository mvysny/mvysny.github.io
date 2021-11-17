---
layout: post
title: Vaadin 8 -> 14 API Counterparts
---

**EDIT:** There's a project in Github listing all API replacements now: the [karibu-migration](https://github.com/mvysny/karibu-migration).
I'm keeping this blogpost for historic reasons only.

When migrating from Vaadin 8 to Vaadin 14, there is a good basic [Vaadin Documentation on Upgrading from Vaadin 8](https://vaadin.com/docs/v14/guide/upgrading/v8).
The documentation also lists [replacement components to use in Vaadin 14](https://vaadin.com/docs/v14/guide/upgrading/v8/5-components),
but the page doesn't mention replacement APIs to use. So, here we go.

## Component

`Component.setCaption()` is no longer available. There is no direct replacement for Vaadin 14;
certain components do have `setLabel()` but not all have it, and there is no unifying interface
`HasLabel`. See and vote for [issue 956](https://github.com/vaadin/flow-components/issues/956).

Workaround is to use the following functions:

```java
public class UIUtils {
  public static void setLabel(Component component, @Nullable String label) {
    if (component instanceof Checkbox) {
      ((Checkbox) component).setLabel(label);
    } else {
      component.getElement().setProperty("label", label);
    }
  }

  @Nullable
  public static String getLabel(Component component) {
    if (component instanceof Checkbox) {
      return ((Checkbox) component).getLabel();
    } else {
      return component.getElement().getProperty("label");
    }
  }
}
```

`Component.setTooltip()` is no longer available and there is no direct replacement
for Vaadin 14. For simple tooltips you can take advantage of the [title attribute](https://www.w3schools.com/tags/att_global_title.asp)
or alternatively use the [Tooltip extension](https://vaadin.com/directory/component/tooltip/samples).

```java
public class UIUtils {
  public static void setTooltip(Component component, String description) {
    component.getElement().setAttribute("title", description);
  }

  public static String getTooltip(Component component) {
    return Strings.nullToEmpty(component.getElement().getAttribute("title"));
  }
}
```

## UI

The `UI.getUiRootPath()` is no longer available. It prints the context root with the leading slash,
e.g. `/Gradle___karibu_helloworld_application_war` and so it's perfect for creating navigational links.
A direct replacement for that is `VaadinRequest.getCurrent().getContextPath()` which can
be called anytime and will always return `/Gradle___karibu_helloworld_application_war`
(it will omit the current route path and any query parameters).

## More

For more utility methods please see the [karibu-tools](https://github.com/mvysny/karibu-tools/)
project.
