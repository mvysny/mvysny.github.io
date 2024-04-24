---
layout: post
title: Vaadin - Server Offline License with Github Actions
---

If you're using one of the Vaadin Paid components (e.g. [Components marked with $](https://vaadin.com/docs/latest/components)
or [Classic Components](https://vaadin.com/classic-components) and you want to run UI tests in your CI/CD env,
you need to pass the [Vaadin server license key](https://vaadin.com/docs/latest/configuration/licenses#server-license-key) to
the build JVM. The easiest way is to use the `VAADIN_OFFLINE_KEY` environment variable.

First, obtain the "Server license key" from your [Vaadin Account](https://vaadin.com/myaccount/licenses).
Clicking the "Download" button downloads file named `offlineKey` which is about 2kb long and contains
the key itself.

Second, go to your GitHub project home page, then click "Settings". In "Security" there's "Secrets and variables"; click the "Actions" link
within. In the secrets tab, click "New repository secret" and add a secret. The name can be anything, let's go with `VAADINOFFLINEKEY`;
paste the Vaadin server license key into the "Secret" field.

Third, you need to create the environment variable in your build, populated by the contents of this secret.
Go to your project `.github/workflows/` folder and add the environment variable to one of the steps.
Here's an example yml file which builds your project via Gradle:
```yaml
name: Gradle

on: [push, pull_request]

jobs:
  build:

    strategy:
      matrix:
        os: [ubuntu-latest]
        java: [11]

    runs-on: $\{{ matrix.os }}

    steps:
    - uses: actions/checkout@v3
    - name: Set up JDK $\{{ matrix.java }}
      uses: actions/setup-java@v3
      with:
        java-version: $\{{ matrix.java }}
        distribution: 'temurin'
    - name: Cache Gradle packages
      uses: actions/cache@v2
      with:
        path: |
          ~/.gradle/caches
          ~/.gradle/wrapper
        key: $\{{ runner.os }}-gradle-$\{{ hashFiles('**/*.gradle.kts', 'gradle/wrapper/gradle-wrapper.properties', 'gradle.properties') }}
    - name: Build with Gradle
      env:
        VAADIN_OFFLINE_KEY: $\{{ secrets.VAADINOFFLINEKEY }}
      run: ./gradlew clean build '-Pvaadin.productionMode' --stacktrace --info --no-daemon
```

Fourth step: if you're running UI unit tests (which you should), you need to enable production mode for the tests, otherwise
the server license key will be ignored and your build will fail with:
```
com.vaadin.pro.licensechecker.LicenseException: The provided offline key does not allow development, please go to https://vaadin.com/pro/validate-license?getOfflineKey=mid-0e7a833e-6b542b5b to retrieve an offline key.
        For CI/CD build servers, you need to download a server license key, which can work offline to create production builds. You can download a server license key from https://vaadin.com/myaccount/licenses.
        For troubleshooting steps, see https://vaadin.com/licensing-faq-and-troubleshooting.
            at app//com.vaadin.pro.licensechecker.OfflineKeyValidator.validate(OfflineKeyValidator.java:110)
            at app//com.vaadin.pro.licensechecker.LicenseChecker.checkLicense(LicenseChecker.java:360)
```
See [Vaadin UI Unit Test: Production Mode](../vaadin-uiunittest-production-mode/) for more details.
