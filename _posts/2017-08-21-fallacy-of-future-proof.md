---
layout: post
title: Fallacy Of Future-Proof
---

Or *what-if-a-fucking-meteor-falls-down-and-swaps-1s-and-0s*

Worst atrocities has been committed in the name of future-proof.

> Hey, let's refactor this previously readable code using all design patterns we can find, so that, you know, **what if** somebody would want to add things in the future?

Ah, the dreaded "**what if**": it's easy to propose, hard to fight against, and
thus the team usually gives up after several what-ifs and just nods their heads.
In the better case those what-ifs are kept at the bottom of the backlog; the
manager is satisfied and the code is not polluted. In the worst case they are
actually implemented, twisting the code base into a spaghetti of undecypherable
patterns.

The best future-proof strategy I've seen so far is to keep the code simple and
understandable. If the code is simple, then any requirement is easy to
integrate. You must thus strive to not to be future-proof, otherwise you will
trade code readability **immediately** for some dubious future which may not
even come. Remember: complexity kills, and it's easy to introduce complexity but
hard to get rid of it.

I have just recently read parts of the *Code Change* book by Uncle Bob (he uses that nickname himself, so I will too). Ironically dubbed *A Handbook of Agile Software Craftmanship*, the book is infected with the *what-if* fallacy and it proposes to trade code simplicity for uncertain future. For example, the `Sql` class on page 147:

```java
public class Sql {
  public Sql(String table, Column[] column);
  public String create();
  public String insert(Object[] fields);
  public String selectAll();
  public String findByKey(String keyColumn, String keyValue);
  public String select(Column column, String pattern);
  public String select(Criteria criteria);
  public String preparedInsert();
  ...
}
```

What's wrong with this class? Absolutely nothing! It actually looks like an `EntityManager`. It is simple to use, auto-completion works and offers a reasonable set of utility methods. Yet Uncle Bob claims that it violates Single Responsibility Principle and proposes the following 'solution':

```java
abstract public class Sql {
  public Sql(String table, Column[] column);
  abstract public String generate();
}
public class CreateSql extends Sql {
  public CreateSql(String table, Column[] columns)
  @Override public String generate()
}
public class SelectSql extends Sql {
  public SelectSql(String table, Column[] columns)
  @Override public String generate()
}
public class InsertSql extends Sql {
  public InsertSql(String table, Column[] columns)
  @Override public String generate()
}
public class SelectWithCriteriaSql extends Sql {
  public SelectWithCriteriaSql(String table, Column[] columns, Criteria criteria)
  @Override public String generate()
}
public class FindByKeySql extends Sql {
  public SelectWithCriteriaSql(String table, Column[] columns, String keyColumn, String keyValue)
  @Override public String generate()
}
```

Uncle Bob claims that

> The code in each class becomes excruciatingly simple.

Wow, you have just fucked up the client API completely by scattering it into a bunch of undiscoverable classes, adding useless inheritance complexity, and you call that an *improvement*. Sure, go ahead and refactor your innard private classes as you see fit, I don't care as long as you give me the single `Sql` class to work with! Even more hilarious,

> Equally important, when it's time to add the `update` statements, none of the existing classes need change!

Oh, awesome! The number of the SQL language statements has not been changed for 30 years, but let's be future-proof here because *what if five completely new statements were suddenly invented*?

This points out one of the tragedies of the Java world quite nicely. We have a simple problem, so let's invent a fucking framework around it which will "solve" an entire class of problems, complicating the world around in the process. *The True Academic Way (tm) - I Don't Care About Usability As Long As I Have My Thesis*.

## How DI Was Invented - The Ironic Version

The problem with Java 1.3: it was really dumb and tedious to do DB transactions:

```java
void accomodate(Guest guest) {
  startDbTransaction();
  try {
    sql.insert(guest);
  } catch(Exception ex) {
    rollbackDbTransaction();
  } finally {
    commitDbTransaction();
  }
}
```
Then some ingenious guy discovered that proxy interfaces could do that for us. But just having a single `DB.wrap(interface)` call was deemed too simple, too particular, not abstract enough and thus improper for a true academic soul, and thus a "proper" solution (read enterprise-fucking-level complicated solution) was invented by some smartass: the XML+AOP Java solution.

![Oh look a number](https://images-cdn.9gag.com/photo/aQpnDb7_700b.jpg)

But there is no way to simply instantiate an interface, you need to instantiate a class implementing that interface, then remember to pass it to `DB.wrap` etc. This is obviously considered error-prone (because what if somebody forgets to call DB.wrap, right?) and thus it's obviously better to declare the construction chain in XML (because that's *not error-prone at all*). And thus we have wounded up with combining services (aka programming a pipeline of functionality) in XML.

Alas, the Dependency Injection was born, giving birth to Spring and JavaEE. All that simply because this Kotlin code:
```kotlin
db {
  doStuff()
}
```
was too much pain to write in a chatty Java 1.3, and because the thinking of Java guys is perverted with complexity.

Luckily, Oracle is dropping JavaEE, so that's one monstrosity down the drain; also Node.js without this DI nonsense (but with its own class of issues) is gaining momentum. Will we live to see a world without Spring and Java, but with Kotlin and a simple approach one day?
