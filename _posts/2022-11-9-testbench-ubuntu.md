---
layout: post
title: Running Vaadin TestBench or Selenium on Ubuntu
---

Running TestBench on Ubuntu is a nightmare. The ChromeDriver will block endlessly and won't work,
while FirefoxDriver will either segfault snap or fail with some other crazy error. On top of that,
Selenium has problems with Chromium and Firefox installed as snap.

Use [Playwright](https://playwright.dev/). It just works, even on Linux, both x86 and arm. It doesn't use the stupid driver architecture
but instead accesses the browser over a standardized [Firefox CDP](https://firefox-source-docs.mozilla.org/remote/cdp/)/[Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/). But if you can't
do that, read on.

## Ubuntu 25.04

`firefox` snap now comes with geckodriver which actually works! To test:

1. `sudo snap install firefox`
2. git clone skeleton-starter-flow-spring
3. Edit `AbstractViewTest` and make it extend `TestBenchTestCase`, to disable parallel runs
4. Modify `AbstractViewTest.setup()` as follows:

```java
class AbstractViewTest {
   @Before
   public void setup() throws Exception {
      System.setProperty("webdriver.gecko.driver", "/snap/bin/firefox.geckodriver");
      setDriver(TestBench.createDriver(new FirefoxDriver()));
      getDriver().get(getURL(route));
   }
}
```

Works on arm64 Ubuntu.

## Ubuntu 24.10

`chromium` snap now comes with `chromedriver` which actually works! To test:

1. `sudo snap install chromium`
2. git clone skeleton-starter-flow-spring
3. Edit `AbstractViewTest` and make it extend `TestBenchTestCase`, to disable parallel runs
4. Modify `AbstractViewTest.setup()` as follows:

```java
class AbstractViewTest {
   @Before
   public void setup() throws Exception {
      System.setProperty("webdriver.chrome.driver", "/snap/chromium/current/usr/lib/chromium-browser/chromedriver");
      setDriver(TestBench.createDriver(new ChromeDriver()));
      // Alternatives:
      // - specify the driver via ChromeDriverService
      // - start Chromium in headless mode
//      ChromeOptions chromeOptions = new ChromeOptions();
//      chromeOptions.addArguments("--headless", "--no-sandbox");
//      final ChromeDriverService service = new ChromeDriverService.Builder()
//              .usingDriverExecutable(new File("/snap/chromium/current/usr/lib/chromium-browser/chromedriver"))
//              .build();
//      setDriver(TestBench.createDriver(new ChromeDriver(service, chromeOptions)));
      getDriver().get(getURL(route));
   }
}
```

Works on arm64 Ubuntu.

## Ubuntu 23.10

ChromeDriver can't control Chromium - Chromium is launched but it just sits there with no
activity until finally Selenium times out with `org.openqa.selenium.SessionNotCreatedException: Could not start a new session. Response code 500. Message: session not created: DevToolsActivePort file doesn't exist`.
Reported as [Chromium Bug](https://issues.chromium.org/issues/335373503), please upvote.

1. Uninstall Chromium.
2. Use [Chrome for Testing](https://googlechromelabs.github.io/chrome-for-testing/#stable). Download both "chrome" and "chromedriver" - they should work well together.
3. According to [Testbench: installing WebDrivers](https://vaadin.com/docs/latest/testing/end-to-end/installing-webdrivers),
   either add Java system property `webdriver.chrome.driver` pointing to the `chromedriver` binary, or add the chromedriver binary to your `$PATH`.
4. Add Chrome binary to the `$PATH` as well.
5. Launch the tests, no other configuration necessary: now the chromedriver from PATH is launched, and it will launch chrome from the PATH.

## Ubuntu 22.04 arm64

EDIT: There's a way! Install [old arm64 Chromium debs using this tutorial](https://stackoverflow.com/questions/76857893/is-there-a-known-working-configuration-for-using-selenium-on-linux-arm64).
Then, create this class:

```java
public class MyTest extends AbstractBrowserDriverTestBase {
    @BeforeEach
    public void setupBrowser() {
        final ChromeOptions options = new ChromeOptions();
        options.addArguments("--headless", "--no-sandbox");
        final ChromeDriver driver = new ChromeDriver(options);
        setDriver(driver);
        getDriver().get("http://localhost:8080/");
    }

    @AfterEach
    public void shutdown() {
        getDriver().close();
    }

    @Test
    public void clickingButtonAddsParagraph() {
        Assertions.assertFalse($(ParagraphElement.class).exists());
        $(ButtonElement.class).first().click();
        Assertions.assertTrue($(ParagraphElement.class).exists());
    }
}
```

### Old shit for reference

Unfortunately, Chrome for Testing isn't available for linux-arm64. I've tried fiddling with [Parallels+Rosetta](https://kb.parallels.com/129871);
but even after I installed all dependencies chrome still failed with:
```
assertion failed [arm::is_brk_instruction(instruction)]: SIGTRAP from kernel was not from a BRK
(ThreadContextRuntimeSignals.cpp:371 translate_sigtrap)
 fish: Job 1, './chrome' terminated by signal SIGTRAP (Trace or breakpoint trap)
```

I've opened a [feature request](https://issues.chromium.org/issues/335383220), please upvote.

Downloading official [Chrome](https://www.google.com/chrome/) only yields amd64 deb package. It installs and draws a welcome window,
but then segfaults and that's it. Also, the deb package doesn't contain chromedriver.

## Ubuntu 23.04

This works on Ubuntu 23.10 with chromium 119 installed via snap:
```java
public abstract class AbstractViewTest extends TestBenchTestCase {
    @Before
    public void setup() throws Exception {
        System.setProperty("webdriver.chrome.driver", "/snap/bin/chromium.chromedriver");
        setDriver(new ChromeDriver());
    }

    @After
    public void stop() {
        getDriver().close();
    }
}
```

## Ubuntu 22.10

Note that these instructions are working on Ubuntu 22.10, with JDK 11 and snap chromium 107.0.5304.87. These
instructions may not work in the future since the browser drivers tend to break with every browser release;
also the File hack may not work on JDK 17.

To run TestBench on Ubuntu with Chromium installed via `snap install chromium`:

1. `git clone https://github.com/vaadin/skeleton-starter-flow` and checkout the v23 branch
2. Forget Firefox (I wasn't able to get it running), go with Chromium.
3. Rewrite the `AbstractViewTest.java` as follows:

```java
public abstract class AbstractViewTest extends TestBenchTestCase {

    private final String route;

    @Rule
    public ScreenshotOnFailureRule rule = new ScreenshotOnFailureRule(this,
            false);

    public AbstractViewTest() {
        this("");
    }

    protected AbstractViewTest(String route) {
        this.route = route;
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
        getDriver().get("http://localhost:8080/" + route);
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
}
```

Note the ugly ChromeDriver File hack. It has been reported to Selenium as [#10969](https://github.com/SeleniumHQ/selenium/issues/10969)
and [#7788](https://github.com/SeleniumHQ/selenium/issues/7788) and the workaround comes from there.

Now, run the app, e.g. via `mvn jetty:run`; then right-click `MainViewIT` and run it as a test suite.
You should hopefully see Chromium popping up, controlled by the ChromeDriver and the tests.
