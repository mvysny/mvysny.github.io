---
layout: post
title: Tutorial - Writing Vaadin apps in Kotlin Part 2
---

Let's add some database to our hello-world. I'll use the pure-Java embedded
database called [H2](http://www.h2database.com) which will run as a part
of our application, so there is no need for you to install any database
engine. Open the `pom.xml` file and add the following lines at the end of
the `dependencies` element:

```xml
<dependency>
   <groupId>org.hibernate</groupId>
   <artifactId>hibernate-core</artifactId>
   <version>5.2.6.Final</version>
</dependency>
<dependency>
   <groupId>com.h2database</groupId>
   <artifactId>h2</artifactId>
   <version>1.4.193</version>
</dependency>
```

**Tip:** You can add any dependency on any jar hosted in Maven central this
way. Just head to the `artifactId` element and press `Ctrl+Space`, to offer
the artifacts as you type. To auto-complete from the maven repo, one needs
to index it first though, so open **File / Settings** in IDEA, then
**Build, Execution, Deployment / Build Tools / Maven / Repositories**, select
the [https://repo1.maven.org/maven2](https://repo1.maven.org/maven2) repo
and click **update**. The update will take a while.

What we just did is that we added two Java libraries:

* The Hibernate library, which maps Java (or Kotlin) objects to rows in a
  standard relational database (or RDBMS since Java people love acronyms ;)
* The H2 database implementation

Now, let's configure Hibernate to use H2. Create the following file:
`src/main/resources/META-INF/persistence.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<persistence xmlns="http://xmlns.jcp.org/xml/ns/persistence"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/persistence
             http://xmlns.jcp.org/xml/ns/persistence/persistence_2_1.xsd"
             version="2.1">
    <persistence-unit name="h2" transaction-type="RESOURCE_LOCAL">
        <provider>org.hibernate.jpa.HibernatePersistenceProvider</provider>
        <properties>
            <property name="hibernate.dialect" value="org.hibernate.dialect.H2Dialect" />
            <property name="hibernate.connection.driver_class" value="org.h2.Driver" />
            <property name="hibernate.connection.url" value="jdbc:h2:~/temp/h2/myvaadinapp;AUTO_SERVER=TRUE" />
            <property name="hibernate.connection.user" value="sa" />
            <property name="hibernate.connection.password" value="sa" />
            <!-- <property name="hibernate.show_sql" value="true"/> -->
            <property name="hibernate.hbm2ddl.auto" value="update" />
        </properties>
    </persistence-unit>
</persistence>
```

**Tip:** to force Intellij to show the currently edited class in the Project
tree view, click on the little cog-wheel located in the header of the
**Project** Tool window and check **Autoscroll from source**.

Now right-click the `org.test.myvaadin` package in the **Project** Tool
Window and select **New / Kotlin File/class**. Type in `DB` and paste the
following contents:

```kotlin
package org.test.myvaadin

import javax.persistence.EntityManager
import javax.persistence.Persistence

private val emf = Persistence.createEntityManagerFactory("h2")

fun <R> db(block: (EntityManager) -> R): R {
    val em = emf.createEntityManager()
    try {
        em.transaction.begin()
        val result = block(em)
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

First, we have created an entity manager factory, which produces entity
managers which look after the JPA objects and map them to the database.
Next, we defined a very simple db function which runs a block in a transaction.
Note that this function is not present in any class and is thus "global" -
this seems like an anti-pattern but at some places this is immensely helpful.
Read [Kotlin Documentation on blocks or lambdas](https://kotlinlang.org/docs/reference/lambdas.html).
Now that we have the necessary machinery in place, let's create some tables.
Let's define a person - create new Kotlin class Person and paste in the following code:

```kotlin
package org.test.myvaadin

import javax.persistence.Column
import javax.persistence.Entity
import javax.persistence.GeneratedValue
import javax.persistence.Id

@Entity
data class Person(
    @field:Id
    @field:GeneratedValue
    var id: Long? = null,

    @field:Column(nullable = false, length = 100)
    var name: String? = null,

    @field:Column(nullable = false, length = 100)
    var surname: String? = null,

    @field:Column(nullable = false)
    var age: Int? = null
)
```

This is a standard JPA so-called entity - an object mapped to a table row.
[See here how exactly that is done](https://docs.jboss.org/hibernate/stable/annotations/reference/en/html/entity.html).
Let's now use all the pieces. Open the `MyUI` class and insert the following
code right at the beginning of the `init` method:

```kotlin
val persons = db { em ->
    em.persist(Person(name = "Zaphod", surname = "Beeblebrox", age = 42))
    em.createQuery("select p from Person p").resultList.joinToString()
}
```

So, we run the `db` function which starts the database transaction and gives
us the Entity Manager which is the central point for storing stuff into
the database. We have created a new person and stored it into the database;
then we queried all personnel, returned it from the block and stored into
the persons variable. Let's show the variable, in a bit of a stupid way,
but nevertheless: just change the code in the `MyUI.init()` function appropriately:

```kotlin
val name = TextField()
name.caption = persons
```

Again, please play with the code a bit. The `db` function has many shortcomings -
it does not cache/reuse Entity Managers, it does not cache JDBC Connections,
it can't handle nested calls and will create new transactions. No worries -
this is just for demo purposes. Later on we will use a real, production-ready
stuff. Stay tuned. In the next article we will show how to create forms
which will edit our Personnel.
