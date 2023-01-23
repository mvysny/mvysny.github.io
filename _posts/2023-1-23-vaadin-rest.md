---
layout: post
title: REST server with your Vaadin app
---

The easiest way to add REST server to your vaadin app is to use [Javalin](https://javalin.io)
in the standalone mode. By default, Javalin runs its own Jetty server. However, your
Vaadin app is already running in a servlet container. We can simply exclude Jetty from Javalin dependencies
and use Javalin via the regular Servlet API.

Add Javalin to your build script:
```groovy
    implementation("io.javalin:javalin:4.6.7") {
        exclude(group = "org.eclipse.jetty")
        exclude(group = "org.eclipse.jetty.websocket")
        exclude(group = "com.fasterxml.jackson.core")
    }
```

Then add the following class to your project:
```java
@WebServlet(name = "MyJavalinServlet", urlPatterns = {"/rest/*"})
public class MyJavalinServlet extends HttpServlet {
    private final JavalinServlet javalin = Javalin.createStandalone()
            .get("/rest", ctx -> ctx.result("Hello!"))
            .javalinServlet();

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        javalin.service(req, resp);
    }
}
```

Your servlet container will automatically discover the servlet and initialize it properly. To test, you can run

```bash
$ curl -v localhost:8080/rest
```

Testing: follow this example, to only initialize the REST servlet (no need to initialize the Vaadin servlet as well):
```kotlin
class MyJavalinServletTest {
    private var server: Server? = null

    @BeforeEach
    fun startJetty() {
        val ctx = WebAppContext()
        ctx.baseResource = EmptyResource.INSTANCE
        ctx.addServlet(MyJavalinServlet::class.java, "/rest/*")
        server = Server(30123)
        server!!.handler = ctx
        server!!.start()
    }

    @AfterEach
    fun stopJetty() {
        server?.stop()
    }

    @Test
    fun testRest() {
        assertEquals("Hello!", URL("http://localhost:30123/rest").readText())
    }
}
```

Also see [Vaadin Boot: REST via Javalin](https://github.com/mvysny/vaadin-boot#rest-via-javalin).
