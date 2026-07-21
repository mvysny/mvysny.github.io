---
layout: post
title: Vaadin - Getting Browser Time Zone
---

The easiest way is to use [karibu-tools built-in support](https://github.com/mvysny/karibu-tools?tab=readme-ov-file#time-zone)
but that requires Kotlin. Here's the Java class (quick'n'dirty, no javadoc):

```java
public final class BrowserTimeZone {
	/**
	 * Returns the current {@link ExtendedClientDetails}, which is stored in the current session.
	 * You need to populate this field first, by using {@link #fetch()},
	 * otherwise this will return null.
	 */
	public static ExtendedClientDetails getExtendedClientDetails() {
		return VaadinSession.getCurrent().getAttribute(ExtendedClientDetails.class);
	}

	public static void setExtendedClientDetails(ExtendedClientDetails extendedClientDetails) {
		VaadinSession.getCurrent().setAttribute(ExtendedClientDetails.class, extendedClientDetails);
	}

    /**
     * Call this from the UI Init Listener.
     */
	public static void fetch() {
		if (getExtendedClientDetails() == null) {
			UI.getCurrent().getPage().retrieveExtendedClientDetails(BrowserTimeZone::setExtendedClientDetails);
		}
	}

	public static ZoneId get() {
		final ExtendedClientDetails details = getExtendedClientDetails();
		if (details != null) {
			if (details.getTimeZoneId() != null && !details.getTimeZoneId().isBlank()) {
				// take into account zone ID. This is important for historical dates, to properly compute date with daylight savings.
				return ZoneId.of(details.getTimeZoneId());
			} else {
				// fallback to time zone offset
				return ZoneOffset.ofTotalSeconds(details.getTimezoneOffset() / 1000);
			}
		}
		return ZoneOffset.UTC;
	}

	public static LocalDateTime toLocalDateTime(Instant instant) {
		return instant == null ? null : instant.atZone(get()).toLocalDateTime();
	}
}
```
