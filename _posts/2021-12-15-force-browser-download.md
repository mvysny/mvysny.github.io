---
layout: post
title: Force the browser to download the content
---

The best way to achieve that is to use the Vaadin `Anchor` component, setting `href` to
appropriate `StreamResource`. That way, the browser will correctly open the download dialog by default,
working as expected. Tags: `FileDownloader`.

If you want to have a download icon, you can simply add the `Icon` component into `Anchor` like follows:

```java
Anchor a = new Anchor(...);
a.add(new Icon(VaadinIcon.ABACUS));
```

This may not work with the Vaadin Button though, since the button may steal clicks.

## Programmatic Downloads

You can try to call [window.open](https://developer.mozilla.org/en-US/docs/Web/API/Window/open) as follows, on button click, to open the download in a new popup:
```java
button.getElement().executeJs("window.open($0)", registration.getResourceUri().toString()));
```

Note that Firefox will block the popup by default - you will need to
tell the user to disable popup blocking for your site.

On top of that, unfortunately it's not possible to tell [window.open](https://developer.mozilla.org/en-US/docs/Web/API/Window/open) to
force-download the target content:

* using `window.location.href = [url]` instead of `window.open` might seem to be working (it works for PDF and CSV files), but
  HTML and JSON files are still displayed inline in the browser, rather than being downloaded.
* The same by setting target to `_parent`.

The only way is to set the [Content-Disposition HTTP header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition) header
to `attachment`.

This feature has been added to Vaadin 22 and Vaadin 14.8+, see [flow #5471](https://github.com/vaadin/flow/issues/5471) for more details.

Example code:

```java
@Route("")
public class MainView extends VerticalLayout {

    public static class DownloadOnClickExtension implements Serializable {

        private StreamRegistration registration;

        public DownloadOnClickExtension(Button button) {
            button.addAttachListener(e -> registerResource());
            if (button.isAttached()) { registerResource(); }
            button.addDetachListener(e -> {
                registration.unregister();
                registration = null;
            });
            button.addClickListener(e ->
                    button.getElement().executeJs("window.location.href = $0", registration.getResourceUri().toString()));
        }

        private void registerResource() {
            final StreamResource resource = new StreamResource("hello.txt",
                    (InputStreamFactory) () -> new ByteArrayInputStream("Hello, world".getBytes(StandardCharsets.UTF_8)));
            resource.setHeader("Content-Disposition", "attachment");
            registration = VaadinSession.getCurrent().getResourceRegistry().registerResource(resource);
        }
    }

    public MainView() {
        final Button button = new Button("Download file");
        new DownloadOnClickExtension(button);
        add(button);
    }
}
```
