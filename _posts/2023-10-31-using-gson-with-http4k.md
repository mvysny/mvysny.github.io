---
layout: post
title: Using Gson with Http4k
---

An example code to use [Gson](https://github.com/google/gson) with [http4k](https://www.http4k.org).
See [beverage-buddy-jooq](https://github.com/mvysny/beverage-buddy-jooq) to see this code in action.

First, some basic utility methods for Gson:

```kotlin
/**
 * Parses [json] as a list of items with class [itemClass] and returns that.
 */
fun <T> Gson.fromJsonArray(json: String, itemClass: Class<T>): List<T> =
    fromJsonArray(StringReader(json), itemClass)

/**
 * Parses JSON from a [reader] as a list of items with class [itemClass] and returns that.
 */
fun <T> Gson.fromJsonArray(reader: Reader, itemClass: Class<T>): List<T> {
    val type: Type = TypeToken.getParameterized(List::class.java, itemClass).type
    return fromJson<List<T>>(reader, type)
}

/**
 * Parses the response as a JSON and converts it to a Java object.
 */
fun <T> Body.json(gson: Gson, clazz: Class<T>): T = gson.fromJson(stream.buffered().reader(), clazz)

/**
 * Parses the response as a JSON array and converts it into a list of Java object with given [clazz].
 */
fun <T> Body.jsonArray(gson: Gson, clazz: Class<T>): List<T> = gson.fromJsonArray(stream.buffered().reader(), clazz)

/**
 * Parses the response as a JSON array and converts it into a list of Java object with given [clazz].
 */
inline fun <reified T> Body.jsonArray(gson: Gson): List<T> = jsonArray(gson, T::class.java)
```

The client code:

```kotlin
private fun Response.checkOk(request: Request) {
    if (!status.successful) {
        val msg = "$request ====> $this"
        if (status.code == 404) throw FileNotFoundException(msg)
        throw IOException(msg)
    }
}

val CheckOk = Filter { next -> { next(it).apply { checkOk(it) } } }

fun Request.accept(contentType: ContentType): Request = header("Accept", contentType.toHeaderValue())

fun Request.acceptJson(): Request = accept(ContentType.APPLICATION_JSON)

class PersonRestClient {
  private val client: HttpHandler = ClientFilters.SetBaseUriFrom(Uri.of("http://localhost:8080/rest"))
    .then(ClientFilters.FollowRedirects())
    .then(CheckOk)
    .then(JavaHttpClient(responseBodyMode = BodyMode.Stream))
  private val gson = RestService.gson

  fun getAllCategories(): List<Category> {
    val request = Request(Method.GET, "categories").acceptJson()
    return client(request).use { response -> response.body.jsonArray<Category>(gson) }
  }
}
```

The server code:

```kotlin
object RestService {
    val gson: Gson = GsonBuilder().registerJavaTimeAdapters().create()
    private fun Response.json(json: Any): Response =
        header("Content-Type", ContentType.APPLICATION_JSON.toHeaderValue())
            .body(gson.toJson(json))

    val app: RoutingHttpHandler = routes(
        "categories" bind GET to { Response(OK).json(db { CATEGORY.dao.findAll() }) }
    ).withBasePath("rest")
}

/**
 * Provides access to person list. To test, just run `curl http://localhost:8080/rest/categories`
 */
@WebServlet(
    urlPatterns = ["/rest/*"],
    name = "RestServlet",
    asyncSupported = false
)
class RestServlet : HttpServlet() {
    private val adapter = Http4kJakartaServletAdapter(RestService.app)
    override fun service(req: HttpServletRequest, resp: HttpServletResponse) =
        adapter.handle(req, resp)
}

private fun GsonBuilder.registerJavaTimeAdapters(): GsonBuilder = apply {
    Converters.registerAll(this)
}
```
