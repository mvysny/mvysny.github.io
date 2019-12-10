---
layout: post
title: WTF Spring
---

This post is not about how [Spring/Dependency Injection hurts ability to navigate and code readability](../2017-6-18-code-locality-and-ability-to-navigate/)
nor it's about [There's no place for Spring in post-annotation world](../2019-4-16-post-annotation-programming/).
This post is a rant.

So.

```java
    @Bean
    public ServletRegistrationBean<VaadinServlet> frontendServletBean() {
        ServletRegistrationBean<VaadinServlet> bean = new ServletRegistrationBean<>(new VaadinServlet(), "/VAADIN/*", "/frontend/*", "/icons/*");
        bean.setLoadOnStartup(1);
        return bean;
    }
```

This doesn't work, even though it's according to the Servlet spec. VaadinServlet
returns webcomponent.js as 200 OK, then Spring filters it out and returns 404 to
the browser which then won't initialize webcomponents and will render a completely non-functional web page.
 
This works:

```java
  @Bean
    public ServletRegistrationBean<VaadinServlet> frontendServletBean() {
        ServletRegistrationBean<VaadinServlet> bean = new ServletRegistrationBean<>(new VaadinServlet(), "/VAADIN/**", "/frontend/**", "/icons/**");
        bean.setLoadOnStartup(1);
        return bean;
    }
```

Spring even spits `Suspicious URL pattern: [/VAADIN/**] in context [], see sections 12.1 and 12.2 of the Servlet specification`
and then it works. It's as if Spring doesn't even have the decency to shit
in its mouth in a consistent manner....
 
I rate this three out of three facepalms.
