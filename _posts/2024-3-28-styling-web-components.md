---
layout: post
title: Styling Web Components with Vaadin
---

Summarizing ways to style both Vaadin and non-Vaadin components here. Important: The `@CssImport` annotation
only works with web components implementing the `ThemableMixin` (so, in general, only with Vaadin components)
AND/OR web components correctly defining parts in their ShadowDOM.
`@CssImport` **can not** be used with other web components - it will simply get ignored and will do nothing.

## Vaadin 23 and lower

In order to style the components, you need to "pierce the ShadowDOM veil" and inject
CSS into the ShadowDOM of the component, otherwise things won't work. The following ways are only possible
for Vaadin components (or for components implementing the `ThemableMixin`):

* The best way is to create a theme for your app and place the css into the `components/` folder.
  For example if you're styling `vaadin-button` then place `vaadin-button.css` into `components/` folder
  and Vaadin theming engine will automatically inject that CSS into Button's ShadowDOM.
  See [Creating Custom Themes](https://vaadin.com/docs/v23/styling/custom-theme/creating-custom-theme) for more details.
* Alternatively add `@CssImport(value = "./css/foo.css", themeFor = "vaadin-button")` into a `@Route`-annotated class in your project.

## Non-Vaadin components

For other web components (web components not implementing `ThemableMixin` mixin), you can use tricks mentioned at [Vaadin Docs #790](https://github.com/vaadin/docs/issues/790).
For example you can simply inject new `<style>` element into shadow-dom from Java as follows:
```java
calendar.getElement().executeJs("var s = document.createElement(\"style\"); s.textContent = $0; this.shadowRoot.appendChild(s);", ".fc-timegrid-slots { background: red }");
```
Alternatively, extend the class in javascript and add the styles manually, as described at https://vaadin.com/directory/component/full-calendar-flow/samples , the "using a custom class" example.

## Vaadin 24

Vaadin 24 changed the way ShadowDOM is pierced. It now uses direct support of CSS for styling parts via
`::part(input-field)`, see [Styling Components](https://vaadin.com/docs/latest/styling/styling-components).
This should work with all web components that contain elements with `part="xyz"` attributes in their ShadowDOM;
then you can target those via

```css
vaadin-button::parts(xyz) {
  background: red;
}
```

There's no need to include such CSS in a special way - you can add rules directly to your `my-theme/styles.css`
file, or even to `@CssImport("./foo.css")` if you're not using Application Themes.
This will work regardless of whether the web component implements the `ThemableMixin` or not.

If the web component doesn't implement the `ThemableMixin` AND it does not define parts (this is the case for example for the
[Google Map Addon](https://github.com/FlowingCode/GoogleMapsAddon)), the only way is to use workarounds
mentioned above in the "Non-Vaadin components" chapter - e.g. the `<style>` injection.
