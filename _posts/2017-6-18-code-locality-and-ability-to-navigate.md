---
layout: post
title: Code Locality and the Ability To Navigate
---

Once a project leaves the rapid development phase and enters the calm waters of
maintanenance mode, the programming paradigm changes. Fancy hyped frameworks
favored by project creators no longer play important role. What matters most now
is the code readability and understandability. The code is already written - now
it is going to be read, understood and fixed. After all, that's usually what
happens to the code - it is written once but read by many. This is true both for
open-source, but also for closed-source: people in the team come and go, and new
team members need to read the code, to familiarize themselves with it.

So far I have came up with the following main principle of project maintenance:

* You must be able to understand what the program does, **without having to run
  it**

When fixing bugs originated from production, you often don't have the
possibility to reproduce the bug in your testing environment - the production
usually contains a different set of users, different data, the workflow to
reproduce the bug may not be clear, etc. The only things you actually have are:
a log file, a stacktrace, a vague description from the user on what she did and
how she interacted with the app, and perhaps a screenshot. Usually this alone is
not enough to reproduce the bug, so you start examining the code, looking for
possible code execution flows that might have been taken by the CPU to trigger
the bug.

In other words, we maintainers need to invest the mental power to read the code
surrounding the stacktrace in hopes to discover the proper code execution flow
which may lead to the bug. All that so that we could reproduce/trigger the bug
ourselves, in our happy contained debug environment. Thus:

* **The execution flow of the code must be obvious**: you can't understand the
  algorithm if you can't follow the instructions in the algorithm. Too many
  misnamed utility methods, too many asynchronous calls with callbacks (
  especially if they continue the algorithm in a completely different
  class/actor/observable) seriously hinder the readability.

To find the code execution flow that led to the bug, you usually need two
things:

* A stacktrace, with possibly good error message, to point you at the end of the
  code execution flow, and
* The code, obviously.

The better the stacktrace, the stacktrace's message and the code, the faster we
can discover the code execution flow. In order to discover the code execution
flow faster, the code should have the following properties:

* **Code Readability** - it's obvious on the first sight what the code does. By
  no means I'm implying that the code is the documentation; however to fix a
  bug, one first needs to read the code and understand it. Badly named
  variables, too many clever `filter`s in your `List`-filtering code, and you'll
  need comments to explain that particular spaghetti.
* **Code Locality** - the code doing similar functionality should be co-located:
  in one class, in one file, in one package. That's how we human beings like
  things that relate - nicely wrapped in one box.
* **Ability to Navigate** - to understand the algorithm one must understand the
  functions which the algorithm calls. You must be able to `Ctrl`+click to
  anything in the code and IDE must navigate to code which implements that
  thing, be it a function, class, interface, operator, property, anything.

I have drafted a sketch list of things that tend to hinder these properties.

## Overzealous protection against copy-paste

*Affects: Code Readability*

So now you've extracted all repetitive code to utility methods. Congratulations!
Now your function calls a function, which calls a function, which calls a
function... If those functions are not well-defined or they are misnamed, the
code readability will suffer.

Often there are multiple methods which share only a few lines of the code. One
usually extracts the moving parts to an abstract class (generally a bad idea,
see below) or introduces some builder, with moving parts injected as blocks
or `Runnable`s (ugly, but better than using inheritance).

Remember: every rule has an exception and sometimes it's better to copy-paste.
Especially in the UI world: either turn part of the UI into a reusable
component, or copy-paste mercilessly.

## OOP Inheritance

*Affects: Code Readability*

The main principle of OOP is still awesome: cram related code to a single class,
which improves code locality. Hiding stuff into `private` produces sane
autocompletion results and makes your component really usable. Trouble starts
when you start using functionality from those classes. You generally have to
choose whether to use functionality (that is, call methods) from other class
either by reference, or by inheritance.

Composition promotes components: reusable objects with well-defined API that do
not leak their internals and do stuff. This is the good approach.

Inheritance promotes adding functionality by extending classes. Peachy, but it's
not easy to do it properly.
Quoting [Josh Bloch: Design and document for inheritance or else prohibit it](https://medium.com/@rufuszh90/effective-java-item-17-design-and-document-for-inheritance-or-else-prohibit-it-be6041719fbc):

1. Your protected methods are now part of the API as well
2. Constructor must not invoke overridable methods. This is because the
   overrided method in the constructor of super class will always be invoked
   before the constructor of the sub class. This may cause invocation of an
   object before that object has been initialised properly.

Ever tried to read a class which extended a deep hierarchy, and methods were
magically called out of nowhere? You're effectively combining your class with
all of the code from all of the subclasses, and you need to understand those as
well. This hurts code locality (since superclasses are located completely
elsewhere), and also code navigability (since it may only be clear at runtime
what the method will actually do, thanks to polymorphism).

I once had a colleague who blindly followed the newest hip rule in OOP,
quoting: *"every class must have an interface"*. There were *lots* of interfaces
in that project. `Ctrl`+Click would bring you to an interface. Luckily nowadays
with Intellij you just press `Navigate - Implementations`, but it hurted the
code navigability quite badly back then.

## Dynamically-Typed Languages

*Affects: Ability to Navigate*

The very foundations of dynamic languages (say, JavaScript, Ruby, Python) are
based on duck-typing - if a class has `quack()` method then it can quack. The
problem with duck-typing starts to show once you `Ctrl`+click on the `quack()`
function call and realize that the IDE has no way of knowing of:

* which class you are trying to call (since you often do not specify the type of
  the class)
* whether the callee class actually has the `quack()` method or not (since
  the `method_missing()` catch-all may be used)

Thus, on every `Ctrl`+click, the IDE usually presents all classes that
define `quack()` method (unless it can guess the callee class type); and this
list may actually not list all possible target code points because
of `method_missing()`.

## Incorrect Code Grouping

*Affects: Code Locality*

Sometimes people tend to put all JPA entities into one package, all Controllers
into the `controller` package, all Views into the `view` package. This causes
the code to be grouped by type instead of by the functionality. This is the same
fallacy as grouping racing cars by color (not the best parable but it's the best
I have ;).

The fix is actually quite easy: all Views, Controllers and JPA entities dealing
with the customer should instead be placed into the `customer` package (unless
of course there is a glaring reason to do otherwise, for example when the JPA
entity resides in a completely another layer, invoked remotely via REST).

## Overuse of Annotations ([Annotatiomania](http://www.annotatiomania.com/))

*Affects: Ability to Navigate, Code Readability, Code Locality*

An example:

```java
@Transaction
@Method("GET")
@PathElement("time")
@PathElement("date")
@Autowired
@Secure("ROLE_ADMIN")
public void manage(@Qualifier('time')int time){
        ...
        }
```

`Ctrl`-clicking on `@Transaction` will take you to the Transaction annotation
definition which contains no code. To actually see the code, one needs to search
for any code touching that annotation in all libraries (and this is actually
impossible with JavaEE). And then one usually encounters an uber-complex
function dealing with all of the annotation parameters (say, code dealing
with `Required`/`RequiresNew`/`Mandatory`/`NotSupported`/`Supports`/`Never`
transaction attributes, XA transaction handling, bean/container managed
transactions) which is virtually impossible to grok in a sane time span.

The idea behind annotations is noble: to standardize a particular functionality
and make it configurable via annotations. Using the
convention-over-configuration principle one can often simplify the annotated
class so that the intent is immediately clear (
say, `@RequiresRole("ROLE_ADMIN")`). However, often that is not enough, and in
the fervous attempt of avoiding code writing, an annotation-based DSL language
is born. Usually with morbid results, for
example `@Secure({@And(@RequiresRole(@Or("ROLE_ADMIN", "ROLE_MANAGEMENT")), @RequiresLoginPlace("ACME_HQ")})`
. The problem is that annotations do not actually execute anything; the actual
implementation handling all aspects of the configuration is thus someplace else,
not easily reachable (making the possibility to navigate hard). This can be
remedied for example by specifying access verifier class in the annotation;
however the code that actually calls the verifier class is still hardly
reachable.

However, sometimes this may be acceptable.
Say, [Retrofit](http://square.github.io/retrofit/): the library is simple enough
so that the functionality is clear; also one rarely needs to actually dig into
its core and check how exactly that `GET` is executed. And since Retrofit forms
a simple detained island which does just one thing (as opposed to Spring with
all its plugins which tend to permeate all of your code base), the complexity is
detained within an acceptable black box.

The interceptor annotations such as `@Transactional` can be replaced with custom
functions with blocks, for example:

```kotlin
db { em.persist(person) }
```

The `db` is just a function which starts and commits (or rollbacks) the
transaction. It has some 15-20 lines, is easy to understand, and you can just
Ctrl+Click on the `db` function name to navigate directly to the source code.
The idea behind the `db {}` function is described in mode depth
in [Writing Vaadin Apps In Kotlin part 3](../Tutorial-Writing-Vaadin-apps-in-Kotlin-Part-3/)
. And you can just call this function from anywhere, as opposing of having an
injector everywhere (by making all classes managed beans) and injecting
@Transactional class which finally can call the database.

Should the `db{}` function stop serving your needs (no XA or other reason), just
fork and write your own, or use XA vendors. It's actually not that hard: the
dirty little secret of XA is that it is still not 100% error proof; naive
approach may work here quite well.

### JPA

*Affects: Ability to Navigate*

JPA is a tough beast. Its sheer amount of annotations makes you want to run and
hide. There is absolutely no way one can understand what's going on behind the
scenes by a simple Ctrl+click approach. However, once one follows a good
tutorial and learns how to navigate himself around pitfalls such as detached
beans, then it does its job and is again an acceptable black box.

Yet, I grew weary of constant surge of exceptions, N+1 selection problems and
now I just select exactly what I need with plain SQL selects, using sql2o plus a
bit of code to add simple CRUD capabilities in
the [Vaadin On Kotlin](https://github.com/mvysny/vaadin-on-kotlin) framework.

## Loose Coupling

*Affects: Ability to Navigate*

Loose Coupling of large modules makes sense - it's not easy to understand the
modular structure of the app if all of the modules leaks internals like hell.
However, it is easy to go all loose-coupling-crazy, stuff everything behind
interfaces and thus turning `Ctrl`+click into searching for implementors of that
particular function (and God forbid should there be more than one!). The
granularity here really matters. Loose Couple on module level, tightly couple on
package level.

Argumenting by loose coupling is often fallacious. Say, "using Rx makes your
code loosely coupled". This actually sounds like a good thing, until you realize
that you can no longer see the code flow! To rebute this fallacy, just ask:

1. Do we need loose coupling in this particular place?
2. Does it outweight the cost of not seeing the code flow anymore? (Usually it
   doesn't).
3. Are you just fallaciously promoting your favourite framework?

Remember: Loose coupling directly reduces the ability to navigate and the
possibility to read the code flow.

## Interceptors / Aspects

*Affects: Ability to Navigate*

The interceptors/aspects are immensely popular with the Dependency Injection
frameworks.
However, when overused, this can become a maintenance nightmare.
Usually interceptors are employed by the means of annotating
class/function, which hurts the ability to navigate,
but is still doable - by searching all accessors of that particular
annotation one can eventually learn the code that "executes"
the annotation (even though this gets harder as the number of annotated
components increase). However, interceptors can also be configured (in Spring
XML or Guice Module) so that theyapply to certain class types (and subclasses)
only, and that makes them virtually undiscoverable for any coder who just joined
the project.
This directly boosts the coder's frustration and the desire to leave that
project,
which is not what you want.

One of the solutions may be to use functions with blocks instead, as shown
with the `db {}` example.

## Java Stream API

*Affects: Code Readability*

A simple filtering with Java Stream API turns into this:

```java
list.stream().filter(it->it.age>0).collect(Collectors.toList());
```

The `stream()` and `collect(Collectors)` is just a noise, however in Java this
noise takes almost half of the entire expression, which decreases readability.
Compare that with the following Kotlin expression:

```kotlin
list.filter { it.age > 0 }   // the result is already a list.
```

Going more stream-crazy allows you to write unreadable code like this:

```java
Stream<Pair> allFactorials=Stream.iterate(
        new Pair(BigInteger.ONE,BigInteger.ONE),
        x->new Pair(
        x.num.add(BigInteger.ONE),
        x.value.multiply(x.num.add(BigInteger.ONE))));
        return allFactorials.filter(
        (x)->x.num.equals(num)).findAny().get().value;
```

Please read more
at [This Is Not Functional Programming](http://www.vitavonni.de/blog/201603/2016030101-stop-abusing-lambda-expressions---this-is-not-functional-programming.html)
. Streams are to be used cautiously: Java's nature is not a functional one, and
using Java with functional approach is going to produce weird code with lots of
syntactic sugar, which will make little sense to traditional Java programmers.

To avoid the noise introduced by Java you can consider switching to Kotlin.

## Java Optional API

*Affects: Code Readability*

Optional is the Java's way to deal with nulls. Unfortunately Optional introduces
methods which tend to be used instead of the built-in `if` statements. Consider
this code:

```java
optionalString=Optional.ofNullable(optionalTest.getNullString());
        optionalString.flatMap(s->something).ifPresent(s->{System.out.println(s.toString());}).orElseThrow(()->new RuntimeException("something"));
```

Using the traditional approach of `if`s and `null`-checks would have worked
better here.

Optional is also capable of breaking of the Bean API. Consider the following
code:

```java
public void setFoo(String foo){}
public Optional<String> getFoo(){}
```

This is actually **not** a property since the type for setter and getter
differs.
This also breaks the Kotlin support for propertyising Java beans. The code could
be fixed by changing the setter to `setFoo(Optional<String> foo)` but that makes
it really annoying to call the `setFoo` method.

Instead, it is better to use Intellij's `@NotNull` annotation and traditional
language statements. The resulting code tends to be way more readable than
any `Optional` black magic.

## Spring, JavaEE, Dependency Injection

*Affects: Ability to Navigate, Code Readability, Code Locality*

Spring was founded as an alternative for J2EE, which in the old days contained a
lot
of XMLs. At that time it was lean; nowadays it has tons of modules, with varying
quality of the documentation. It seems that Spring permeates everything and uses
all of the above methods:

* In a lots of projects, the wiring granularity is too high. Instead of wiring
  modules,
  it often wires classes, often with synthetic interfaces in front of those.
  This is basically
  Loose Coupling on a way too granular level, which makes the navigation in such
  code harder.
* Uses interceptors/annotations heavily. Spring Data, Spring Security for
  example.
  Spring Security has became so huge that coders are avoiding it on purpose.
* Uses clever tricks to employ interceptors. To employ interceptors to a class,
  Spring uses the CGLIB library to create a dynamic class which extends the
  original one,
  overrides all methods and invokes interceptor chain. This has the unfortunate
  side-effect of having lots of `$$$PROXY` fields with null values which clutter
  the state of the original class.

JavaEE suffers from the very same problems, and adds the following issues on
top:

* It is impossible to see the actual implementation of, say, `@Transactional`,
  since it's implemented somewhere in the application server, which may not even
  be OSS. And even if it was possible, the code is highly complex and hard to
  read.
* If JavaEE can't employ annotation, it simply will ignore it. For example,
  calling `@Asynchronous` method on the same bean instance will silently result
  in a synchronous call. This directly violates the main principle since the
  program silently does something else than it should, from the look of the
  code. To actually call the method asynchronously, the class needs to inject
  itself and call the method on that.

The Dependency Injection paradigm is highly invasive. For example, the need of
injecting classes into Vaadin (or Swing, JavaFX) components: since all DI
frameworks usually tend to
hide Injector from the programmer, the programmer usually makes every Vaadin
component a managed bean,
to have depending services injected. This makes it harder to use java-debug
class-reloading techniques.

I've seen people using Spring only because of `Spring Boot`, since it is a pain
in
the ass to launch a war project in Eclipse. Let me rephrase: one's code base
hurts just because the tooling of his choice sucks.

## Overuse of async: Reactive, EventBus, AKKA

*Affects: Code Locality, Ability to Navigate*

Reactive, Rx, React or whatever the asynchronous programming is called today. On
larger granularity, and with proper task, it makes total sense to employ AKKA
Actors: when they are big enough in order for them to form a grokkable box of
synchronous functionality in which you can navigate. Also, in large loads,
having too many thread being blocked will cause their stacks to eat the memory,
so async is always the way to go, right? It depends.

It is true that it is extremely handy to have only a single thread in `node.js`,
or a single thread in AKKA actor consuming messages, as opposed to traditional
multi-threaded approach. With a single thread, you don't need to worry yourself
with guarding your shared state with locks. And with advanced techniques like
promises and/or coroutines, neither code locality nor ability to navigate
suffers.

Shit tends to hit the fan when you have a hammer labelled Rx and every problem
is a nail. Then, usually `Observable` gets slammed on every button listener,
splitting the previously readable synchronous listener method into chunks of
three-line asynchronous objects. There is no way to navigate there - this is
like a too granular Dependency Injection all over again, since the code which
configures (creates a pipelines of those asynchronous small blocks) is usually
completely elsewhere than the code itself. This horribly affects the code
locality.

Even worse when you have lots of actors with no promises/coroutines to handle
request/response type of messages. If all you have is just an `onMessage()`
method, then it's usually very hard or impossible to figure out who sent the
message and thus who the caller is, and thus the ability to navigate suffers.
And even more worse when the actor needs to send and receive messages in certain
order. Then you need to mark down in the actor state which message you already
received and which you still need. You are effectively creating a defensive
state machine. State machines are hard to maintain, since by adding more state
raises the possible code execution flows exponentionally. This price is rarely
worth more than any dubious benefits the async approach may have.

Debugging suffers with async as well - it is no longer possible to debug and
check the stacktrace for the information who called you, since the caller is
usually a background message-processing thread. To actually get the caller, you
need to track the code which created the message, as mentioned above.

The motto of EventBus - *fire [the event] and forget* - can be read as *I have
no idea what is going on when I fire this event* since it's nearly impossible in
design time to discover all event receivers who gets notified. This hurts the
ability to navigate.

## Java 8 Default Methods on Interfaces

*Affects: Code Locality*

Everything is fine when the default methods are used purely as utility methods (
or in place of extension methods since Java is lacking those). The hell breaks
loose if the interfaces are used as traits, adding completely new functionality,
demanding to store the state as in the following example:

```java
interface Bark {
    public abstract int getBarkedCount();

    public abstract int increaseBarkedCount();

    default public String bark() {
        increaseBarkedCount();
        return "barked " + getBarkedCount() + " times";
    }
}
```

Of course this example is simple, silly and self-explanatory. Yet, imagine
having 4-5 of such interfaces implemented on an object, each bringing its tiny
little functionality inside the object, but every piece of functionality stored
in a different file. The code locality suffers: it can no longer be seen what
the object is responsible for, what's the actual state and what are the state
mutation paths. The object becomes a God object with a lots of responsibilities.

## Missing Comments

*Affects: Code Readability*

Quoting Uncle Bob's Clean Code book, chapter 4:

> Comments are, at best, a necessary evil. If our programming languages were
> expressive enough [...], we would not need comments very much. The proper use of
> comments is to compensate for our **failure** to express ourselves in the code.

That's totally wrong, stupid, and very dangerous:

1. People who take that literally will end up with having no comments in their
   code, and they will be proud of that. I can't even begin to describe how
   stupid that is.
2. Uncle Bob actually contradicts himself - at first he says that all comments
   are evil, and then he lists examples of good comments: legal comments (!!!
   yeah, truly the most important type of comments. Uncle Bob, certainly you do
   care about code clarity, right?), informative comments, explanation of
   intent...
3. The "expressive language" myth is easy to debunk: there is no such language.
   Scala tried and failed to produce not even code with intents, but even
   readable code. Computers don't execute intents, they execute code and they
   don't care about intents. Computer code is not about what we want the
   computer to do, it is about what the computer will do, and those are two
   different things. Thus, we need comments to explain our intents.

In short, having no comments because of fear that the comments may get obsolete,
is just plain stupid.

## Scala

*Affects: Code Readability*

There are languages which say what they do in English, and then there's Scala:

![scala.png]({{ site.baseurl }}/images/scala.png)
