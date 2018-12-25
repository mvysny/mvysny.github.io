---
layout: post
title: Using DSL to write structured UI code
---

Creating Vaadin UIs from Java code has the following disadvantages:

* The UI structure (how the components are nested into each other) is not
  clearly visible from the code
* There is no mechanism to enforce the component configuration code to be
  grouped together in one place. If the programmer is not careful,
  the config code for different components may mix

Consider the following code:
```kotlin
class WelcomeView: VerticalLayout(), View {
    init {
        val button = Button("Save")
        val formLayout = FormLayout()
        val name = TextField()
        val age = TextField()
        name.caption = "Name:"
        age.caption = "Age:"
        formLayout.addComponents(name, age)
        addComponents(button, formLayout)
        button.icon = VaadinIcons.CHECK
        button.addClickListener {
            Notification.show("Saved!")
        }
    }
}
```

The code is a mess of random assignments, with no clear structure. The first
improvement we can do is to use the `.apply{}` function to group the component
initialization code:

```kotlin
class WelcomeView: VerticalLayout(), View {
    init {
        val formLayout = FormLayout()
        val name = TextField().apply {
            caption = "Name:"
        }
        val age = TextField().apply {
            caption = "Age:"
        }
        val button = Button("Save").apply {
            icon = VaadinIcons.CHECK
            addClickListener {
                Notification.show("Saved!")
            }
        }
        formLayout.addComponents(name, age)
        addComponents(button, formLayout)
    }
}
```

Much better. Now the component initialization code grouping is actually
enforced by the compiler. However, there is much to improve; for example
the UI structure is still not yet visible. What if we move the `TextField`
initialization code into the parent layout `.apply{}` block?

```kotlin
class WelcomeView: VerticalLayout(), View {
    init {
        val formLayout = FormLayout().apply {
            val name = TextField().apply {
                caption = "Name:"
            }
            val age = TextField().apply {
                caption = "Age:"
            }
            addComponents(name, age)
        }
        val button = Button("Save").apply {
            icon = VaadinIcons.CHECK
            addClickListener {
                Notification.show("Saved!")
            }
        }
        addComponents(button, formLayout)
    }
}
```

Now the structure emerges, but the components are inserted into parents in
a reverse order (button before the form layout) which is not what we want.
We want the components to be inserted in the very same order in which they
are create in the code. When we create a component, we typically want to
add it to the "parent" layout immediately, and we can take advantage of this:

```kotlin
class WelcomeView: VerticalLayout(), View {
    init {
        addComponent(FormLayout().apply {
            addComponent(TextField().apply {
                caption = "Name:"
            })
            addComponent(TextField().apply {
                caption = "Age:"
            })
        })
        addComponent(Button("Save").apply {
            icon = VaadinIcons.CHECK
            addClickListener {
                Notification.show("Saved!")
            }
        })
    }
}
```

Getting there, but the code is quite chatty. Maybe we could rewrite the
`addComponent()`, `Button()` and `.apply{}` into one function? The function
must know into which layout the button is going to be inserted; also the
function must run the configuration block so that we don't have to write
the `.apply{}` ourselves. The first prototype could look like this:

```kotlin
fun button(parent: ComponentContainer, caption: String, block: Button.()->Unit) {
    val b = Button(caption)
    parent.addComponent(b)
    b.block()
}
```

If we write similar functions for `FormLayout` and `TextField`, that will
allow us to write the code as follows:

```kotlin
class WelcomeView: VerticalLayout(), View {
    init {
        formLayout(this) {
            textField(this) {
                caption = "Name:"
            }
            textField(this) {
                caption = "Age:"
            }
        }
        button(this, "Save") {
            icon = VaadinIcons.CHECK
            addClickListener {
                Notification.show("Saved!")
            }
        }
    }
}
```

Better, but we keep repeating the `this` parameter. `this` always points
to the current parent layout where we want to add the components. And there
is a way to transfer `this` automatically into the function itself - by
defining the functions as an extension functions on the layout:

```kotlin
fun ComponentContainer.button(caption: String, block: Button.()->Unit) {
    val b = Button(caption)
    addComponent(b)
    b.block()
}
```

Now the code is perfect:

```kotlin
class WelcomeView: VerticalLayout(), View {
    init {
        formLayout {
            textField {
                caption = "Name:"
            }
            textField {
                caption = "Age:"
            }
        }
        button("Save") {
            icon = VaadinIcons.CHECK
            addClickListener {
                Notification.show("Saved!")
            }
        }
    }
}
```

To use this approach with Vaadin, simply use the [Karibu-DSL](https://github.com/mvysny/karibu-dsl)
library - it introduces such extension functions for all Vaadin components
for you, allowing you to build your UIs in a structured way.
