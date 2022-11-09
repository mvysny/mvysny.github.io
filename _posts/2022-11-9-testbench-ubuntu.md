---
layout: post
title: Running Vaadin TestBench on Ubuntu
---

Running TestBench on Ubuntu is a nightmare. The ChromeDriver will block endlessly and won't work,
while FirefoxDriver will either segfault snap or fail with some other crazy error. On top of that,
Selenium has problems with Chromium and Firefox installed as snap. Fear not, there's a way.

Note that these instructions are working on Ubuntu 22.10, with JDK 11 and snap chromium 107.0.5304.87. These
instructions may not work in the future since the browser drivers tend to break with every browser release;
also the File hack may not work on JDK 17.

To run TestBench on Ubuntu with Chromium installed via `snap install chromium`:

1. `git clone https://github.com/vaadin/skeleton-starter-flow` and checkout the v23 branch
2. Forget Firefox (I wasn't able to get it running), go with Chromium.
3. Rewrite the `AbstractViewTest.java` as follows:

```java
public abstract class AbstractViewTest extends TestBenchTestCase {
    private static final int SERVER_PORT = 8080;

    private final String route;
    private final By rootSelector;

    @Rule
    public ScreenshotOnFailureRule rule = new ScreenshotOnFailureRule(this,
            false);

    public AbstractViewTest() {
        this("", By.tagName("body"));
    }

    protected AbstractViewTest(String route, By rootSelector) {
        this.route = route;
        this.rootSelector = rootSelector;
    }

    @Before
    public void setup() throws Exception {
        setDriver(TestBench.createDriver(new ChromeDriver(
                new ChromeDriverService.Builder() {
                    @Override
                    protected File findDefaultExecutable() {
                        if (new File("/snap/bin/chromium.chromedriver").exists()) {
                            return new File("/snap/bin/chromium.chromedriver") {
                                @Override
                                public String getCanonicalPath() {
                                    return this.getAbsolutePath();
                                }
                            };
                        } else {
                            return super.findDefaultExecutable();
                        }
                    }
                }.build())));
        getDriver().get(getURL(route));
    }

    @After
    public void stop() {
        getDriver().close();
    }

    protected void assertThemePresentOnElement(
            WebElement element, Class<? extends AbstractTheme> themeClass) {
        String themeName = themeClass.getSimpleName().toLowerCase();
        Boolean hasStyle = (Boolean) executeScript("" +
                "var styles = Array.from(arguments[0]._template.content" +
                ".querySelectorAll('style'))" +
                ".filter(style => style.textContent.indexOf('" +
                themeName + "') > -1);" +
                "return styles.length > 0;", element);

        Assert.assertTrue("Element '" + element.getTagName() + "' should have" +
                        " had theme '" + themeClass.getSimpleName() + "'.",
                hasStyle);
    }

    private static String getURL(String route) {
        return String.format("http://%s:%d/%s", "localhost",
                SERVER_PORT, route);
    }
}
```

Note the ugly ChromeDriver File hack. It has been reported to Selenium as [#10969](https://github.com/SeleniumHQ/selenium/issues/10969)
and [#7788](https://github.com/SeleniumHQ/selenium/issues/7788) and the workaround comes from there.

Now, run the app, e.g. via `mvn jetty:run`; then right-click `MainViewIT` and run it as a test suite.
You should hopefully see Chromium popping up, controlled by the ChromeDriver and the tests.
