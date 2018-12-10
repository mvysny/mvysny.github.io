---
layout: post
title: Browserless Web Testing
---

Traditionally, the testing of a web portal is done from the browser, by a tool which typically using Selenium under the hood. This type of testing is closest to the user experience - it tests the web page itself. Unfortunately, it has several major drawbacks:

* It is slow as hell. A typical Selenium test case takes at least 5-10 seconds to complete, depending on the complexity of the test.
* Unreliable - the integration with Firefox breaks on every Firefox update; sometimes Selenium itself fails or timeouts randomly.
* Either requires proper IDs, or you have to use CSS/XPath selectors which are very flaky, tend to break on web portal upgrades and tend to grow to absurd lengths, making them maintainability nightmare.

Luckily with Vaadin, being a component-oriented framework, we can do better. How about we stopped testing the Browser, the client-server transport layer and the server-side http parsing code and started to test the app logic directly? Vaadin - being a server-oriented framework - holds all of the component information and hierarchy server-side after all.

By bypassing the browser and running tests "server-side", with all of the business logic directly accessible on classpath from JUnit tests, we gain:

* Speed. Server-side tests are typically 100x faster than Selenium and run in ~60 milliseconds.
* Reliable. We don't need arbitrary sleeps since we're server-side and we can hook into data fetching.
* Run headless since there's no browser.
* Can be run after every commit since they're fast.
* You don't even need to start the web server itself since we're bypassing the http parsing altogether!

Yeah, we can't test CSS with those, but we can now test all the nitty-gritty form validation paths which were just too painful and slow to test with Selenium; that leaves Selenium just for testing the happy paths. This follows the concept of the [Test Pyramid](https://martinfowler.com/bliki/TestPyramid.html):

* Most tests are quickly running simple JUnit tests which test individual classes
* In less numbers there are server-side tests which test the business logic, a basic integration and the "dark corners" of the UI rarely triggered by the user (e.g. validation, crappy user input etc). These tests are able to test surprisingly large coverage of the app.
* That leaves Selenium just tests few happy flows and the overall system integration.

## How to do that

Now if you use Vaadin, there is an alternative to this. Typically what we want is to test our business logic, which resides server-side. Typically the server-side logic is triggered by an user action: the user clicks a button in a browser, which runs the client-side code to rely a RPC to server-side, where Vaadin will run all attached click listeners, which will then execute our logic.

How about we removed the user, the client-side and the RPC from the equation? Certainly we can "click" the button (read run the click listeners) server-side, using just the Vaadin Button API. Certainly we can run a JUnit test which calls `button.click()`, given that the environment is sufficiently prepared.

As it turns out, it is rather easy to prepare the environment. All that's needed is:

* We need to create VaadinSession and set it as current, so that the UI code can rely that there is a session.
* We need to create the UI and set it as current,
* And we need to obtain Vaadin UI lock, purely because the Vaadin Framework server-side code contains countless asserts that the lock is held.

Once that's done we can simply create Vaadin components and UIs directly from the JUnit tests as follows:

```kotlin
@Before
fun mockVaadin() {
    MockVaadin.setup()
}

@Test
fun testButtonCaption() {
    val button = Button("Click Me")
    expect("Click Me") { button.caption }
}
```

(the [MockVaadin.setup()](https://github.com/mvysny/karibu-dsl/blob/master/karibu-testing-v8/src/main/kotlin/com/github/karibu/testing/MockVaadin.kt#L23) just creates `VaadinServletService`, `VaadinSession` and creates Vaadin `UI`, which provides enough environment for Vaadin components to work happily).

Well this test is not really useful. We need to test our app instead of the Vaadin Button, right? For a really simple app with no navigator we need to:

* Instantiate our UI since that creates our app's UI,
* Find components and interact with them - e.g. press the "Login" button etc.

Luckily, lot of this is provided by the Karibu-Testing library. You can see the library in action in [Karibu Helloworld Application](https://github.com/mvysny/karibu-helloworld-application). When you build the app using `./gradlew`, all tests (including the UI ones) will run automatically. The UI test is just a simple class:

```kotlin
class MyUITest {
    @Before
    fun mockVaadin() {
        MockVaadin.setup({ MyUI() })
    }

    @Test
    fun simpleUITest() {
        val layout = UI.getCurrent().content as VerticalLayout
        _get<TextField> { caption = "Type your name here:" }.value = "Baron Vladimir Harkonnen"
        _get<Button> { caption = "Click Me" }._click()
        expect(3) { layout.componentCount }
        expect("Thanks Baron Vladimir Harkonnen, it works!") { (layout.last() as Label).value }
        expect("Thanks Baron Vladimir Harkonnen, it works!") { _get<Label>().value }
    }
}
```

The `mockVaadin()` function sets up the test environment and instantiates our UI; now we're ready to test!

The `simpleUITest()` is the main meat. The test method runs with Vaadin UI lock acquired and thus we can access the Vaadin components directly. The `_get` method is provided by Karibu-Testing and serves for component finding: the `_get<TextField>(caption = "Type your name here:")` invocation finds the one text fields with given caption in the current UI; if there are none or multiple of those the function fails.

The `_click()` method on a Button is really useful since it asserts that the button is actually visible, enabled and not read-only and thus can be interacted with; if all of this is satisfied then the button is actually clicked, which invokes the click listeners etc etc.

All that's left is to assert the state of the application - we can assert that a `Label` has been added and it has a proper contents.

Note that no web server is launched, not even an embedded Jetty - it's unnecessary. This makes the test run very fast and really simple to debug - just try to place a breakpoint into the "Click Me" button click handler and try debugging the test from your IDE.

## A more complex example

With more complex apps which sport the navigator pattern, we moreover need to:

* Instantiate our UI since that creates our app's general outlook,
* Navigate to the view under testing since that populates the page with components,
* Auto-discover all of `@AutoView` views so that the navigator will work properly.
* Mock our app initialization (since we will have no server and those ContextListeners won't be run automatically)

Since we don't use Spring nor JavaEE components, we don't have to painfully start/stop those fat environments. And since we don't need the web server either, we are still able to write just a basic JUnit tests as follows:

```kotlin
class CrudViewTest {
    companion object {
        @JvmStatic @BeforeClass
        fun bootstrapApp() {
            autoDiscoverViews("com.github")
            Bootstrap().contextInitialized(null)
        }

        @JvmStatic @AfterClass
        fun teardownApp() {
            Bootstrap().contextDestroyed(null)
        }
    }

    @Before
    fun mockVaadin() {
        MockVaadin.setup({ -> MyUI() })
    }

    @Before @After
    fun cleanupDb() {
        Person.deleteAll()
    }

    @Test
    fun testEdit() {
        // pre-fill the database with a single person
        Person(name = "Leto Atreides", age = 45, dateOfBirth = LocalDate.of(1980, 5, 1), maritalStatus = MaritalStatus.Single, alive = false).save()

        // open the Person CRUD page.
        CrudView.navigateTo()

        // now click the "Edit" button in the Vaadin Grid, on the first person (0th index).
        val grid = _get<Grid<*>>()
        grid._clickRenderer(0, "edit")

        // the CreateEditPerson dialog should now pop up. Change the name and Save.
        _get<TextField>(caption = "Name:").value = "Duke Leto Atreides"
        _get<Button>(caption = "Save")._click()

        // assert the updated person
        expect(listOf("Duke Leto Atreides")) { Person.findAll().map { it.name } }
    }
}
```

This tests a fairly complex functionality of the [Vaadin-on-Kotlin example CRUD app](https://github.com/mvysny/vaadin-on-kotlin/blob/master/vok-example-crud-sql2o), namely the ability to edit a person. Let's break it down into individual pieces:

* the `bootstrapApp()` will use the Karibu-Testing built-in `autoDiscoverViews()` method to find and register all `@AutoView`s; then it will simply call the WAR bootstrap which will initialize Vaadin-on-Kotlin and run the migrations.
* The `teardownApp()` will call the WAR teardown which will close the database connection pool and tears down Vaadin-on-Kotlin
* The `mockVaadin()` will mock Vaadin environment exactly as in the earlier simple example. It will also instantiate our `MyUI` which sets up the Navigator and creates the page UI.
* Since the database is initialized and ready, we can use it freely; thus we can for example remove all persons in the `cleanupDb()` method. The `Person` itself is just a Sql2o entity; by the means of `Dao<Person>` it gains the extension methods such as `deleteAll()` and other DAO methods. To learn more about this neat-and-simple database access, just watch the [Vaadin-on-Kotlin Part 2 Video](https://www.youtube.com/watch?v=qDd-8F0TgAY).
* The bulk of the test is located in the `testEdit()` method which shows the person list, then clicks the "Edit" button on the first person, changes the name in the opened dialog and hits the *Save* button. Then we can assert the state of the database that the person has indeed been updated.

You can see the test itself here: [CrudTestView.kt](https://github.com/mvysny/vaadin-on-kotlin/blob/master/vok-example-crud-sql2o/src/test/kotlin/com/github/vok/example/crud/personeditor/CrudViewTest.kt); you can run the app for yourself simply by typing this into your terminal:

```bash
git clone https://github.com/mvysny/vaadin-on-kotlin
cd vaadin-on-kotlin
./gradlew vok-example-crud-sql2o:appRun
```

The [Karibu Testing Library](https://github.com/mvysny/karibu-testing) is available which implements this approach. You can find more information at [Vaadin on Kotlin Example Project](https://github.com/mvysny/vaadin-on-kotlin#example-project); for more information on Vaadin on Kotlin please visit the official [Vaadin On Kotlin](http://www.vaadinonkotlin.eu/) page. There is [a short introductionary video on Youtube](https://www.youtube.com/watch?v=XOhv3y2GXIE).

It takes 2 seconds on my machine to bootstrap JVM, load all classes, initialize everything, run both of those two tests and then clean up. Any further tests will typically take 60-120 milliseconds to complete since everything is already loaded and initialized. This is very fast as compare to launching a Spring application, not to mention launching a JavaEE application, launching a browser... Also, the whole setup is very easy, especially when compared to setting up a testbed to launch JavaEE server; just a tiny bit of magic as compared to tons of magic when using Spring.
