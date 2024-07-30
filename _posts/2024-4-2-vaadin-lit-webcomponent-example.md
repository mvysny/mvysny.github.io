---
layout: post
title: Vaadin - Lit WebComponent example
---

The [Vaadin Documentation on In-Project Web Component](https://vaadin.com/docs/latest/create-ui/web-components/an-in-project-web-component)
is rather outdated, so here's a more up-to-date example. Also don't forget to consult [Lit Documentation](https://lit.dev/docs/)
whenever needed.

`frontend/src/my-component.ts`:
```typescript
import {css, html, LitElement} from 'lit';
import {customElement, property} from 'lit/decorators.js';

@customElement("my-component")
class MyComponent extends LitElement {
	@property() atTime: string = "0 : 00";
	@property() atDate: string = "8th Feb 2024";

	static styles = css`
		.timer-card {
			flex: 1 1 100%;
			align-items: center;
			justify-content: center;
			padding: 15px 15px 14px 16px;
			border-radius: var(--lumo-border-radius-m);
			box-shadow: var(--lumo-box-shadow-xs);
			background: var(--lumo-tint);
			border: 1px solid var(--lumo-contrast-10pct);
		}
	`;

	render() {
		return html`
			<vaadin-horizontal-layout style="width: 100%" class="timer-card" theme="spacing">
				<span style="flex-grow: 1">Valid until</span>
				<span>${this.atTime}</span>
				<span>${this.atDate}</span>
			</vaadin-horizontal-layout>
		`;
	}
}
```

Java:
```java
import com.vaadin.flow.component.*;
import com.vaadin.flow.component.dependency.JsModule;
import com.vaadin.flow.component.littemplate.LitTemplate;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.FormatStyle;
import java.util.Locale;

@Tag("my-component")
@JsModule("./src/my-component.ts")
public class MyComponent extends LitTemplate implements HasSize {

	private static final PropertyDescriptor<String, String> AT_TIME = PropertyDescriptors.propertyWithDefault("atTime", "0 : 00");
	private static final PropertyDescriptor<String, String> AT_DATE = PropertyDescriptors.propertyWithDefault("atDate", "");

	public MyComponent() {
		setWidthFull();
	}

	public MyComponent(LocalDateTime atDateTime) {
		this();
		setDate(atDateTime);
	}

	public void setDate(LocalDateTime atDateTime) {
		final Locale locale = UI.getCurrent().getLocale();
		final DateTimeFormatter timeFormatter = DateTimeFormatter.ofPattern("H : mm", locale);
		AT_TIME.set(getElement(), timeFormatter.format(atDateTime));
		final DateTimeFormatter dateFormatter = DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM).withLocale(locale);
		AT_DATE.set(getElement(), dateFormatter.format(atDateTime));
	}
}
```

Additional tips:

* Read the [Vaadin Documentation on Element API](https://vaadin.com/docs/latest/create-ui/element-api) to learn the ways to communicate with the component and back.
* Note that [Lumo Style Properties](https://vaadin.com/docs/latest/styling/lumo/lumo-style-properties) are available from within the ShadowDOM
  of the component, as seen in the `.timer-card` CSS class definition.
* Read [Lit Documentation](https://lit.dev/docs/) on additional topics such as Lifecycle, properties, events etc.

## Troubleshooting

* The client-to-server RPC stops working: make sure your component is enabled and not covered by a modal dialog. See [Client-Server RPC](https://vaadin.com/docs/latest/create-ui/element-api/client-server-rpc)
  and the `@AllowInert` for more documentation.

## JavaScript instead of TypeScript

Here you go

`frontend/src/my-component.js`:
```javascript
import {css, html, LitElement} from 'lit';

class MyComponent extends LitElement {
    static get properties() {
        return {
            atTime: {type: String},
            atDate: {type: String},
        };
    }

    static styles = css`
		.timer-card {
			flex: 1 1 100%;
			align-items: center;
			justify-content: center;
			padding: 15px 15px 14px 16px;
			border-radius: var(--lumo-border-radius-m);
			box-shadow: var(--lumo-box-shadow-xs);
			background: var(--lumo-tint);
			border: 1px solid var(--lumo-contrast-10pct);
		}
	`;

    render() {
        return html`
			<vaadin-horizontal-layout style="width: 100%" class="timer-card" theme="spacing">
				<span style="flex-grow: 1">Valid until</span>
				<span>${this.atTime}</span>
				<span>${this.atDate}</span>
			</vaadin-horizontal-layout>
		`;
    }
}

customElements.define("my-component", MyComponent);
```
