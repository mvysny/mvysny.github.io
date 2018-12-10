---
layout: post
title: Vaadin 10 server-side layouting for Vaadin 8 and Android developers
---

The client-side in Vaadin 10 is completely different than the one in Vaadin 8 and the layouting manager from Vaadin 8 is completely gone. Vaadin 10 layouting is therefore something completely different to Vaadin 8 layouting. Naturally, it is something completely different to Android layouting. Here we will focus on layouting completely configured from server-side, and not from a CSS file.

## For Android Developers

1. There is no `RelativeLayout`.
2. There is no `AbsoluteLayout` yet.
3. There is `VerticalLayout` and `HorizontalLayout` to replace `LinearLayout`
4. To replace `ListView`, create Vaadin Grid with one column, containing components as contents. The content will be lazy-loaded and the components will be constructed lazily. The issue here is that Vaadin Grid requires all rows to have exactly the same height (or at least it used to).
5. There is no `GridView`. You can employ `FlexLayout` which allows for multi-line horizontal layouting, but there is no lazy loading and the components will be instantiated eagerly.
6. There is no table layout supported out-of-the-box by Vaadin 10. You can try to employ `css grid` but it's quite new and only [supported by latest browsers](https://caniuse.com/#feat=css-grid).

## For Vaadin 8 Developers

1. There is no `AbsoluteLayout` yet.
2. There is no `GridLayout`. You can try to employ `css grid` but it's quite new and only [supported by latest browsers](https://caniuse.com/#feat=css-grid).
3. There is a replacement for `VerticalLayout` and `HorizontalLayout` but it behaves differently. Read on for more info.
4. There is `FormLayout` and it is responsive. See the [vaadin-form-layout element documentation](https://vaadin.com/components/vaadin-form-layout) for more details; use `FormLayout` class server-side.

# Let's learn `VerticalLayout` and `HorizontalLayout`

The very important rule #1:

1. There are no slots allocated for child components. Because of that, calling `setSizeFull()` or `setWidth("100%")`/`setHeight("100%")` on children will not fill in the slot - instead it will set the component to be of the same width or height as the parent layout is. Hence it will most probably overflow out of the parent layout. Therefore, **never call `setSizeFull()` nor set width/height to `100%` unless you absolutely know what you're doing**. When you set the component to expand, it will be automatically enlarged.

The new `HorizontalLayout` and `VerticalLayout` are classes designed to mimic the old Vaadin 8 layouts as much as possible. Yet underneath they use a completely different algorithm so you can't expect a 100% compatibility. The new algorithm is called `flexbox` and you can learn about its capabilities in the [Complete Guide to Flexbox](https://css-tricks.com/snippets/css/a-guide-to-flexbox/). Don't pay too much attention to the terminology - both `HorizontalLayout` and `VerticalLayout` try to use the "older" Vaadin 8 terminology as much as possible, making it easier to understand the functionality.

We will also not use vanilla Vaadin 10; instead we will use the [Karibu-DSL](https://github.com/mvysny/karibu-dsl) library which enhances both `HorizontalLayout` and `VerticalLayout` in a way that they are more compatible with Vaadin 8. The simplest way to experiment with the layouts is to clone the [Karibu-DSL HelloWorld Application for Vaadin 10](https://github.com/mvysny/karibu10-helloworld-application) project. Just follow the steps there to get the project up-and-running in no time.

## HorizontalLayout

We'll modify the `MainView` class as follows:
```kotlin
@BodySize(width = "100vw", height = "100vh")
@Route("")
@Viewport("width=device-width, minimum-scale=1.0, initial-scale=1.0, user-scalable=yes")
@Theme(Lumo::class)
class MainView : VerticalLayout() {
    init {
        content { align(stretch, top) }

        horizontalLayout {
            content { align(left, baseline) }

            textField("Enter your name:")
            checkBox("Subscribe to spam")
            comboBox<String> {
                setItems("Once per day", "Twice per day")
            }
            button("Create Account")
        }
    }
}
```

The focus here is the `horizontalLayout`'s `content { align(left, baseline) }`. It tells the layout to align the children to the left, and vertically on the baseline:

![horizontallayout-left-baseline.png]({{ site.baseurl }}/images/2018-3-10/horizontallayout-left-baseline.png)

The `baseline` setting keeps the components in line and aligned properly on a single line. If we were to change that setting to `top`, all components would move upwards (except the `TextField` which is the largest one and is held in-place by its label):

![horizontallayout-left-top.png]({{ site.baseurl }}/images/2018-3-10/horizontallayout-left-top.png)

> Note how the checkbox is no longer aligned properly with the rest of the components - instead it is glued to the top.

Let's demonstrate the `100%` mistake. Let's set the `textField`'s width to 100% as follows:
```kotlin
            textField("Enter your name:") {
                width = "100%"
            }
```

The result is very weird: it will push other components to the right and shrinks them. I was expecting the first element to be as wide as the parent, pushing all other components to overflow; I was wrong and something else happened :)

![horizontallayout-left-top-100perc.png]({{ site.baseurl }}/images/2018-3-10/horizontallayout-left-top-100perc.png)

Let's now remove the `100%` width and let's continue. There are two more vertical alignments: `center`:

![horizontallayout-left-middle.png]({{ site.baseurl }}/images/2018-3-10/horizontallayout-left-middle.png)

And `bottom`:

![horizontallayout-left-bottom.png]({{ site.baseurl }}/images/2018-3-10/horizontallayout-left-bottom.png)

This almost resembles the `baseline` setting, but the combobox looks misaligned. Therefore, if you're aligning fields, most probably you'll want to use `baseline`.

There is one more setting which is very important if you compose other layouts in `HorizontalLayout` - the `stretch` setting.

Now for the horizontal alignments: there are the following options:

* `left`, which corresponds to flexbox's `start`
* `center`
* `right` which corresponds to flexbox's `right`
* `around`, `between` and `evenly` distributes the leftover space around the individual components.

To see the effect of those settings please see the [`justify-content` flexbox setting](https://css-tricks.com/snippets/css/a-guide-to-flexbox/#article-header-id-6).

Of course these settings work only if there is a leftover space. If the `HorizontalLayout` is set to wrap its contents or if at least one component expands, the leftover space is gone and these settings are ignored.

### Expanding

Now let's expand the TextField as follows:
```kotlin
            textField("Enter your name:") {
                isExpand = true
            }
```

The `isExpand` property only works inside of a `VerticalLayout` or `HorizontalLayout` and it is an alias for setting of the `flexGrow` to `1.0`. This makes the TextField expanded in a way that it will eat all available leftover space:

![horizontallayout-expand.png]({{ site.baseurl }}/images/2018-3-10/horizontallayout-expand.png)

Of course you can set other components to different `flexGrow` settings; a component with the setting of `flexGrow = 2.0` should roughly take two times the space of a component expanded by `flexGrow = 1.0` (this depends also on what the inherent size of the component is).

When there is no leftover space (for example because the `HorizontalLayout` wraps its content) then the `flexGrow`/`isExpand` setting is ignored. However, in this case the parent `VerticalLayout` is set to `stretch` its children to the available width, and hence the `HorizontalLayout` will be set to fill parent and that creates leftover space in order for the `flexGrow` setting will work.

Note how the components were automatically enlarged, to accommodate the space they've grown into, without any need to set their width to `100%`. Setting the width to `100%` would break the flexbox algorithm completely and would introduce weird artifacts.

Since Vaadin 10 does not use any kind of layouting engine but the CSS engine, it is actually the browser who is responsible for laying out the children. This means that you can use the browser's built-in developer tools to play with the components - you can set the flexbox properties in any way you see fit. The only disadvantage is that the flexbox terminology will differ from that of `HorizontalLayout`.

The browser is a very powerful IDE which can help you debug CSS- and layout-related issue. Take your time and read slowly through the following tutorials, to get acquinted with the browser
developer tools:

* [Chrome Developer Tools tutorial](https://developers.google.com/web/tools/chrome-devtools/)
* [Firefox Developer Tools tutorial](https://developer.mozilla.org/en-US/docs/Tools)

### Shrinking

When the components are so tightly packed that there is no room even for their preferred size, the `flexShrink` rules are taken into effect. That is however beyond the scope of this tutorial, you can read more about this at [The Guide To Flexbox](https://css-tricks.com/snippets/css/a-guide-to-flexbox) or [Mozilla's flex-shrink documentation](https://developer.mozilla.org/en-US/docs/Web/CSS/flex-shrink).

### Overriding the default alignment for children

You can override the horizontal alignment per child, by using the `verticalAlignSelf` property:
```kotlin
            comboBox<String> {
                setItems("Once per day", "Twice per day")
                verticalAlignSelf = FlexComponent.Alignment.START
            }
```

You however can't change the vertical alignment per-child.

## VerticalLayout

The VerticalLayout behaves exactly the same as HorizontalLayout does, it just swaps the axes and lays out the component along the y axis.

## Root Layout

You can use both `VerticalLayout` and `HorizontalLayout` as root layouts. Typically you set them to span the entire browser window by calling `setSizeFull()` - that's the only place where you should use the `setSizeFull()` call :-).

Of course these layouts are quite rudimentary and may not have enough expressive power to define the general UI of your app. As you grow accustomed to these layouts, you can then switch to `FlexLayout` which offers you all possibilities of the flexbox. See the mobile-first header/footer example in the [Complete Guide to Flexbox](https://css-tricks.com/snippets/css/a-guide-to-flexbox) article.
