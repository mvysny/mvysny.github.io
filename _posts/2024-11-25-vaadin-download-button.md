---
layout: post
title: Vaadin Download Button
---

Creating a download button in Vaadin 23+ is very easy. First, let's create a
`DownloadButton` class:

```java
public class DownloadButton extends Button {
    private final StreamResource resource;
    private StreamRegistration streamRegistration;

    public DownloadButton(StreamResource resource) {
        super("Download");
        this.resource = Objects.requireNonNull(resource);
        addClickListener(event -> UI.getCurrent().getPage().open(streamRegistration.getResourceUri().toString(), "_blank"));
    }

    @Override
    protected void onAttach(AttachEvent attachEvent) {
        super.onAttach(attachEvent);
        streamRegistration = VaadinSession.getCurrent().getResourceRegistry().registerResource(resource);
    }

    @Override
    protected void onDetach(DetachEvent detachEvent) {
        streamRegistration.unregister();
        streamRegistration = null;
        super.onDetach(detachEvent);
    }
}
```

To use it:
```java
@Route("")
public class MainView extends VerticalLayout {
    public MainView() {
        add(new DownloadButton(new StreamResource("foo.txt", () -> new ByteArrayInputStream("Hello!".getBytes()))));
    }
}
```
