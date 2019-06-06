---
layout: post
title: Android XML Parsing
---

If you ever tried to parse XML on Android [the encouraged way](https://developer.android.com/training/basics/network-ops/xml),
trying to parse a simple XML `<foo>Hello World!</foo>` will yield the following code:

```java
 import java.io.IOException;
 import java.io.StringReader;

 import org.xmlpull.v1.XmlPullParser;
 import org.xmlpull.v1.XmlPullParserException.html;
 import org.xmlpull.v1.XmlPullParserFactory;

 public class SimpleXmlPullApp
 {

     public static void main (String args[])
         throws XmlPullParserException, IOException
     {
         XmlPullParserFactory factory = XmlPullParserFactory.newInstance();
         factory.setNamespaceAware(true);
         XmlPullParser xpp = factory.newPullParser();

         xpp.setInput( new StringReader ( "<foo>Hello World!</foo>" ) );
         int eventType = xpp.getEventType();
         while (eventType != XmlPullParser.END_DOCUMENT) {
          if(eventType == XmlPullParser.START_DOCUMENT) {
              System.out.println("Start document");
          } else if(eventType == XmlPullParser.END_DOCUMENT) {
              System.out.println("End document");
          } else if(eventType == XmlPullParser.START_TAG) {
              System.out.println("Start tag "+xpp.getName());
          } else if(eventType == XmlPullParser.END_TAG) {
              System.out.println("End tag "+xpp.getName());
          } else if(eventType == XmlPullParser.TEXT) {
              System.out.println("Text "+xpp.getText());
          }
          eventType = xpp.next();
         }
     }
 }
```

A true Java-ish solution: the code is
* complex
* horrible
* error-prone
* hard to maintain
* hard to write
* The library API encourages you to write such shitty code
* Everybody seems to accept the fate and be okay with it.

On top of that, the solution:
* doesn't validate the XML
* exceptions won't report precise location in the XML

No wonder nobody young and sane would pick Java as the language worth learning.

How about replacing the above monstrosity with something like this (in Kotlin):

```kotlin
println("<foo>Hello World!</foo>".konsumeXml().childText("foo"))
```

That's what the [Konsume-XML](https://gitlab.com/mvysny/konsume-xml) library does -
it allows you to call high-level functions to parse XML, and it shields you from
direct interaction with the pull
parser (which is used under-the-hood). And no annotations
([another Java pain point](../post-annotation-programming/)).
