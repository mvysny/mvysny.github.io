---
layout: post
title: Tutorial - Writing Vaadin apps in Kotlin Part 4
---

Now if there was some way to get rid of that pesky `em ->` which needs to
be written every time one calls the `db {}` function. If only there was a
way we could tell a block to "know" some variables implicitly... Maybe we
could throw those "variables" into a class and tell the block to run as some
kind of an extension method in that class? That could work - extension methods
have direct access to the receiver object methods and variables. Remember
our `findAll()` method?

```kotlin
fun <T: Any> EntityManager.findAll(clazz: KClass<T>): List<T> = createQuery("select a from ${clazz.java.simpleName} a", clazz.java).resultList
```

The `findAll()` extension method is apparently able to access the `createQuery()`
method which belongs to the `EntityManager`. So. How about we create a object
which has `em` as its field? Right on:

```kotlin
class PersistenceContext(val em: EntityManager)
```

Now we modify the `db()` method as follows:

```kotlin
fun <R> db(block: PersistenceContext.() -> R): R {
    val em = emf.createEntityManager()
    try {
        em.transaction.begin()
        val result = PersistenceContext(em).block()
        em.transaction.commit()
        return result
    } catch (t: Throwable) {
        try {
            em.transaction.rollback()
        } catch (t2: Throwable) {
            t2.printStackTrace()
        }
        throw t
    } finally {
        em.close()
    }
}
```

The block definition changed from `(EntityManager)->R` (that is, take EntityManager
as its parameter and return R) into `PersistenceContext.()->R`, that is, pretend
that the block is some weird kind of extension method of `PersistenceContext`.
And we will call it in this new fashion:

```kotlin
PersistenceContext(em).block()
```

After these modifications you'll have compiler errors - this is because the
`db {}` block now has no parameters. Just fix them by removing the `em ->` stanza
from your `db {}` method calls.

With this approach, we can toss in some additional variables which may come
handy. For example, sometimes it is handy to circumvent EntityManager and
go directly into JDBC. No problem:

```kotlin
class PersistenceContext(val em: EntityManager) {
    val session: SessionImpl get() = em.unwrap(SessionImpl::class.java)
    val connection: Connection get() = session.connection()
}
```

From now on, you can use `connection` in your `db {}` calls. Just like that.
Awesome, isn't it?

Now, I need you to play with this thing a bit, so that it has the time to
soak in and become native to you. Because in the next lines we will combine
everything you have learned, into a mind-blowing big ball which may get too
overwhelming. Just tell me when you're ready :-)

Ready? Now I want you to read [this article and understand everything from it](https://kotlinlang.org/docs/reference/type-safe-builders.html).
Don't worry - once you grok that article, that's it - you just learned everything
I need you to know, and further text will be completely straightforward.

So, now you grok this DSL thingy. Cool, huh? You can basically model a tree
structure type-safe with Kotlin. Hey, Vaadin components are arranged in a kinda
tree fashion! You know, VerticalLayouts containing HorizontalLayouts containing
other components... Let's build a Vaadin DSL!

Let's create a Kotlin file named `VaadinDSL` and let's start by introducing
a builder method for VerticalLayout:

```kotlin
fun HasComponents.verticalLayout(init: VerticalLayout.()->Unit): VerticalLayout {
    val vl = VerticalLayout()
    add(vl)
    vl.init()
    return vl
}
```

I chose to add this extension method into `HasComponents`, so that both
`ComponentContainer`s+Layouts and `SingleComponentContainer`s are supported.
Since `VerticalLayout` is also `HasComponents`, you can now nest vertical layouts.
But there is a problem: `HasComponents` has no "add" method! Easily fixable though:

```kotlin
fun HasComponents.add(component: Component) = when (this) {
    is ComponentContainer -> this.addComponent(component)
    is SingleComponentContainer -> this.content = component
    else -> throw IllegalArgumentException("Don't know how to add items to $this")
}
```

Let's introduce a few more builders for `Button`, `TextField` and `PersonEditor`,
so that we can rewrite our `MyUI`, builder-style!

```kotlin
fun HasComponents.textField(caption: String? = null, init: TextField.()->Unit = {}): TextField {
    val component = TextField(caption)
    add(component)
    component.init()
    return component
}

fun HasComponents.button(caption: String, init: Button.()->Unit = {}): Button {
    val component = Button(caption)
    add(component)
    component.init()
    return component
}

fun HasComponents.personEditor(init: PersonEditor.()->Unit = {}): PersonEditor {
    val component = PersonEditor()
    add(component)
    component.init()
    return component
}
```

(There is some code pattern, repeating again and again. I'll leave the refactoring
to you ;). Note the default values for the init parameters. This way, the block
is not required and we can leave that out if we wish so. This allows for simple
`textField("name")` instead of having to write `textField("name") {}`. And thus,
we can rewrite the `init()` method as follows:

```kotlin
val persons = Person.findAll()

verticalLayout {
    setMargin(true); isSpacing = true
    val layout = this
    val name = textField(persons.joinToString())
    button("Click Me Kotlin") {
        addClickListener { layout.add(Label("Thanks ${name.value}, it works!")) }
    }
    personEditor {
        edit(persons.last())
    }
}
```

The structure of the Vaadin component graph is now more visible than in the previous
"flat" code. Please play with the code a bit. Next, yet another application of the
extension methods.
