---
layout: post
title: Tutorial - Writing Vaadin apps in Kotlin Part 1
---

Kotlin provides some very interesting language features which are immensely
helpful when writing Vaadin apps. Let us start from scratch, building
necessary functionality as we progress. The result of this exercise will
be a Kotlin-based simple web app, built with Gradle, using Hibernate+JPA
o store entities into the database. I will not use Spring nor JavaEE here -
the whole thing will run in a pure Servlet environment like Tomcat or Jetty.
The complete exercise may take some 60 minutes. I will be using Intellij
IDEA Community which you can download for free here: [Download IDEA](https://www.jetbrains.com/idea/download).
When installing, just press the "Skip remaining" button to install Intellij
with the default settings.

Originally I intended to write the tutorial using Gradle, but there were
bugs in the Gradle Vaadin Plugin which would disallow the app to launch
without using IntelliJ Ultimate. Therefore I have chosen Maven with more
stable support for tooling.

Let's start by creating a Maven-based Java Vaadin project by following
[this tutorial](https://vaadin.com/maven) (I am using the `org.test.myvaadin`
groupId and `vaadin-app` as artifactId throughout this tutorial). Just
install Maven 3, follow the steps in the Vaadin tutorial and you're good
to go. After you have run the project from the command-line, just fire up
IDEA, open the `pom.xml` file with **File / Open**; then select **Open as Project**.

To run the project in IDEA, click on the bottom-left touchpad-like button
in the lower-left corner, then click **Maven Projects** in the upper-right
corner. Unwrap the tree: **vaadin-app / Plugins / jetty**, right-click
**jetty:run** and select **Run (or Debug)**. Then, point your browser to
[http://localhost:8080/](http://localhost:8080/).

Now it may be a good idea to start versioning, so that you can play with
the project safely and just revert the changes, should things go banana.
Just run this in your command-line, inside the project directory (vaadin-app):

```
$ git init .
```

Create a `.gitignore` with the following contents:

```
.idea
target
styles.css
*.iml
```

Then, in your console:

```
$ git add .
$ git commit -m "Initial import"
```

Intellij will detect a git repo, just click "Add Root" in the popup dialog.

Finally, let's Kotlinify the project. Open the `MyUI` class (by pressing `Ctrl+N`)
and press `Ctrl+Alt+Shift+K` - this will automatically convert the Java
class to Kotlin class. Intellij will show "Kotlin not configured" popup
- click "Kotlin" (not Kotlin-Javascript), then just press OK -
the `pom.xml` will be modified automatically.

**Tip:** to see the cheat-sheet with the keyboard shortcuts in IDEA, just
open the **Help / Keymap** reference menu.

Now, head back to the `MyUI` class and change the following line:
`val button = Button("Click Me Kotlin")`. Now, when you run the project
using the `jetty:run` as before (or just press `Shift+F10` since the Maven
launcher for this task has been created, just see the upper-right corner
in the IDEA window; this way you can also launch the project in debug mode),
Kotlin should auto-compile the class and the page saying "Click Me Kotlin"
should open. Good job!

Please feel free to experiment around. When you alter some code, press
`Ctrl+F9` to recompile - the code should be deployed to Jetty immediately,
just press `F5` in the browser. If not, just head down to the
**Debug Tool Window** and then press the green arrow **"Rerun 'vaadin-app'"**,
to recompile the project and restart the Jetty web server.

In the next blog post, we will add database support.
