---
layout: post
title: Vaadin 14 SessionInitListener
---

A quick tip on how to add a (Vaadin) session init listener: first,
create a `VaadinServiceInitListener` as documented at [VaadinServiceInitListener tutorial](https://vaadin.com/docs/v14/flow/advanced/tutorial-service-init-listener).

Afterwards, use this code to init the session:

```java
public class ApplicationServiceInitListener
        implements VaadinServiceInitListener {

    @Override
    public void serviceInit(ServiceInitEvent event) {
         // ...
        event.getSource().addSessionInitListener(e -> {
            // init the session: e.getSession()
        });
    }
}
```

A [bug report #417 to enhance the official docs](https://github.com/vaadin/docs/issues/417)
have been opened - please upvote.

## Init'ing the lower-level Servlet Session

Then you need `@WebListener`-annotated class implementing `HttpSessionListener`.

## Spring

Documented in [this StackOverflow answer](https://stackoverflow.com/a/60773432/377320).

Simply create a class `ApplicationServiceInitListener` as above, but don't
forget to annotate it with `@Component`.

Adding `@EventListener` on `SessionInitEvent` doesn't work, implementing
`ApplicationListener<SessionInitEvent>` doesn't work.

MAKE SURE to remove any stray `META-INF/services/com.vaadin.flow.server.VaadinServiceInitListener`
file, otherwise `serviceInit()` will be called but `SessionInitListener` WILL NOT.
