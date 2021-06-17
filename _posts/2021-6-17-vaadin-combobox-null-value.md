---
layout: post
title: Adding support for null values to Vaadin ComboBox
---

Vaadin 8 used to have the `ComboBox.setNullSelectionAllowed(true)` function which enabled
the user to select an empty item in the ComboBox. Vaadin 14 does not seem to
have the same function, so what to do next?

At first, I tried to add the `null` item amongst the list of items set via `setItems()`:

```kotlin
combobox.setItems([null] + items)
```

But that only resulted in a NullPointerException with the message
`"Cannot provide an id for a null item."` thrown from `DataProvider.getId()`.
You could hack around, by overriding the `getId()` method and making it return an empty string
in case of a null item, but once you start using lazy loading, you'll quickly hit a dead end.

The solution is to show the "Clear" button as follows:

```kotlin
combobox.setClearButtonVisible(true)
```
