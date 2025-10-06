---
layout: post
title: Ubuntu local translation via LibreTranslate
---

The [LibreTranslate.com](https://libretranslate.com/) project is an open-source alternative
to Google Translate, which can be used both directly from the website, or from the
[Dialect](https://apps.gnome.org/Dialect/) app. But it gets even better: you can
run LibreTranslate easily on your local system.

Find the sources at [LibreTranslate GitHub page](https://github.com/LibreTranslate/LibreTranslate);
here's the [LibreTranslate installation documentation](https://docs.libretranslate.com/guides/installation/).
The easiest way is to run LibreTranslate via docker:
```bash
$ docker run --rm -ti -p 5000:5000 -v lt-local:/home/libretranslate/.local libretranslate/libretranslate
```
Note: to avoid huge downloads, you can limit the languages with e.g. ` --load-only en,fi`.
Here is the [LibreTranslate documentation on command-line arguments](https://docs.libretranslate.com/guides/installation/#arguments).

Once everything starts, open [localhost:5000](http://localhost:5000) and start translating.

# Dialect

The [Dialect](https://apps.gnome.org/Dialect/) app can provide very simple translation client:
```bash
$ sudo apt install dialect
```
Start the app, then go to Preferences / Providers, and set "Translator" to "LibreTranslate".
By default, the LibreTranslate.com will be used as backend. To reconfigure to use your local instance
press the cog wheel icon to the left of the "Translator" configuration and
enter `localhost:5000` as the Instance URL.

Now Dialect will use the local LibreTranslate.

# Accelerated Translation

By default the translation will use CPU only; longer texts may take a while to get translated.
If you have Nvidia, [LibreTranslate supports CUDA](https://docs.libretranslate.com/guides/installation/#cuda)
but I never tested that.
