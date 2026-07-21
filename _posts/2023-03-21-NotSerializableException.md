---
layout: post
title: NotSerializableException
---

Sometimes the serialized class suddenly references a completely unexpected class by accident
(maybe some class is an inner class or such). However,
by default the `NotSerializableException` prints only the offending class that's not serializable, but it doesn't
print the 'field path' how the serialization got there.

The solution is to run the JVM with `-Dsun.io.serialization.extendedDebugInfo=true`. The `NotSerializableException`
message will now contain a full 'field path' from the object being serialized, all the way to the
offending class. You can examine the path and remove offending fields that shouldn't be serialized
in the first place.

Found at [Serializable Exception in Java](https://software-creation.nl/2011/07/serializable-exception-in-java/).
