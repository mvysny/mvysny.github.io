---
layout: post
title: Cached Vaadin Routes
---

If you need to preserve the state of certain route during the duration of
user's session (e.g. to preserve a half-filled form so that the user can
return to the form and fill it afterwards, or to create a multi-route wizard with
a back+forward navigation), you may use the following code to cache the route components
in your session.

The trick here is to create a customized `Instantiator` which, instead of creating
new instances of routes, would store the instances into the session and reuse them
afterwards.

For Vaadin 14.5.x and lower, customizing `Instantiator` is a bit tricky,
see+vote [Vaadin Flow #8427](https://github.com/vaadin/flow/issues/8427)
for more details. The code looks like this:

```java

@WebServlet(urlPatterns = "/*", asyncSupported = true)
public class MyServlet extends VaadinServlet {

    @Override
    protected VaadinServletService createServletService(DeploymentConfiguration deploymentConfiguration) throws ServiceException {
        VaadinServletService service = new VaadinServletService(this,
                deploymentConfiguration) {
            @Override
            protected Instantiator createInstantiator() throws ServiceException {
                return new MyInstantiator(this);
            }
        };
        service.init();
        return service;
    }

    public static class MyInstantiator extends DefaultInstantiator {
        public MyInstantiator(VaadinService service) {
            super(service);
        }

        @Override
        public <T extends HasElement> T createRouteTarget(Class<T> routeTargetType, NavigationEvent event) {
            if (routeTargetType == MainView.class) {
                final MainView view = RouteSessionCache.getOrCreate(MainView.class);
                return ((T) view);
            }
            return super.createRouteTarget(routeTargetType, event);
        }
    }

    public static class RouteSessionCache implements Serializable {
        private final Map<Class<?>, Serializable> routeCache = new HashMap<>();

        public static <T extends HasElement> T getOrCreate(Class<T> clazz) {
            RouteSessionCache cache = VaadinSession.getCurrent().getAttribute(RouteSessionCache.class);
            if (cache == null) {
                cache = new RouteSessionCache();
                VaadinSession.getCurrent().setAttribute(RouteSessionCache.class, cache);
            }
            final Serializable instance = cache.routeCache.computeIfAbsent(clazz, (c) -> ((Serializable) ReflectTools.createInstance(clazz)));
            final T route = clazz.cast(instance);
            route.getElement().removeFromTree();
            return route;
        }
    }
}
```

For Vaadin 14.6+ you can simply provide your own implementation of
`InstantiatorFactory` in order to produce `MyInstantiator`; you will no longer need
to create a custom `MyServlet`.
