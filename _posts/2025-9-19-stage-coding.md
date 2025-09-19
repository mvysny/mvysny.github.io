---
layout: post
title: Stage Coding
---

So we have vibe coding, coined by Andrej Karpathy (super-smart guy, but my two cents - not really a coding ;). Maybe another kinds
of coding should be coined as well. On top of prototyping and maintenance, I'm proposing stage coding. What is it?

# Stage Coding

Picture yourself, being on the stage, presenting to a crowd, live-coding. It doesn't matter whether the code is performant or well-structured,
or whether the program even works - you're conveying an idea to your audience and you want to be as
clear and quick as possible. You're delivering the message at a typing speed; that means you're limited
by your typing speed, which is also the cognitive speed of your audience (the moment you start
generating walls of code, you lose your audience, and you don't want that).

In this kind of setup, almost anything goes - annotations, utility functions, quick-and-dirty code blocks that you would
be ashamed of under regular circumstances - and that's okay. The point is to deliver a message, not to produce
good code. You're going to write code once, the audience is going it read it once, and that's it - when the presentation is over,
the code is gone.

Spring is perfect for this case: you can get very far simply by adding an annotation or two (or ten). You don't
care about the massive annotation processors hidden behind those teeny-weeny annotations (and the ways they can blow up) -
you're conveying the message and throwing the code away afterwards.

# Prototyping

This goes even further than presentation coding - no-one is looking, so the code can be as ugly as it can get.
No-one is going to read the code - you write it, you run it, you test the idea, and then you delete the code
and move on.

Again, Spring shines here. Quick annotation here and there does the job, and then you throw it away. Job done.

# Maintenance

Now the game changes completely. It's still very important to get the idea through to your colleagues, yes -
programming is all about conveying your ideas to your colleagues, and the program actually working is a happy side-effect.
However, the speed of writing is no longer that important: you are now free to rewrite parts of the program multiple
times, to make the idea clearer. Exactly as when writing a book - it's going to be read by many,
so you better make those sentences crystal-clear.

I am a firm believer that [simplicity](../on-simplicity/) and [code locality](../code-locality-and-ability-to-navigate/) are
two most important things when it comes to writing maintainable code.
And this is where annotation processors such as Spring completely fall apart.

Since the annotation itself doesn't do anything, it needs an annotation processor to do the work.
Annotation processor is a class completely unrelated to the annotation itself - annotation
is not a function call so you can't "step in" with your debugger to figure things out.
This breaks the "code locality" principle.

On top of that, annotation processors are typically huge, abstract and complex, since they have
to support all configurations attached to the annotation. But all that is just a dead weight in your project,
since you use but a tiny subset of its functionality. Worse than a dead weight, since the complexity gets in the way
once you start debugging it. That breaks the "simplicity" principle.

The conclusion is clear: Spring is a liability when it comes to maintenance.

# Conclusion

Beware when a nice guy with a cool T-shirt tries to sell you on something on a conference stage.
His objectives do not match yours - he's there to sell himself and his product and then possibly some consulting,
should you use his product and things go south. Beware of the [merchants of complexity](../on-complexity/), since
you are on the other side of the barricade: you're here to make the app work and fix bugs quickly;
the merchant of complexity is here to sell help to you, once you buy into complexity and it explodes for you
and you need help quickly.

Spring looks so shiny and lovely on a fancy conference stage, but yours is the maintenance
game: and these stages are very far apart.

