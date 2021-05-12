---
layout: post
title: Vaadin 14 + Spring request-scoped transactions
---

Simply create the following Servlet Filter which will start the transaction
and will commit/rollback after the request has been handled:

```java
@Component
public class TransactionalFilter implements Filter {
    private TransactionTemplate transactionTemplate;

    public void destroy() {
    }

    public void doFilter(final ServletRequest req, final ServletResponse resp, final FilterChain chain) throws ServletException, IOException {
        transactionTemplate.execute(status -> {
            try {
                chain.doFilter(req, resp);
            } catch (IOException | ServletException e) {
                throw new RuntimeException(e);
            }
            return null;
        });
    }

    public void init(FilterConfig config) throws ServletException {
        transactionTemplate = new TransactionTemplate(WebApplicationContextUtils.getRequiredWebApplicationContext(config.getServletContext()).getBean(PlatformTransactionManager.class));
    }
}
```

(the idea taken from [Stack Overflow](https://stackoverflow.com/questions/10888861/transaction-with-request-scope-with-mybatis-and-spring)).

However, the problem is that Vaadin will catch exceptions thrown by the event handlers
and will process them internally, and will not rethrow the exception upwards. That means
that the `doFilter()` method will complete successfully, causing the transaction to be
committed instead of rolled back.

You can find the `try{}catch` culprit block in `ServerRpcHandler:415` class, the `handleInvocationData()` method.

One solution is to tell Vaadin to re-throw the exception in the `ErrorHandler`:

```java
@Component
public class MyServiceInitListener implements VaadinServiceInitListener {
    @Override
    public void serviceInit(ServiceInitEvent event) {
        event.getSource().addSessionInitListener(e -> {
            e.getSession().setErrorHandler(new ErrorHandler() {
                @Override
                public void error(ErrorEvent event) {
                    throw new RuntimeException(event.getThrowable());
                }
            });
        });
    }
}
```

> Note: See [Vaadin 14+ Error Handling](../vaadin-error-handling/)
for more details.
