---
layout: post
title: Vaadin + Localization/Internationalization (l10n/i18n)
---

The `I18nProvider` class handles the duty of performing localization in Vaadin apps.
You can invoke it either directly via `VaadinService.getCurrent().getInstantiator().getI18NProvider().getTranslation("key", UI.getCurrent().getLocale());`
or via `Component.getTranslation()`. The latter is much shorter, but you may not have a component
always around to perform the translation. Therefore, I recommend to create a simple class

```java
public class Tr {
    public static String tr(String key, Object... params) {
        return VaadinService.getCurrent().getInstantiator().getI18NProvider().getTranslation(key, UI.getCurrent().getLocale(), params);
    }
}
```

Then you can static-import the `tr()` function everywhere and use it from anywhere:

```java
import static com.example.Tr.tr;

public class MyForm extends FormLayout {
    public MyForm() {
        TextField nameField = new TextField(tr("person.name"));
        // ...
    }
}
```

## Default I18nProvider?

There is no default `I18nProvider` implementation. You can check out
[Vaadin documentation in Localization](https://vaadin.com/docs/v14/flow/advanced/tutorial-i18n-localization)
on how to create a simple `ResourceBundle`-backed I18nProvider, or simply read on.

For non-Spring projects, Vaadin recommends to register your I18nProvider via a system property or web init param.
It looks funny but it works; I recommend this approach of having `ApplicationServlet` as shown in the Vaadin tutorial above.
Alternatively you can define [your own Instantiator](../vaadin-custom-instantiator/),
override `Instantiator.getI18nProvider()` and provide a singleton instance of your I18nProvider.

With Spring, you can annotate your `I18nProvider`-implementing class with `@Service` and Vaadin-Spring integration should pick it up
automatically.

## Resource Bundle

The best way to localize in Java is to use the mechanism of Resource Bundles. It is widely
supported by IDEs, used by default in Java world, has no significant shortcomings, and therefore
I recommended this way.

In order to use Resource Bundles with Vaadin, you'll need to define the following i18n provider:

```java
public class TranslationProvider implements I18NProvider {

    private static final String BUNDLE_PREFIX = "translate";

    private static final List<Locale> locales = Collections
            .unmodifiableList(Arrays.asList(new Locale("en", "GB"), new Locale("fi", "FI")));

    @Override
    public List<Locale> getProvidedLocales() {
        return locales;
    }

    @Override
    public String getTranslation(String key, Locale locale, Object... params) {
        Objects.requireNonNull(key);
        Objects.requireNonNull(locale);

        final ResourceBundle bundle = ResourceBundle.getBundle(BUNDLE_PREFIX, locale);

        String value;
        try {
            value = bundle.getString(key);
        } catch (final MissingResourceException e) {
            log.warn("Missing resource", e);
            return "!" + locale.getLanguage() + ": " + key;
        }
        if (params.length > 0) {
            value = MessageFormat.format(value, params);
        }
        return value;
    }

    private static final Logger log = LoggerFactory.getLogger(TranslationProvider.class);
}
```

In the `getProvidedLocales()` you should return all locales for which you define resource bundles.
Vaadin will then match the language list coming from the browser in the http request to this list,
it will pick a match and will set it to the VaadinSession and all UIs. If no match
is found, first locale is selected. Therefore:

* Pick one locale that will be the primary one, usually it's English. This will be a fallback locale:
  if a match can not be found, the default is returned.
* Return the primary locale as first item in the `getProvidedLocales()` list
* Create the default resource bundle (the bundle with no language/country selectors) and populate
  it with strings for this language.

In this example there are two locales: English and Finnish. If the browser requests Finnish,
then Finnish resource bundle will be selected, otherwise English resource bundle will be selected.

You should then create two resource bundles in `src/main/resources/`:

* `translate.properties` for English locale, with the content `Hi=Hello, {0}!`
* `translate_fi.properties` for Finnish locale, with the content `Hi=Moi, {0}!`

Note the `{0}` string - that's what `MessageFormat` class uses to format String with parameters. See
the `MessageFormat` class javadoc for more info on how to use additional formatting.

Now you are able to call `tr("Hi", "Martin")` from anywhere in your code, to obtain the translation e.g. `Hello, Martin!`.

## Changing Language On-The-Fly

Say that you want to have a ComboBox language selector with the languages placed somewhere within the navigation bar of
your application. If the user changed the language,
then you'd like to immediately change all texts in all Vaadin components to the new language.
You may be tempted to have all
components implement the `LocaleChangeObserver` interface to change their labels,
then simply call `VaadinSession.getCurrent().setLocale(locale)`.

**Don't.**

There is no good solution for this. Let's explore two solutions.

Say you want to have a Button which changes its text automatically based on locale change.
You would create a class `I18nButton` as follows:

```java
public class I18nButton extends Button implements LocaleChangeObserver {
    private final String i18nkey;

    public I18nButton(String i18nkey) {
        this(i18nkey, null);
    }

    public I18nButton(String i18nkey, Component icon) {
        this.i18nkey = Objects.requireNonNull(i18nkey);
        setIcon(icon);
        updateText();
    }

    private void updateText() {
        setText(getTranslation(i18nkey));
    }


    @Override
    public void localeChange(LocaleChangeEvent event) {
        updateText();
    }
}
```

There are the following shortcomings:

1. What if someone calls `setText()` on this button - should it interpret the String literally as untranslated text
   (and overwriting it on next locale change), or should it set the String as key to `i18nkey`, thus changing
   the semantics of `setText()`? Neither is perfect.
2. What if we need parameters? We can modify `Tr` to carry key+parameters and rewrite I18nButton to use `Tr` instead of `String i18nkey`.

```java
public class Tr implements Serializable {
    private final String key;
    private final Object[] params;

    public Tr(String key, Object... params) {
        this.key = key;
        this.params = params;
    }
    public Tr(String key) { this(key, (Object[]) null); }

    public String get() { return tr(key, params); }

    public static String tr(String key, Object... params) {
        return VaadinService.getCurrent().getInstantiator().getI18NProvider().getTranslation(key, UI.getCurrent().getLocale(), params);
    }
}
```

The usage would then be `new I18nButton(new Tr("Hi", "Martin"))`. That could work.

What if we also need to localize placeholders for fields, LabelProviders for ComboBoxes etc?
We would have to introduce `I18nTextField` which remembers `Tr` not only for label, but also
for placeholder.

Furthermore, shall we
also define `I18nTextField`, `I18nComboBox` and `I18n*` class for every Vaadin component and use those
instead of vanilla Vaadin component? That is certainly a lot of work, not to mention that 
this solution feels weird to any new developer joining the project -
you have to remember to always use a non-standard `I18nTextField` component instead of the
original counterpart `TextField`. Any extending classes will need to have the `I18n*` counterparts too:
say you have `MyTextField` which extends `TextField` then you need to define `I18nMyTextField` and repeat the i18n
machinery there.

You may be tempted to solve the repetition problem by introducing a set of mixin interfaces,
say `HasI18nText` which would extend `LocaleChangeObserver`
and would be implemented by all components, but that solution is just horrible:

* It's very complex to understand;
* You'll need to implement get/set for `tr` in every component
* Mixin interface won't add constructor parameters
* You'll still need to define the `I18n*` class hierarchy anyway

### Alternative: Traverse Components Yourself

Alternatively you could remember the i18nkey for component's placeholder/label/texts in component data (`ComponentUtil.getData()`),
then have one locale observer which would traverse all components on locale change and would apply the new placeholders/labels/texts
to the components. This certainly removes the need of having a parallel set of `I18n*` classes.

Technical problem: UI doesn't allow you to add a locale change listener to it, but that could be solved
by having a custom implementation of the UI, or making the root layout component `LocaleChangeObserver`,
or the `LanguageComboBox` can do it itself.

How would such an API look like? You could have a function, say `Tr.setLabel(textField, "key.name")` which
would handle the abovementioned stuff. The problem is that IDE would not auto-complete this function in a `TextField`
since Java lacks the extension function language feature. You would also have to remember to not to use `textField.setLabel()`
itself but use some funny API `Tr.setLabel()`, which is just weird and hard for any newcomers.

## The Best Solution

The best & simplest solution is to reload the page on language change, then re-create all components and
set their labels via `textField.setLabel(tr("key.name"))`. You only need to remember one rule: to always
call the `tr()` function, and that's really easy to remember.

What if you're using `@PreserveOnRefresh` or [cached routes](../cached-vaadin-routes/)? You can
make `LanguageComboBox` clear the view cache on language change then reload the page, which is perfectly acceptable -
the language doesn't change often after all. In case of `@PreserveOnRefresh` there's no simple solution -
even if you navigate to other view, the root layout may not be changed. You may need a combination
of navigation + page reload; or you can clear the session and log out the user.

The simplest solution is to have the user to pick the language on login, then disallow
any language change. Again - the language is frequently only changed once on login to the user's native
language, then not changed afterwards.
