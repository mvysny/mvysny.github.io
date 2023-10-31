---
layout: post
title: HttpClient error checking
---

An example code to use the built-in JDK HttpClient directly, with a bit of Kotlin.

```kotlin
/**
 * Documents a HTTP failure.
 * @property statusCode the HTTP status code, one of [jakarta.servlet.http.HttpServletResponse] `SC_*` constants.
 * @property method the request method, e.g. `"GET"`
 * @property requestUrl the URL requested from the server
 * @property response the response body received from the server, may provide further information to the nature of the failure.
 * May be blank.
 */
public class HttpResponseException(
    public val statusCode: Int,
    public val method: String,
    public val requestUrl: String,
    public val response: String,
    cause: Throwable? = null
) : IOException("$statusCode: $response", cause) {
    override fun toString(): String = "${javaClass.simpleName}: $message ($method $requestUrl)"
}

/**
 * Fails if the response is not in 200..299 range; otherwise returns [this].
 * @throws FileNotFoundException if the HTTP response was 404
 * @throws HttpResponseException if the response is not in 200..299 ([Response.isSuccessful] returns false)
 * @throws IOException on I/O error.
 */
public fun <T> HttpResponse<T>.checkOk(): HttpResponse<T> {
    if (!isSuccessful) {
        val response = bodyAsString()
        if (statusCode() == 404) throw FileNotFoundException("${statusCode()}: $response (${request().method()} ${request().uri()})")
        throw HttpResponseException(statusCode(), request().method(), request().uri().toString(), response)
    }
    return this
}

/**
 * True if [HttpResponse.statusCode] is 200..299
 */
public val HttpResponse<*>.isSuccessful: Boolean get() = statusCode() in 200..299

/**
 * Returns the [HttpResponse.body] as [String].
 */
public fun HttpResponse<*>.bodyAsString(): String {
    return when (val body = body()) {
        is String -> body
        is ByteArray -> body.toString(Charsets.UTF_8)
        is InputStream -> body.buffered().reader().readText()
        is Reader -> body.buffered().readText()
        is CharArray -> body.concatToString()
        else -> body.toString()
    }
}

/**
 * Runs given [request] synchronously and then runs [responseBlock] with the response body.
 * Everything including the [HttpResponse.body] is properly closed afterward.
 *
 * The [responseBlock] is only called on HTTP 200..299 SUCCESS. [checkOk] is used, to check for
 * possible failure reported as HTTP status code, prior calling the block.
 * @param responseBlock runs on success. Takes a [HttpResponse] and produces the object of type [T].
 * You can use [json], [jsonArray] or other utility methods to convert JSON to a Java object.
 * @return whatever has been returned by [responseBlock]
 */
public fun <T> HttpClient.exec(request: HttpRequest, responseBlock: (HttpResponse<InputStream>) -> T): T {
    val result = send(request, HttpResponse.BodyHandlers.ofInputStream())
    return result.body().use {
        result.checkOk()
        responseBlock(result)
    }
}
```

Also add the [Apache URIBuilder Kotlin API](https://gitlab.com/mvysny/apache-uribuilder#kotlin-api). Now you can write:

```kotlin
val request = "http://localhost:8080/person".buildUrl().buildRequest()
val client = HttpClient()
val response = client.exec(request) { response -> response.bodyAsString() }
```
