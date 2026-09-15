---
layout: post
title: Frameworks and Languages Fit for AI
date: 2026-09-15 11:14:51 +0300
---

> DRAFT — parts 1 and 2 are final; part 3 is a full first draft; part 4 is tables plus stubs.

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
disciplined Python (`uv` with a lockfile, strict `pyright`, `ruff`) moves three of these
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
| 7. Bounded blast radius | ● JDT LS rename, mature | ◐ rename listed, Alpha | ○ duck typing defeats rename |
| 8. Safe defaults | ◐ null allowed by default | ● non-null by default | ○ dynamic and mutable by default |
| 9. Loop latency | ◐ compile step | ◐ compile step, slower than `javac` | ● no compile step |
| 10. Reproducible environment | ● coordinates + lockfile | ● same | ○ `venv`/`pip` — `◐` with `uv` |
| 11. Introspectable as data | ● JDT LS, blind only to Kotlin | ◐ exact refs; call hierarchy skips tests | ◐ `pyright` decent; dynamism limits it |
| 12. Version legibility | ● 2012 code still compiles and reads fine | ◐ stable; coroutine/K2 churn | ● Python 3 settled, corpus current |
| 13. Knowable on demand | ● javadoc ships in the jar | ● KDoc, same mechanism | ● docstrings, `help()`, REPL |

Row 13 is a three-way tie and gets no prose. The other rows do, biggest differences first:

### Where Kotlin moves the compiler (2, 8)

Nullability is in the type system, with no annotations, no external checker and no build
configuration. The difference that makes for an agent is not "fewer NPEs" — it is the
difference between *the oracle catches this* and *the oracle catches this if somebody wired up
JSpecify correctly*. An agent will not notice that the wiring is missing. It will read code
that looks annotated, write code that looks annotated, and get no complaint from a checker that
was never switched on. That is a property 8 failure producing a property 2 failure: the missing
default makes the oracle quietly narrower than it appears.

`when` exhaustiveness over sealed hierarchies is the same mechanism pointed at business logic
rather than at types. Add a case to a sealed type and every incomplete branch becomes a compile
error — a silent behavioural gap converted into a loud failure, which is the whole game. Java
has had the same check since Java 21, via sealed interfaces and pattern-matching `switch`. The
difference is how common it is: Kotlin code has used it routinely for a decade, while most Java
in the training data predates it, and how common an idiom is decides whether a model writes it.

Python's position here is the honest counterweight: type hints plus `mypy` or `pyright` can get
a long way, and modern strict-mode `pyright` is genuinely good. But it is opt-in at every
boundary, and an untyped boundary doesn't fail — it just stops checking. Opt-in safety and
agents interact badly for exactly the reason property 8 exists.

### Where Kotlin's tooling costs it (7, 11)

I couldn't write this row from memory, so I measured it. The measurements got long enough for a
post of their own:
[The State of Java and Kotlin Language Servers](../java-kotlin-lsp-status/). It compares
JetBrains' free, Alpha `kotlin-lsp` with Eclipse JDT LS, run through an agent's LSP tool on three
repositories. The short version, as of September 2026:

- **Kotlin's navigation is better than its Alpha label suggests.** Find-references,
  go-to-definition, go-to-implementation and hover are precise. They cross into Java and across
  Gradle modules, and in a mixed repo `kotlin-lsp` is a better reference engine for *Java* symbols
  than JDT LS, as long as you ask from a Kotlin file. Row 11 doesn't lose where I expected.
- **It loses on call hierarchy.** The call hierarchy silently drops every caller or callee that
  lives in test code, so "who calls this?" gets a confident `nothing calls this function`. Search
  by symbol name misses classes that plainly exist.
- **JDT LS is mature on Java**, and its call hierarchy does see tests. It fails silently too:
  callers written in Kotlin are simply missing, and `findReferences` merges two classes that share
  a fully-qualified name in different modules.
- **Row 7 stays on reputation.** The agent's LSP tool can't call rename on either server, so
  Java's `●` is a decade of JDT and Kotlin's `◐` is the Alpha label. Neither is a measurement.

The lesson that carries over to other tools isn't about Kotlin: **when you wire a tool into an
agent loop, how it fails matters as much as how well it works.** A server that refuses is safe at
any quality level, because the agent falls back to `grep` and says so. A server that returns an
empty list, or a well-formed wrong one, gets acted on. The obvious next step after "nothing calls
this function" is to delete the function.

Rule of thumb for this row: if the agent does most of its editing through a language server,
check the current state on your own repo before you commit to it. That claim moves faster than
anything else in this post, and the research post ends with a checklist you can hand to an agent.
If the agent mostly reads and writes whole files and uses the compiler and Karibu-Testing (browserless UI tests, part 3) as its oracle,
which is the common setup, the gap costs much less, and Kotlin's nullability and density come out
ahead.

### Where expressiveness cuts against reading (4, 6)

Extension functions resolve by import, so `user.toDto()` tells you nothing about where `toDto`
lives. That is action at a distance — milder than a runtime proxy, but the same category. Here
tooling does recover it: go-to-definition resolves the import, and `kotlin-lsp` gets it right.
But that only helps an agent that asks the language server. An agent that greps for `toDto`
finds the call plus every other function with the same name, and has no way to tell them apart.

Scope functions are the idiom-convergence case, and a clean one. `let`, `run`, `also`, `apply`
and `with` are five spellings of nearly the same thing; models pick among them inconsistently,
because the training data does. Nothing breaks, and that is the point — the codebase simply
stops being self-similar, so the next edit generalises from a worse sample. Operator
overloading and infix functions extend the same problem. Java's blandness is doing real work
here, and it is the clearest case in the post of a property that looks like a weakness
(property 5, density) protecting a property that isn't (property 6).

All of this is the most controllable risk in the table: a short, opinionated style section in
the project's spec file — which scope functions are allowed, where extension functions may
live, no operator overloading, no custom DSLs — fixes most of it. That is property 13 being
spent to buy property 6, and it is the cheapest trade available anywhere in this post.

### The smaller gaps (3, 5, 9, 12)

**Errors (3).** `javac` errors are plain: a file, a line, and a sentence that usually names the
fix. Most Kotlin errors are just as good. The exception is type inference: when a generic call
or a lambda fails to infer, the error can be long and can point at the call rather than at the
argument that caused it. Python's traceback is the best of the three to read, but it only
arrives when the line runs, so it catches only what the tests executed.

**Density (5).** Java's ceremony is shrinking — records and `var` cut a lot of it — but the
code models learned Java from is full of getters, setters and builders, and that is the Java
they write. Kotlin and Python both state a data class or a function call with default
arguments in one line. As part 1 argued, the cost of ceremony is attention, not tokens.

**Loop latency (9).** Kotlin compiles more slowly than `javac`. Incremental builds and the K2
compiler have narrowed the gap, which is why both JVM languages score `◐`. Both lose clearly to
Python, which has no compile step at all.

**Version legibility (12).** Java never breaks old code, so the model's Java drifts in style,
not correctness: pre-records, pre-`var` code that still compiles. That costs density, not the
build. Kotlin's language is also stable, but its ecosystem has moved underneath it: coroutines
went from experimental to stable, `kapt` gave way to KSP, and K2 replaced the compiler. So
the model writes `GlobalScope.launch` and `kapt` with the same fluency as the current idioms.
The compiler catches some of that as deprecation warnings; an agent tends to ignore warnings.

### Where Python is strongest, and what it costs (1, 9, 10)

No compile step is the best loop latency in the table, and it is not a small advantage — the
agent gets a verdict in the time the JVM spends starting. But the verdict is *narrower*: it
covers the lines the tests actually executed, and nothing else. That is the trade the entire
oracle group is about. Python reaches an answer fastest and the answer says least; Kotlin takes
longest and says most. Neither is wrong, and which one you want depends on whether your failures
are the kind that show up when a line runs.

Reproducible environment is the sharpest factual split in the table, and in my experience the
one that costs agent sessions the most wall-clock time. A JVM project names its dependencies by
coordinates and resolves them the same way on every machine; the failure mode is a slow
download. Python's default toolchain gives an agent several plausible ways to be in the wrong
environment, and — the part that matters for property 2 — being in the wrong environment
produces errors that look like code errors. The agent then fixes the code.

Two things keep this fair. First, the disciplined-Python delta is real: `uv` with a lockfile
moves row 10 from `○` to `◐`, and strict `pyright` moves rows 1 and 7 up a step. Neither touches
row 2, because an untyped boundary still passes silently. Second, Python ties Java for the
lead on row 12, ahead of Kotlin, and it is worth saying why: Python 3 is settled, and the model's Python is *current*, where its
Vaadin is several years old. That is the single strongest argument for using the language models
know best, and it is a genuine one.

Which is the result the control was there to produce. Python leads outright on one row (9),
ties for the lead on three more (5, 12, 13), trails both rivals on six, and trails only Java on
the remaining three. The wins and losses cluster rather than cancelling out. It is level with
the best on both knowledge rows; weakest on the oracle, last on two of its three rows and
ahead on none; and split down the middle on the loop, holding the fastest iteration in the table and the least
reproducible environment. Corpus mass is worth a great deal, and it does not buy verification.

## Part 3: Karibu-Testing vs Selenium

Disclosure first: I wrote Karibu-Testing. So this section sticks to things you can check, most
of them by running a test, and it is explicit about where the browser wins — which turns out to
be the row that matters most.

The framing matters more than the scores. These are not two ways of doing the same job at
different speeds. Karibu-Testing runs your Vaadin component tree inside the test JVM, with no
browser, no servlet container and no JavaScript, so it **structurally cannot see** anything that
happens on the client. A browser test sees exactly that. The table below is therefore not a
ranking. It is a map of two oracles that cover different ground, and the useful question is how
to split the work between them.

"Selenium" stands for the browser-driven family. TestBench is Selenium plus Vaadin-aware element
classes and automatic waiting; Playwright replaces the driver architecture and retries its
assertions. Where either changes a cell, the prose says so. On the other side, Vaadin's own
browserless testing (formerly UI Unit Testing, free since Vaadin 25.1) works on the same
principle as Karibu, so the structural rows — 2, 9 and 10 — apply to it too. I haven't measured
its error messages.

Rows 4, 5 and 7 are left out: they describe the code you ship, not the tool that checks it.

| | Karibu-Testing | Selenium |
|---|---|---|
| 1. Verifiability | ● pass/fail in JUnit | ● pass/fail in JUnit |
| 2. Oracle honesty | ◐ blind to JS, CSS, the bundle | ● sees the real browser |
| 3. Errors that close the loop | ● prints the component tree | ○ "wrong place or wrong time" |
| 6. Idiom convergence | ● `_get` plus a search spec | ○ five locators, three ways to wait |
| 8. Safe defaults | ◐ `_click()` checks; `click()` doesn't | ○ implicit wait is zero |
| 9. Loop latency | ● tens of ms per test, in-JVM | ○ app server + browser, seconds per test |
| 10. Reproducible environment | ● one test dependency | ◐ Selenium Manager; still a browser and a server |
| 11. Introspectable as data | ● component tree as Java objects | ◐ DOM, mostly behind shadow roots |
| 12. Version legibility | ◐ thin corpus; API stable since 2020 | ○ Selenium 2/3 idiom dominates |
| 13. Knowable on demand | ● small API, KDoc at the cursor | ◐ knowing Selenium ≠ knowing Vaadin's DOM |

### What Karibu cannot see (2)

Karibu's README says it in one line: there is no browser, so it is not possible to test or call
JavaScript. Everything downstream of that is invisible as well, and it is worth listing, because
part 1's test for this property was *name a class of failure your suite structurally cannot
see*:

- CSS and layout: a form that overflows, a button hidden behind a dialog;
- the production frontend bundle failing to build, or building and failing to load;
- a JavaScript component — an add-on, a chart, anything rendered client-side by a `LitTemplate`
  — failing to initialise;
- anything your code does through `executeJs()`.

Being able to write that list is the good news. A blind spot you can name is one you can cover.

A subtler gap follows from something Karibu does on purpose. In a browser, the Grid shows the
rows it last fetched until something calls `DataProvider.refreshAll()`. Karibu has no client-side
cache to go stale: every Grid operation in a test polls the data provider for fresh rows. That
makes Grid tests simple, and it also means a forgotten `refreshAll()` — the database changed, the
screen still shows the old rows — passes under Karibu. It is the same shape as the list above: a
failure that lives in what the client *keeps*, which a server-side oracle never sees.

Selenium's blind spot is of a different kind: economic rather than structural. A browser test
can see the hundredth validation path perfectly well. Nobody writes it at several seconds a run.

### Karibu fakes Vaadin, not your app

Karibu mocks exactly one thing: the servlet environment Vaadin expects — the session, the
request, the `UI`. Your services and your database are real. You start the application inside
the test JVM, typically by calling the same `ServletContextListener` the server would call, so a
`_click()` runs the real listener against the real service and the real database.

That matters more for agents than for humans. The usual fast alternative to a browser test is a
unit test with the service mocked out, and a mock is exactly where an agent writes a green suite
over a broken app: it mocked the thing that was wrong, the oracle agreed, and it moved on with
full confidence. Karibu gets its speed by removing the browser, not by removing your code.

### Errors and introspection (3, 11)

I measured this row rather than describing it. In the Vaadin Boot example project, with
Karibu-Testing 2.7.2, I misspelled a label in a lookup — `withLabel("Your nme")` — and ran the
test:

```
java.lang.AssertionError: /: No visible TextField in MockedUI[] matching TextField and label='Your nme': []. Component tree:
└── MockedUI[]
    └── MainView[@class='centered-content', @style='width:100%', @theme='padding spacing']
        ├── TextField[label='Your name', value='', @class='bordered']
        └── Button[text='Say hello', @data-vaadin-shortcut-owner='sc-f7e6…', @theme='primary']
```

The message names the lookup that failed, says what it matched (nothing), and prints the whole
component tree, where the real label sits two lines below. The agent can fix this without running
anything else. It is also row 11 in miniature: `toPrettyTree()` can be called from any test, and
the components are ordinary Java objects that the test can query directly.

Selenium's equivalent is `NoSuchElementException`. Its documentation describes it as the element
not being found "at the exact moment you attempted to locate it", and gives two causes: looking in
the wrong place, or looking at the wrong time. Those call for opposite fixes — change the locator,
or add a wait — and the error cannot say which one applies. An agent will try both, which is row
3's failure mode word for word. Worse, if the server threw an exception, that exception sits in
the application server's log, in another process; the test only sees an element that never
appeared. Under Karibu the server's exception is thrown straight into the test.

For row 11 the browser has real data too — the DOM — but a Vaadin app keeps most of it out of
reach. Vaadin components are web components: the actual `<input>` of a `TextField` lives in shadow
DOM, XPath cannot cross a shadow root, and Selenium only gained `getShadowRoot()` in version 4.
Vaadin's own Playwright guide has to spell out recipes such as
`vaadin-confirm-dialog vaadin-button[slot='confirm-button']` for a dialog button, and
`:visible` for Grid cells, because the Grid recycles them while scrolling. None of those are
facts about Selenium or Playwright; they are facts about Vaadin's DOM. That is row 13's gap: an
agent that knows Selenium perfectly still has to learn a DOM that isn't documented anywhere near
its cursor. Hiding that DOM is what TestBench's element classes are for.

### Defaults and dialects (8, 6)

I measured row 8 as well. Disable the button, then call Vaadin's own `button.click()`: **the test
passes.** Call Karibu's `_click(button)` instead and it fails:

```
java.lang.IllegalStateException: The Button[DISABLED, text='Say hello', …] is not enabled
```

In a real browser the user cannot click a disabled button, and Vaadin's server ignores events
from disabled components anyway. So the green from `click()` is false — a property 8 gap
producing a property 2 failure, the same pattern as the missing nullability checker in part 2.
Karibu's cell is `◐` rather than `●` because both spellings exist, and the one that doesn't check
is plain Vaadin API, which a model has seen far more often. `_setValue()` versus `setValue()` has
the same trap. The fix is the cheapest one in this post: one line in the spec file — "in tests,
always `_click()` and `_setValue()`" — plus a `grep` in CI that fails on the other spelling, which
turns the rule into an oracle. Lookups are safe by default already: `_get` fails when it finds zero
matches *or more than one*, where Selenium's `findElement` silently returns the first of several.

Selenium's unsafe default is time. The implicit wait defaults to zero: "if the element is not
found, it will immediately return an error". Add waits and the documentation warns you not to
mix the implicit and explicit kinds, because a 10-second implicit wait combined with a 15-second
explicit one can time out after 20. It also names race conditions as "one of the primary causes
of flaky tests". A flaky test is the oracle lying in the other direction — red for an app that
works — and it teaches the agent, and the team, that red means "run it again". Karibu has nothing
to wait for: `_click()` returns once the listeners have run.

The browser-side tools differ most on this row. TestBench fixes the default and waits for Vaadin
to finish every round trip by itself. Playwright retries its own assertions, but Vaadin's guide
warns that reading `textContent()` and asserting with plain JUnit "might fail as the server
round-trip response might not yet be completed". That is a rule the agent has to remember — which
is property 8's failure mode again.

On row 6, Selenium lets you locate by id, name, CSS selector, XPath or link text, and wait
implicitly, explicitly, fluently or with `Thread.sleep()`; Page Objects are optional. Every
combination is in the training data, and every one will turn up in your repository. Karibu has one
way to find a component and one family of underscore functions to act on it.

### The smaller gaps (9, 10, 12, 13)

**Loop latency (9).** In the same example project the greeting test took 111 ms and the probes
above 56–115 ms; the first test of the run took 0.9 s, most of it Vaadin warming up. For a bigger
sample, the Karibu-DSL test suite is almost entirely Karibu-Testing tests: 302 of them, exercising
every Vaadin component, ran in 5.3 seconds on Vaadin 25.2 — about 18 ms a test — and the same
suite took 5.5 seconds on Vaadin 25.3. A browser test costs seconds apiece; I reported 5–10
seconds back in 2017, which puts the same 302 tests somewhere between half an hour and an hour.
That is the difference between running the UI suite after every edit and running it before a
commit, and as part 1 argued, it decides whether the agent batches its changes.

**Reproducible environment (10).** Selenium Manager, used by default since Selenium 4.6 and able
to download browsers since 4.11, removed most of the driver pain. Not all of it: my own
[notes on running TestBench on Ubuntu](../testbench-ubuntu/) record years of browsers and drivers
that wouldn't talk to each other. And a browser test still needs the application built, started
and reachable. Karibu is a `testImplementation` line.

**Version legibility (12).** Selenium's corpus is the cleanest drift specimen in the post. Selenium
4 removed the `findElementByXPath()` family in favour of `findElement(By.xpath(…))`,
`implicitlyWait(10, TimeUnit.SECONDS)` became a `Duration`, and Selenium Manager made
`System.setProperty("webdriver.chrome.driver", …)` unnecessary — and my Ubuntu post above still
uses that last one, so I am part of the problem. Karibu's corpus is thin, but its API has been
stable since 2020, so the little a model knows is still current. Its one trap is naming: the
artifact is `karibu-testing-v24` and it also serves Vaadin 25. There is no `-v25`, and an agent
reasoning from version numbers will go looking for one. Writing this row turned it up; it is now
[issue #216](https://github.com/mvysny/karibu-testing/issues/216).

**Knowable on demand (13).** Karibu's API is small and documented in KDoc plus one README.
Selenium's API is small too; as row 11 showed, the knowledge it's missing is Vaadin's DOM.

### Inner loop, outer gate

The split follows from row 2. Karibu is the inner loop: hundreds of tests, run on every change.
Browser tests are the outer gate: a handful, covering exactly the list from row 2 — the production
bundle builds and the page loads, the key views don't overflow, the JavaScript components
initialise, and one happy path goes end to end over real HTTP.

**Small in number, not lower in priority.** My 2017 post on
[browserless web testing](../browserless-web-testing/) drew this as a test pyramid, which is
right about the counts and misleading about importance. Treat browser tests as a distant second
and they rot: they are slow and flaky, and nobody notices when one gets `@Disabled`. Then the one
failure class your fast oracle cannot see is also the untested one — property 2 failing through
neglect rather than by design. An agent will not catch it, because the agent only ever runs the
inner loop. So make the outer gate a required CI check the agent cannot skip, and keep its list of
what it covers written down next to it, because that list is row 2's blind spot, named.

On the table, Karibu leads on eight rows, ties on one and trails on one. With equal rows that
would be a sweep. The rows are not equal: row 2 decides whether the other nine are worth
anything, and it is the only one a faster oracle cannot buy back.

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
