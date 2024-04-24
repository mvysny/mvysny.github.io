---
layout: post
title: Vaadin - UI Unit Tests - Enable Production Mode
---

If you're using one of the Vaadin Paid components (e.g. [Components marked with $](https://vaadin.com/docs/latest/components)
or [Classic Components](https://vaadin.com/classic-components) and you want to run UI tests in your CI/CD env,
the server offline license won't work unless you enable Vaadin production mode. Luckily it's easy.

All that's needed is to enable the production mode via system property, then assert that it has indeed been enabled:

```java
public abstract class AbstractVaadinTest {
    @BeforeEach
    public void mockVaadin() {
        System.setProperty("vaadin.productionMode", "true");
        MockVaadin.setup();
        Assertions.assertTrue(VaadinService.getCurrent().getDeploymentConfiguration().isProductionMode());
    }
}
```
