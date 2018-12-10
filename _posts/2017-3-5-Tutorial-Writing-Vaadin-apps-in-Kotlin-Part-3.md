---
layout: post
title: Tutorial - Writing Vaadin apps in Kotlin Part 3
---

I'll get to the forms right away. But first, I want to talk extension methods.
They are immensely helpful in adding functionality to objects. Note that Kotlin
is not a dynamic language - the methods will not really be added to target
classes, it is just a syntactic sugar. Quite delicious, though. So, EntityManager
misses the `findAll` method - let's fix that. Open the `DB.kt` file and
add this to the end:

```kotlin
fun <T: Any> EntityManager.findAll(clazz: KClass<T>): List<T> = createQuery("select a from ${clazz.java.simpleName} a", clazz.java).resultList
```

Read more on [Kotlin Extension Methods](https://kotlinlang.org/docs/reference/extensions.html).
Basically, what we just did is that we "kinda added" a `findAll` method
to the `EntityManager`, which invokes the `createQuery()` method of the
`EntityManager` itself and runs given query. From Java's perspective we
have created a static method `findAll(EntityManager $receiver, Class<T> clazz): List<T>`
on a class named `DBKt` - this is what's actually produced by the Kotlin
compiler. Let's use it and let's implement `findAll()` which finds all
Persons. I personally believe that such code belongs to the class dealing
with personnel, as per OOP imperative "code shall be with the data",
don't you agree? So, let's create a finder right on the `Person` class:

```kotlin
    @field:Column(nullable = false)
    var age: Int? = null
) {
    companion object {
        fun findAll(): List<Person> = db { em -> em.findAll(Person::class) }
    }
}
```

Companion object is Kotlin's way of doing Java static stuff. Seems more complicated
than static methods, until you realize that the companion object is also an
object, and as such it may inherit from other objects, implement an interface,
so it is immensely more powerful. Read more on [Kotlin Companion Objects here](https://kotlinlang.org/docs/reference/object-declarations.html).
Let's head back to MyUI and modify the `init()` method:

```kotlin
db { em -> em.persist(Person(name = "Zaphod", surname = "Beeblebrox", age = 42)) }
val persons = Person.findAll().joinToString()
```

There. More easy to read, and one can just intuitively head to the Person
class and auto-complete to find this useful function. We'll leave extension
methods for now, but we'll return to them as they are immensely useful.

**Tip:** Now maybe is the time to purchase IDEA Ultimate. The Ultimate edition
has a built-in database browser which also integrates with Java/Kotlin editors
and provides auto-completion and validation of your database queries. Let's
browse the embedded H2 database by opening the upper-right **Database** Tool
Window, clicking the green **+** button and import from sources. IDEA auto-discovers
the `persistence.xml`, extracts the connection string from that so you only
need to provide the username "sa" and password "sa". If the **Test Connection**
button is greyed out, see below - the H2 driver may be missing. Just click
the **Download** link, IDEA will download the driver and you will be able
to add the database. Then, expand the database, click **More Schemas - PUBLIC**,
select the `PERSON` table and press `F4` - you will see the table contents.
This kind of connection will work because [H2 is in mixed mode](http://www.h2database.com/html/features.html#auto_mixed_mode).

Now, back to the forms. We will employ Vaadin's `BeanFieldGroup` to edit the
bean. Let's create a Kotlin class `PersonEditor`:

```kotlin
package org.test.myvaadin

import com.vaadin.data.fieldgroup.BeanFieldGroup
import com.vaadin.data.util.converter.StringToIntegerConverter
import com.vaadin.ui.Button
import com.vaadin.ui.FormLayout
import com.vaadin.ui.TextField

class PersonEditor : FormLayout() {
    private val name = TextField()
    private val surname = TextField()
    private val age = TextField()
    private val fieldGroup = BeanFieldGroup(Person::class.java)
    private val save = Button("Save")

    init {
        save.addClickListener {
            fieldGroup.commit()
            db { em -> em.merge(fieldGroup.itemDataSource.bean) }
        }
        age.setConverter(StringToIntegerConverter())
        fieldGroup.bind(name, "name")
        fieldGroup.bind(surname, "surname")
        fieldGroup.bind(age, "age")
        addComponents(name, surname, age, save)
    }

    fun edit(person: Person) {
        fieldGroup.setItemDataSource(person)
    }
}
```

Be sure to study the `BeanFieldGroup` javadoc how this class works and how
it binds properties (e.g. "name" is really the name field in the Person class)
to Vaadin Fields. To use this class, modify `MyUI.init()` as follows:

```kotlin
override fun init(vaadinRequest: VaadinRequest) {
    db { em -> em.persist(Person(name = "Zaphod", surname = "Beeblebrox", age = 42)) }
    val persons = Person.findAll()

    val layout = VerticalLayout()

    val name = TextField()
    name.caption = persons.joinToString()

    val button = Button("Click Me")
    button.addClickListener { e ->
        layout.addComponent(Label("Thanks " + name.value
                + ", it works!"))
    }

    layout.addComponents(name, button)
    layout.setMargin(true)
    layout.isSpacing = true

    val personEditor = PersonEditor()
    personEditor.edit(persons.last())
    layout.addComponent(personEditor)

    content = layout
}
```

This will edit the last person in the list. Feel free to play with the editor
a bit, and check the database in the Database explorer, to see the last person
being modified by your changes. But what about validations? Try clearing
the age field and press **Save**. What happens is that Vaadin happily stores
null into Person.age which is supposedly non-null, and thus Hibernate will
complain with an exception.

To fix this, we will employ data validations, or JSR-303. Head to `pom.xml`
and add the following dependency:

```xml
<dependency>
   <groupId>org.hibernate</groupId>
   <artifactId>hibernate-validator</artifactId>
   <version>5.3.4.Final</version>
</dependency>
```

We'll add the validation annotations to the Person class as follows:

```kotlin
package org.test.myvaadin

import org.hibernate.validator.constraints.Range
import javax.persistence.Column
import javax.persistence.Entity
import javax.persistence.GeneratedValue
import javax.persistence.Id
import javax.validation.constraints.NotNull
import javax.validation.constraints.Size

@Entity
data class Person(
    @field:Id
    @field:GeneratedValue
    @field:NotNull
    var id: Long? = null,

    @field:Column(nullable = false, length = 100)
    @field:NotNull
    @field:Size(min = 2, max = 100)
    var name: String? = null,

    @field:Column(nullable = false, length = 100)
    @field:NotNull
    @field:Size(min = 2, max = 100)
    var surname: String? = null,

    @field:Column(nullable = false)
    @field:NotNull
    @field:Range(min = 15, max = 90)
    var age: Int? = null
) {
    companion object {
        fun findAll(): List<Person> = db { em -> em.findAll(Person::class) }
    }
}
```

The BeanFieldGroup will pick the annotations up automatically and will add appropriate
validators to the Fields themselves. To get rid of the horrible stack trace
hovering over the **Save** button, just modify the click listener as follows:

```kotlin
save.addClickListener {
    save.componentError = null
    try {
        fieldGroup.commit()
        db { em -> em.merge(fieldGroup.itemDataSource.bean) }
    } catch (ex: FieldGroup.CommitException) {
        save.componentError = UserError("There are invalid fields in the form")
    }
}
```

Again, please feel free to play with the code and to study the BeanFieldGroup.
Up next, juicy stuff coming. We'll learn how to build the UI properly.
