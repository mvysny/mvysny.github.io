---
layout: post
title: Frameworks and Languages Fit for AI
date: 2026-09-15 11:14:51 +0300
---

> DRAFT — part 1 is final; parts 2-4 are tables plus stubs.

When an AI agent writes code in your project, some of your stack helps it and some of it
doesn't. This post tries to say *which parts*, as a comparison of known facts rather than a
verdict on anyone's favourite framework. Spring Boot turns up as a contrast case in part 4;
that is not a claim that it is bad software, only that it scores a particular way against a
particular list. The list comes first, so you can disagree with the list rather than with me.

Nothing in the first part is new. Back in 2017 I wrote
[Code Locality and the Ability To Navigate](../code-locality-and-ability-to-navigate/),
which argued that a maintainable project is one where you can tell what the program does
**without running it**, and named three properties: readability, locality, and the ability
to `Ctrl`+click your way to the answer. Those properties have not changed. What changed is
that the compensations are gone.

A human maintainer working in a hostile codebase has fallbacks. They ask the colleague who
wrote it. They remember what bit them last month. They run the thing and watch. An agent has
none of these: no colleague, no memory across sessions, and often no ability to run the app
at all. So every property that used to be *nice for maintainers* becomes *load-bearing for
agents*. The list below is the 2017 list, re-derived for a reader who cannot ask anybody.

The mapping is close to one-to-one:

| 2017, for human maintainers | This post, for agents |
|---|---|
| Code Readability | Information density (5) + Idiom convergence (6) |
| Code Locality | Locality of reasoning (4) |
| Ability to Navigate | Introspectable as data (11) + Knowable on demand (13) |

What's genuinely new is the rest: an oracle, because there is nobody to ask whether the
change is right; and a reproducible loop, because the agent will run that loop a few hundred
times in an afternoon.

## Part 1: the properties

Thirteen of them, in five groups. Each one exists because of a specific way agent work goes
wrong; I've named the failure mode, because a property whose failure you can't picture isn't
doing any work.

### The oracle — can a machine tell right from wrong?

**1. Verifiability.** A machine can decide whether a change is correct, with no human
looking — compiler, type checker, test suite, whatever answers yes/no. Of the last ten bugs
you fixed, how many would `build && test` have caught? That fraction is the property.
*Failure mode:* the agent cannot tell whether it is finished, so it either stops and asks
you, or declares victory on a guess.

**2. Oracle honesty.** When the oracle says green, the application actually works: no
category of failure passes silently. Name a class of failure your suite structurally cannot
see — and if you can't name one, that is the dangerous case, not the reassuring one.
*Failure mode:* the agent declares victory on a broken app — and it is not being careless,
the oracle told it so.

Easy to conflate with the first one. A fast, cheap, comprehensive oracle that lies is worse
than no oracle, because it converts "I don't know" into "I checked".

**3. Errors that close the loop.** A failure names the fix, and names it at the site of the
fix. Take the errors your build printed this week: how many name the file *and* what to
change?
*Failure mode:* the agent mutates code semi-randomly until the red goes away. Each iteration
is cheap, so it will do this for a long time before it gives up, and what it lands on may be
green for the wrong reason.

### Reading — what has to be in context?

**4. Locality of reasoning.** You can determine what the code does by reading the code in
front of you. The 2017 test still works: follow the execution flow of one request by
`Ctrl`+clicking, and count how many times you land somewhere with no code in it.
*Failure mode:* the agent reads the three files it can see, reasons correctly about them,
and is wrong — because the behaviour was decided elsewhere, by a classpath entry, a proxy,
or a property file.

**5. Information density.** Meaning per token.
*Failure mode:* the agent's attention is spent on ceremony rather than on your logic.

The obvious justification — "more of the app fits in the window" — is the weak one, and gets
weaker as context windows grow. The real cost of low-density code is **attention, not
tokens**: everything in the window competes for it. Ten lines of getters and setters
overflow nothing; they dilute the three lines that matter.

**6. Idiom convergence.** There is one canonical way to do a given thing, and the codebase
does it that way throughout.
*Failure mode:* the agent generalises from whichever file it read most recently, so five
spellings of the same operation become five dialects in your repo. Nothing breaks. The
codebase just stops pattern-matching against itself, which degrades every later change.

### Writing — what happens when the agent acts?

**7. Bounded blast radius.** A wrong edit stays contained, and a mechanical refactor is
atomic. Can your tooling rename a public method across the repo such that you would merge
the diff without reading it?
*Failure mode:* a rename half-lands. The build is green and one call site is wrong.

**8. Safe defaults.** The default is the correct one, and nothing important requires
remembering.
*Failure mode:* the agent omits the annotation that nobody told it about. Not because it is
sloppy — because it did not know the annotation existed, and nothing failed.

Deny-by-default security is the highest-stakes instance, but the property is general:
non-null by default, strict parsing, no lenient modes. Anything you must opt into, an agent
eventually won't.

### The loop — the mechanics of edit-and-check

**9. Loop latency.** Wall-clock time from edit to verdict.
*Failure mode:* fewer iterations, and worse, *batched* changes — when a verdict is expensive
the agent makes five changes before checking, and then cannot attribute the failure to one
of them.

**10. Reproducible environment.** One documented command, from a cold checkout, gives the
same working build every time.
*Failure mode:* the agent spends the session fixing the environment instead of the bug, and
its fixes are indistinguishable from progress until you look.

**11. Introspectable as data.** The agent can ask the system structurally — call hierarchies,
references, routes, config — instead of grepping for strings.
*Failure mode:* the agent greps and guesses. `grep` finds text; it does not find callers,
and it cannot tell you what it missed.

### Knowledge — how does the model come to know your stack?

**12. Version legibility.** The model can tell *which version* it is writing against.

Raw familiarity is not the property. A model that has seen an enormous amount of a framework
has usually seen *several incompatible versions of it at once*, with nothing in the training
data saying which one you are on.
*Failure mode:* fluent, confident, six-year-old idiom. This is the same defect as a
documentation file that drifted from the code: the agent acts decisively on something that
used to be true.

**13. Knowable on demand.** When the agent needs a fact, it can get it — either because the
framework's whole surface fits in a spec file you hand it up front, or because the
authoritative answer sits where its cursor already is: in the signature, in the doc comment,
in one readable file.
*Failure mode:* the answer exists, somewhere the agent didn't think to look, so it invents
one. This is the worst reading failure, because an invented answer looks exactly like a
recalled one.

This is where an unfamiliar-but-small framework beats a famous-but-sprawling one — and it
does most of the work in part 4.

### Three things to say out loud before the tables

**These properties trade against each other.** Density buys you attention and spends
locality — Kotlin's extension functions are the clean example. Safe defaults buy you
correctness and spend locality, because magic that protects you is still magic. More oracle
buys you verifiability and spends loop latency. Nothing here sweeps, and a stack that scored
full marks on all thirteen would be suspicious.

**Locality is the usual currency.** Two of those three trades are paid in it, and that is
not a coincidence of my examples — locality is the largest family in the list. Property 4 is
locality in *reading*; 3 is locality in *diagnosis*, since an error that names the site of
the fix is a local one; 7 is locality in *effect*, whether the change stays where you put
it; and 11 and 13 are the two recovery mechanisms for when locality has already failed —
navigate to the answer, or look it up. That is the 2017 grouping again, which listed Code
Locality and Ability to Navigate side by side for exactly this reason: the second is needed
in proportion to how much the first is missing.

It would be tidy-minded to go one step further and call locality the root of the whole list.
It isn't. Verifiability, oracle honesty, density, idiom convergence, loop latency,
reproducibility and version legibility are all independent of it — and property 8 is
actively *anti*-local, because a safe default is correct behaviour you did not write and
cannot see. That is mechanically the same thing as the autoconfiguration I complain about in
part 4, pointed somewhere useful. Non-locality is a cost, not a defect, and it is sometimes
worth paying.

Which is why this is thirteen rows and not one. Spring Boot and Python both score badly on
locality, for unrelated reasons — Spring in effect and diagnosis, Python in reading and
recovery — and a single merged row would hide precisely the distinction the tables exist to
draw.

**Some of these measure tooling, not syntax.** A language is syntax *plus* its tooling; the
best-designed language in the world doesn't help if nothing can catch its errors or steer an
agent through it. Properties 7 and 11 in particular are mostly "how good is the language
server", and that is a number with a shelf life. **Everything below is as of September
2026**, and the Kotlin row is the one most likely to be wrong by the time you read it.

## Part 2: Java vs Kotlin vs Python

Python is here as the control. It maximises the one property this post is most likely to be
accused of underweighting — sheer training-corpus mass, since it is the language models know
most intimately — and it is weakest on the oracle group. If the thirteen properties are
worth anything, Python should come out mixed rather than sweeping.

Which Python: the one agents usually meet — no mandatory typing, `pip` and `venv`. A
disciplined Python (`uv` with a lockfile, strict `pyright`, `ruff`) moves four of these
cells, noted below.

`●` strong · `◐` partial · `○` weak

| | Java | Kotlin | Python |
|---|---|---|---|
| 1. Verifiability | ● compiler, static types | ● + nullability in the type system | ○ opt-in, `mypy`/`pyright` |
| 2. Oracle honesty | ◐ compiler is blind to null | ● null checked at compile time | ○ tests cover executed lines only |
| 3. Errors that close the loop | ● plain, positional | ◐ good; bad inference tail | ◐ excellent traceback, but at runtime |
| 4. Locality of reasoning | ● bland and explicit | ◐ extension fns resolve by import | ○ duck typing, decorators, monkeypatching |
| 5. Information density | ○ ceremony | ● data classes, default args | ● minimal syntax |
| 6. Idiom convergence | ● one way to do it | ○ five scope functions | ◐ stated value; three packaging tools |
| 7. Bounded blast radius | ● JDTLS atomic rename | ◐ LSP immature | ○ duck typing defeats rename |
| 8. Safe defaults | ◐ null allowed by default | ● non-null by default | ○ dynamic and mutable by default |
| 9. Loop latency | ◐ compile step | ○ slower than Java | ● no compile step |
| 10. Reproducible environment | ● coordinates + lockfile | ● same | ○ `venv`/`pip` — `◐` with `uv` |
| 11. Introspectable as data | ● JDTLS call hierarchies | ○ LSP immature | ◐ `pyright` decent; dynamism limits it |
| 12. Version legibility | ● 2012 code still idiomatic | ◐ stable; coroutine/K2 churn | ● Python 3 settled, corpus current |
| 13. Knowable on demand | ● javadoc ships in the jar | ● KDoc, same mechanism | ● docstrings, `help()`, REPL |

Only the rows where the three actually differ get prose:

### Where Kotlin moves the compiler (2, 8)

> STUB: nullability moves into the type system with no annotations, no external checker, no
> build configuration. For an agent, "the oracle catches NPEs" vs "the oracle catches NPEs
> if someone wired up JSpecify correctly" is the whole difference, because the agent will
> not notice the wiring is missing. Plus `when` exhaustiveness over sealed hierarchies:
> compiler-as-oracle applied to business logic, not just to types. Java has this now via
> sealed interfaces and pattern matching; Kotlin's is more idiomatic, so a model is more
> likely to actually write it.

### Where Kotlin's tooling costs it (7, 11)

> STUB — the row to fact-check before publishing. JDTLS is mature and is effectively a
> structured `describe --json` for a Java codebase: call hierarchies, reference search,
> cross-project rename, no build required. Kotlin's compiler is excellent and its language
> server is not: the community `kotlin-language-server` has been under-maintained for
> years, and JetBrains' official Kotlin LSP is recent. State its September 2026 status
> plainly and date the claim. Consequence: the agent hand-edits call sites that JDTLS would
> have renamed atomically (7), and falls back to grep for reference search (11).

### Where expressiveness cuts against reading (4, 6)

> STUB: `user.toDto()` resolves by import, so reading the file tells you nothing about where
> `toDto` lives — action at a distance, milder than a proxy but the same category. Scope
> functions are the idiom-convergence case: `let`, `run`, `also`, `apply`, `with` are five
> spellings of nearly one thing and models pick among them inconsistently. Java's blandness
> is doing real work here. Mitigable with a project style section, which is property 13
> paying for property 6.

### Where Python is strongest, and what it costs (1, 9, 10)

> STUB: no compile step is the best loop latency in the table — but the verdict you get
> fast is a *narrower* verdict, covering only the lines the tests executed. That is the
> trade the whole oracle group is about: Python gets to the answer quickest and the answer
> says least. Reproducible environment is the sharpest factual split in this table, and the
> one that costs agents the most session time in practice.
>
> The disciplined-Python delta: `uv` moves row 10 to `◐`, strict `pyright` moves rows 1 and
> 7 up one, and neither touches row 2 — an untyped boundary still passes.

## Part 3: Karibu-Testing vs Selenium

> STUB. Framing correction to make early: these are not two ways of doing the same thing at
> different speeds. Karibu **structurally cannot see** what Selenium sees. So this table is
> not a ranking, it is a map of two non-overlapping oracles.

| | Karibu-Testing | Selenium |
|---|---|---|
| 1. Verifiability | ● | ● |
| 2. Oracle honesty | ◐ blind to visual/bundle failures | ● sees the real browser |
| 3. Errors that close the loop | ● JVM stack trace into your code | ○ "element not found" |
| 9. Loop latency | ● sub-second, in-JVM | ○ browser start, seconds to minutes |
| 10. Reproducible environment | ● plain JVM test | ◐ browser + driver versions |
| 13. Knowable on demand | ● small API, KDoc at the cursor | ◐ large surface, flakiness undocumented |

> STUB, the argument: Karibu is the inner loop, browser tests are a thin outer gate. Hundreds
> of Karibu tests sub-second on every change; a handful of browser tests covering only what
> Karibu is blind to — layout doesn't overflow, the production bundle builds and loads, real
> JS components initialise. **Small in number, not lower in priority.** Framing them as a
> "distant second" is how they rot, and then the one failure class your fast oracle cannot
> detect is also the untested one. That is property 2 failing by neglect rather than by
> design.
>
> Second point, on mocks: Karibu bootstraps the real database and real services. This matters
> more for agents than for humans. Mocks are precisely where an agent writes a green suite
> over a broken app, because it mocked the thing that was wrong — and it will do this
> confidently, since the oracle agreed.

## Part 4: Vaadin Boot vs Spring Boot

> STUB. Disclosure line needed: I wrote Vaadin Boot. So this section states facts either
> reader can check and lets Spring win the rows it wins, which are real ones.

| | Vaadin Boot | Spring Boot |
|---|---|---|
| 2. Oracle honesty | ◐ Maven servlet-scope trap | ◐ context loads ≠ app works |
| 4. Locality of reasoning | ● `main()`, `@WebListener`, static getters | ○ autoconfiguration, proxies, property precedence |
| 3. Errors that close the loop | ● your code plus Jetty | ◐ deep reflective stack traces |
| 8. Safe defaults | ○ wire `vaadin-simple-security` yourself | ● deny-by-default with Spring Security |
| 11. Introspectable as data | ○ nothing built in | ● Actuator |
| 12. Version legibility | ◐ thin corpus, but one version of it | ○ enormous corpus, many versions at once |
| 13. Knowable on demand | ● whole surface in a few hundred tokens | ○ answer is not at `@Transactional` |

> STUB, and the rows to argue:
>
> **4 and 13 are the case for Vaadin Boot.** The API is `new VaadinBoot().run()` plus about
> eight configuration methods; initialisation is a plain `@WebListener`; services are a class
> of static getters, so the call chain is one you follow by reading, with no container in
> between. Whole surface fits in a spec file. Link the
> [Annotatiomania section of the 2017 post](../code-locality-and-ability-to-navigate/) —
> `Ctrl`+clicking `@Transactional` lands on an annotation definition containing no code, which
> is property 13's failure mode described nine years before anyone was worried about agents.
>
> **8 and 11 are the case for Spring Boot, and they are not small.** Deny-by-default is the
> highest-leverage safe default there is, and dropping it means a new `@Route` is unprotected
> until somebody remembers. Actuator is genuine introspection-as-data with no equivalent.
> Both are replaceable by things you write — a Karibu test that enumerates every discovered
> route and fails if the view lacks an access annotation; a twenty-line `describe` endpoint
> dumping routes and services as JSON — but "replaceable by code you own" is a different claim
> from "present by default", and the difference is exactly property 8.
>
> **12 is the interesting row.** Spring's familiarity advantage is real and is the strongest
> argument against everything else in this section. It is also familiarity with many Spring
> versions simultaneously, which is the drift problem, not a solution to it.
>
> **Row 2 needs the concrete trap**, because it is the best specimen in the post: on Maven
> with Jetty, `vaadin-bom` manages `jakarta.servlet-api` to `provided` scope — correct for WAR
> deployment, wrong when Vaadin Boot *is* the container — so the app dies at startup with
> `NoClassDefFoundError`, and `mvn test` still passes, because Karibu-Testing pulls the servlet
> API in at test scope. Green oracle, broken application, agent moves on. Two fixes, and both
> generalise: prefer Gradle, where `platform()` contributes version constraints without
> propagating scopes; and add a smoke test calling `start()` / `getServerURL()` / `stop()`, so
> "the app boots" is *inside* the oracle rather than outside it.

## What to do with this

> STUB: the list is more useful than the verdicts. Score your own stack, find the one or two
> rows where you're weakest, and convert the weakness into an oracle — that is the move that
> recurs in every section above. A missing default becomes a test. A missing Actuator becomes
> twenty lines of JSON. An untested boot path becomes a smoke test. Properties you cannot fix
> get written down in a spec file instead, which is property 13 paying for everything else.
>
> Optional closing subsection — the stack these criteria actually pick, if I want to end on
> something concrete rather than abstract: Kotlin + Vaadin 24 + Vaadin Boot (Jetty) + Gradle
> + vok-orm + Flyway + vaadin-simple-security + Karibu-Testing + slf4j-simple, on JDK 21.
> Javalin 5.x if REST is needed, since Javalin 6 doesn't support the Jetty 12 that Vaadin
> Boot 13+ uses. Gradle over Maven for the scope reason in part 4.
>
> And the `SPEC.md` that goes with it, kept under ~2k tokens — this is property 13 made
> concrete, and is arguably the single most useful paragraph in the post: pinned versions
> with a "do not write these deprecated idioms" list (property 12); the allowed Kotlin subset
> — which scope functions, where extension functions may live, no operator overloading, no
> custom DSLs (property 6); the services-as-static-getters convention (property 4); "every
> route needs an access annotation, enforced by test" (property 8); "schema changes go
> through Flyway, never by hand"; and the Karibu test template. That file does the job
> Spring's conventions used to do, except it is three screens long and you can diff it.
