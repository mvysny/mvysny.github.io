---
layout: post
title: Vaadin 14+ Custom VaadinServlet and VaadinServletService
---

To extend the `VaadinService` class you need to override `VaadinServlet.createServletService()`
method which is done by introducing your own `VaadinServlet` into the app.
Your new servlet will automatically take precedence over the old `VaadinServlet`.

Just add this class to your project:
```java
@WebServlet(urlPatterns = "/*", asyncSupported = true)
public class MyServlet extends VaadinServlet {

  @Override
  protected VaadinServletService createServletService(DeploymentConfiguration deploymentConfiguration) throws ServiceException {
    VaadinServletService service = new VaadinServletService(this,
            deploymentConfiguration) {
      // your own stuff
    };
    service.init();
    return service;
  }
}
```

You can for example override `VaadinServletService.createInstantiator()` to provide your
own Instantiator as documented here: [Cached Vaadin Routes](../cached-vaadin-routes/).
However, for this particular case it's better to use `InstantiatorFactory` as documented
at [Vaadin: Custom Instantiator](../vaadin-custom-instantiator/).
