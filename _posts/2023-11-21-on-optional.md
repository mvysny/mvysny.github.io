---
layout: post
title: On Java Optional
---

As Brian Goetz [mentioned](https://youtu.be/MFzlgAuanU0):
Optional is intended to provide a *limited* mechanism for library method *return* types
where there is a clear need to represent "no result," and where using `null` for
that is *overwhelmingly* likely to cause errors.

## Optional creates spaghetti code

[See this StackOverflow message](https://stackoverflow.com/a/34458582/377320):

```java
// BAD
String process(String s) {
    return Optional.ofNullable(s).orElseGet(this::getDefault);
}

// GOOD
String process(String s) {
    return (s != null) ? s : getDefault();
}
```

The method that uses Optional is longer, and most people find it more obscure than the conventional code. Not only that, it creates extra garbage for no good reason.

## Java Bean Property Breakage

Additional problems with Optional: It makes the Java Bean property read-only. I failed to find the rule
in the [Java Bean Specification](https://download.oracle.com/otndocs/jcp/7224-javabeans-1.01-fr-spec-oth-JSpec/) which states
that both the getter and the setter must have the same type for the parameter; however using `Optional` for getter makes
the property read-only:

```java
public final class Main {
    public static void main(@NotNull String[] args) throws Exception {
        for (PropertyDescriptor propertyDescriptor : Introspector.getBeanInfo(Main.class).getPropertyDescriptors()) {
            System.out.println(propertyDescriptor);
        }
    }
    public Optional<String> getFoo() {
        return null;
    }

    public void setFoo(String foo) {
    }
}
```

prints

```
java.beans.PropertyDescriptor[name=foo; values={expert=false; visualUpdate=false; hidden=false;
  enumerationValues=[Ljava.lang.Object;@60c6f5b; required=false};
  propertyType=class java.lang.String;
  readMethod=public java.lang.String com.vaadin.starter.skeleton.Main.getFoo();
  writeMethod=public void com.vaadin.starter.skeleton.Main.setFoo(java.lang.String)]
```

while

```java
public final class Main {
    public static void main(@NotNull String[] args) throws Exception {
        for (PropertyDescriptor propertyDescriptor : Introspector.getBeanInfo(Main.class).getPropertyDescriptors()) {
            System.out.println(propertyDescriptor);
        }
    }
    public Optional<String> getFoo() {
        return null;
    }

    public void setFoo(String foo) {
    }
}
```

prints

```
java.beans.PropertyDescriptor[name=foo; values={expert=false; visualUpdate=false; hidden=false;
  enumerationValues=[Ljava.lang.Object;@60c6f5b; required=false};
  propertyType=class java.util.Optional;
  readMethod=public java.util.Optional com.vaadin.starter.skeleton.Main.getFoo()]
```

## Conclusion

I personally think Kotlin nullability feature is vastly better and produces more readable code
than any usage of Optional - another case where the lack of language features causes broken-by-design
API to appear, causing the library landscape to suffer. Given the reasons
above I prefer to use the `@Nullable` annotation instead. `@Nullable` annotation causes
your IDE to warn you if you don't check for null, fixing the "*overwhelmingly* likely to cause errors"
part of Brian Goetz quote.

Optional may make sense in some highly specific scenario, e.g. when using [RxJava](https://github.com/ReactiveX/RxJava),
but in all other scenarios it produces ugly hard-to-read code and should be avoided.

Just because you can do something doesn't mean that you should do it.
