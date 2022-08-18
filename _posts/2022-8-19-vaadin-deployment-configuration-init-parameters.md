---
layout: post
title: Vaadin DeploymentConfiguration Servlet Init Parameters
---

The [official Vaadin documentation on configuration properties](https://vaadin.com/docs/latest/configuration/properties)
is quite well hidden, therefore I'll repost it here.
In order to change `DeploymentConfiguration` properties, pass them as a servlet init parameter.
Simply define your own servlet which extends VaadinServlet:

```java
@WebServlet(urlPatterns = "/*", name = "myservlet", asyncSupported = true, initParams = {@WebInitParam(name = InitParameters.SERVLET_PARAMETER_CLOSE_IDLE_SESSIONS, value = "true")})
public class MyServlet extends VaadinServlet {
}
```

To check whether the configuration was applied, call the following e.g. from your main route:
```java
@Route("")
public class MainView extends VerticalLayout {

    public MainView() {
        System.out.println(VaadinServlet.getCurrent()); // to verify that the servlet class is MyServlet
        System.out.println(VaadinService.getCurrent().getDeploymentConfiguration().isCloseIdleSessions()); // should print "true"
    }
}
```
