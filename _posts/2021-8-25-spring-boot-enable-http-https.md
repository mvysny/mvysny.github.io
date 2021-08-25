---
layout: post
title: Enable both http and https on Spring Boot
---

Building on [How to Enable HTTP and HTTPS in Spring Boot](https://www.javadevjournal.com/spring-boot/how-to-enable-http-https-in-spring-boot/)
which is a bit outdated nowadays.

To enable support for HTTP and HTTPS in Spring Boot 2, we need to register an additional connector with Spring Boot application.

First, enable SSL/HTTPS for Spring Boot, for example by following the [HTTPS using Self-Signed Certificate in Spring Boot](https://www.baeldung.com/spring-boot-https-self-signed-certificate)
tutorial.

Now, add `server.http.port=8080` to `application.properties`.

To add another Tomcat connector, create the following configuration class:

```java
@Configuration
public class AppConfiguration {
    @Bean
    public WebServerFactoryCustomizer<TomcatServletWebServerFactory> cookieProcessorCustomizer() {
        return (TomcatServletWebServerFactory factory) -> {
            // also listen on http
            final Connector connector = new Connector();
            connector.setPort(httpPort);
            factory.addAdditionalTomcatConnectors(connector);
        };
    }

    @Value("${server.http.port}")
    private int httpPort;
}
```
