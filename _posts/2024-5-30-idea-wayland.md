---
layout: post
title: Intellij IDEA on Wayland
---

Intellij IDEA now runs on Wayland, and it runs surprisingly well! What's even better,
IDEA running on Wayland is now compatible with UTM, meaning that you can finally set up
a perfect dev env in Ubuntu running in UTM! IDEA runs buttery-smooth, no hiccups;
if I'd have to guess it's partly because of JVM 21 and partly because of dropping X
baggage.

## How to enable Wayland

Starting from JetBrains Runtime (JBR) 21, [JBR 21 supports Wayland](https://blog.jetbrains.com/idea/2024/05/intellij-idea-2024-2-eap-2/#switch-to-jbr-21).
The easiest way to run IDEA on JBR 21 is to [download IDEA 2024.2 EAP 2](https://www.jetbrains.com/idea/nextversion/).
Then, edit the `idea64.vmoptions` file and add the
`-Dawt.toolkit.name=WLToolkit` VM option as described in [JBR 3206 comment](https://youtrack.jetbrains.com/issue/JBR-3206/Native-Wayland-support#focus=Comments-27-9266459.0-0).
Done!
