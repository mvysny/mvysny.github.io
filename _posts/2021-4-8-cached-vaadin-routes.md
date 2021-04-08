---
layout: post
title: Cached Vaadin Routes
---

If you need to preserve the state of certain route during the duration of
user's session (e.g. to preserve a half-filled form so that the user can
return to the form and fill it afterwards, or to create a multi-route wizard with
a back+forward navigation), you may use the following code to cache the route components
in your session:

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
                view.getElement().removeFromTree();
                return ((T) view);
            }
            return super.createRouteTarget(routeTargetType, event);
        }
    }

    public static class RouteSessionCache implements Serializable {
        private final Map<Class<?>, Serializable> routeCache = new HashMap<>();
        public static <T> T getOrCreate(Class<T> clazz) {
            RouteSessionCache cache = VaadinSession.getCurrent().getAttribute(RouteSessionCache.class);
            if (cache == null) {
                cache = new RouteSessionCache();
                VaadinSession.getCurrent().setAttribute(RouteSessionCache.class, cache);
            }
            final Serializable instance = cache.routeCache.computeIfAbsent(clazz, (c) -> ((Serializable) ReflectTools.createInstance(clazz)));
            return clazz.cast(instance);
        }
    }
}
```

The custom `MyServlet` and custom `VaadinServletService` is there only because it's
impossible to customize Vaadin's `DefaultInstantiator`, see+vote [Vaadin Flow #8427](https://github.com/vaadin/flow/issues/8427)
for more details. If you're using Vaadin 14.6+, you will be able to customize the
`InstantiatorFactory` in order to produce `MyInstantiator`; you will no longer need
to create a custom `MyServlet`.
