---
layout: post
title: The State of Java and Kotlin Language Servers
date: 2026-09-15 12:45:28 +0300
---

> **Working document.** Verified facts are marked `[verified]` with a date; things I believe but
> have not run are marked `[unverified]`. The measurement section is now filled in — run against
> `jdbi-orm` from a correctly-rooted session on a built project, then repeated against
> `vaadin-boot`, whose different shape overturned two of the first run's conclusions. Findings
> from the second repo are marked `[verified 2026-09-15, vaadin-boot]`. See *How to verify this
> yourself* at the end if you want to repeat it on a repo of your own.
>
> **Retracted since the first draft:** "Call Hierarchy does not work" — it does; it is blind to
> test source sets, and `jdbi-orm`'s Kotlin was *all* under `src/test`. See
> *Call Hierarchy: not broken, blind*.

An agent editing a codebase has two ways to answer "what else touches this?": `grep`, or a
language server. The difference is not convenience. `grep` finds text and cannot tell you what
it missed; a language server finds *symbols* and knows the difference between a call and a
comment. Which one your agent gets is mostly decided by which language you picked, and — as it
turns out — by something much dumber than that.

I set out to measure whether Kotlin's server is good enough to trust. It is, at the thing I most
doubted. The uncomfortable answers were elsewhere: in what each server says when asked about code
it cannot see, and — the lesson that cost me the most — in how much of what I thought I had
measured was really a property of the one repository I measured it on.

This is a snapshot as of **September 2026**. Every number here will rot; the methodology at the
bottom is the part meant to outlive it. So is the discipline of running it twice: the second
repository retracted two findings from the first, and neither of them looked shaky at the time.

## The landscape

There are three things people mean by "Kotlin language server", and they are not
interchangeable.

**`Kotlin/kotlin-lsp` — JetBrains' free standalone server.** `[verified 2026-09-15]` The
repository carries an Alpha badge and a *Project Status* section reading "⚠️ The project is
currently in the Alpha state ⚠️". It ships both a VS Code extension and a standalone
`kotlin-lsp` CLI for any LSP-capable editor. This is what a terminal agent gets today.

**The IntelliJ IDEA LSP extension.** `[verified 2026-09-15, docs]` Announced August 2026:
IntelliJ's own Java *and* Kotlin intelligence exposed over LSP, with refactorings, Gradle/Maven/
Bazel support, DAP debugging, and an explicit mention of "agentic, terminal-based workflows". Two
catches: it targets VS Code and its forks, and it is free only during the preview — afterwards it
requires an IntelliJ IDEA Ultimate subscription. So "Kotlin has an official LSP now" is true and
is not the same claim as "Kotlin has a free LSP an agent can rely on".

**`fwcd/kotlin-language-server` — the community server.** The one that was under-maintained for
years and is what most older writing on this topic means. `[unverified]` — I did not check its
current state, and should before publishing.

On the Java side there is **Eclipse JDT LS**, which is what VS Code's Java extension runs, and
which has a decade of maturity behind it.

### What is actually installed here

`[verified 2026-09-15]` Worth stating because it is easy to test the wrong binary. The machine
had JetBrains' server, not the community one:

```
name             kotlin-server
version          2026.3
versionSuffix    EAP
buildNumber      263.4702.0
productCode      ILS
minRequiredJavaVersion  25
```

with a bundled JetBrains Runtime (`jbr/`) and `intellij.*` platform jars. The community server
is a plain Java app with none of those. If you are benchmarking, check `product-info.json`
before you believe anything.

The Java side of every number below is **Eclipse JDT LS `1.61.0.202609031315`**, launcher
`org.eclipse.equinox.launcher_1.8.0.v20260804-1928`, resolving the JDK as Java 25.0.4.1.

One more thing worth knowing before you read any figure: neither of these is cheap. At rest,
after indexing one small single-module repo, `kotlin-lsp` held **2658 MB** RSS (plus a second
1849 MB instance and a 141 MB launcher) against jdtls' **1870 MB**.

## Supported features, as published

`[verified 2026-09-15]` From `Kotlin/kotlin-lsp`'s README, verbatim list:

- Up-to-date Kotlin language versions support
- IntelliJ-powered code completion
- IntelliJ-powered diagnostics and quick fixes for Kotlin and kotlinx libraries
- Build system support for JVM projects: Gradle, Maven, experimental Android Gradle Plugin
  (Kotlin Multiplatform "coming in future releases")
- Semantic highlighting
- Organize imports
- **Rename refactoring**
- Code formatting
- Documentation navigation and hover support
- **Call Hierarchy**
- Code Folding

Note what is absent: **find-references and go-to-definition are not on that list.** Rename is,
and call hierarchy is. That is an unusual combination, because rename is normally implemented
on top of reference search — so either the omission is a documentation gap or rename is doing
something narrower than it sounds. This was the question the whole post was built to answer.

Hold that list in your head, because the measurements invert it. The two features missing from
it are the two best things in the server. The one printed in the middle of it — **Call
Hierarchy** — is the one that comes with a condition the README does not mention, and that
condition is invisible on a repo whose Kotlin all lives in one source set.

## The trap that invalidated my first attempt

This is the part I most want written down, because it cost me a wrong conclusion that I
published to a draft and had to retract.

`[verified 2026-09-15]` **The Claude Code harness roots the language server at the session's
working directory.** If you start a session in repo A and query a file in repo B, the server
does not import B. It analyses the file standalone, with no workspace model.

What that looks like from the agent's side is the dangerous part, because the two servers
degrade differently:

| | Behaviour with no workspace model |
|---|---|
| Eclipse JDT LS | `EntityMeta.java is a non-project file, only syntax errors are reported` |
| `kotlin-lsp` | `Found 1 reference` (the declaration) · `No incoming calls found (nothing calls this function)` |

Both are equally blind. One says so. The other returns a confident, well-formed, wrong answer —
and the natural next action on "nothing calls this function" is to delete the function.

I took the Kotlin answers at face value and concluded its reference search was broken. It may
well be limited, but that run proved nothing, and here is the check that exposed it:
`goToDefinition` also failed on a Kotlin extension property **defined in another file of the
same source set**. That is not a find-references limitation. That is no project at all.

A postscript that only the rerun could supply: of those two kotlin-lsp answers, `Found 1
reference` really was the broken root talking — rooted properly, that query returns 7. `No
incoming calls found` was not. It says that under a good root too, for every symbol in this
repository. I had attributed a genuine limitation to my own setup error, which is the other way
this mistake goes.

And then — `[verified 2026-09-15, vaadin-boot]` — a second repository showed that "every symbol
in this repository" was carrying far more weight than I gave it. The limitation is real, but it
is not the one I named. See *Call Hierarchy: not broken, blind*. Two setup artifacts in a row,
at two different scopes: first the session's root, then the repository's own shape.

**Diagnosing rootedness before trusting any result:**

```bash
# What projects has jdtls actually imported?
for d in ~/.cache/jdtls/jdtls-*; do
  echo "$d -> $(ls $d/.metadata/.plugins/org.eclipse.core.resources/.projects/ 2>/dev/null | tr '\n' ',')"
done
```

A workspace containing only `jdt.ls-java-project` is the single-file fallback — nothing was
imported. A healthy one lists the actual Gradle/Maven module names. `[verified]` On this machine
a correctly-imported multi-module workspace listed 13 modules for one repo and 17 for another,
so jdtls imports Gradle fine when given the root.

`[verified 2026-09-15]` A detail that bit me while setting up the rerun: **the workspace hash is
derived from the path, so a git worktree is a different workspace from its own main checkout.**
Running the measurements from `jdbi-orm/.claude/worktrees/lsp-tests` produced a brand new
`jdtls-16fae7d5… -> jdbi-orm,lsp-tests` alongside the main checkout's
`jdtls-7090b22b… -> jdbi-orm,jdbi-orm-jdbi-orm`. Both are healthy — two module names each, not
`jdt.ls-java-project` — but the worktree re-imports Gradle from scratch and pays for it.

**And the verdict on the whole retraction:** with the session rooted at the repo, the canary
passes.

```
goToDefinition  Person.kt 68:96  (.withZeroNanos)
→ Defined in .../AbstractMappingTests.kt:272:13
```

That is the exact query, on the exact symbol, that failed before. The trap was the root. Nothing
was wrong with the server.

Two dead ends, so nobody repeats them: `[verified 2026-09-15]` nuking `~/.cache/jdtls/<ws>` does
not help, because the cache was never the problem. And subagents cannot be used to work around
it — they inherit the parent's working directory, *and* the LSP tool is not exposed to them at
all (five `ToolSearch` variants returned nothing).

`[unverified]` A subagent also reported receiving a `Tool loaded.` notice immediately after a
`ToolSearch` that had returned `No matching deferred tools found`, twice, with no schema
attached. Possibly a harness bug; worth reproducing before claiming it.

## Cold start is a race, and it does not always lose loudly

`[verified]` I had previously recorded the honest version of this failure: a query issued
immediately after the first one dies with `Cannot send notification to LSP server
'plugin:kotlin-lsp:kotlin-lsp': server is starting`. That is fine. That is a refusal.

`[verified 2026-09-15]` On the measurement run it did something else. The first two queries of
the session, fired while `intellij-server` was pegged at 298% CPU indexing, came back as:

```
goToDefinition Person.kt 68:96 → "No definition found. This may occur if the cursor is not on a
                                  symbol, or if the definition is in an external library…"
hover          Person.kt 68:96 → "No hover information available…"
```

Two minutes later the identical query returned the correct answer. So **cold start has two
failure modes and one of them is a silent wrong answer wearing a plausible explanation.** If your
agent queries once during indexing and believes what it gets, it has been lied to in a way it
cannot detect. Never trust an empty result from a first query.

## What the servers actually do

`[verified 2026-09-15]` All of the below was measured in one session on `jdbi-orm` — 23 Kotlin
files (**all under `src/test`** — remember that detail, it turns out to decide a whole section),
50 Java files, a single Gradle module, so the Kotlin and the Java sit in the same compilation
unit and the cross-language boundary is real rather than staged. Session rooted at the repo,
`./gradlew testClasses` green first, then `./gradlew downloadSources`. Ground truth established
by `grep` before each query, never after.

`[verified 2026-09-15, vaadin-boot]` Everything was then re-run on a second subject chosen to
vary the things `jdbi-orm` held fixed: [`vaadin-boot`](https://github.com/mvysny/vaadin-boot) —
16 Kotlin files, 28 Java files, **seven Gradle modules**, with the Kotlin confined to two modules
of its own. So the cross-language boundary here is a *project dependency* rather than a shared
compilation unit, and Kotlin appears in both `src/main` and `src/test`. It also has a property I
did not go looking for and could not have designed better: the project deliberately ships **two
classes with the identical fully-qualified name**, `com.github.mvysny.vaadinboot.VaadinBoot`, one
in the Jetty module and one in the Tomcat module, in modules that do not depend on each other.
That accident produced the sharpest result of either run.

### kotlin-lsp: reference search is the best thing in it

The feature that is *not* on the published list is excellent. Four reference queries, four exact
answers:

| Query | Result | Ground truth |
|---|---|---|
| `findReferences` `Person.withZeroNanos()` | **7 refs / 3 files** | exact |
| `findReferences` `Person.age` | **57 refs / 5 files** | exact |
| `findReferences` `Entity.save()` — *a Java symbol*, asked from Kotlin | **111 refs / 7 files** | exact |
| `findReferences` `EntityMeta` — *a Java class*, asked from Kotlin | **57 refs / 10 files** | exact (two entries duplicated) |

"Exact" is doing real work in that table. `grep -w age` returns 41 lines in `DaoTest.kt` alone;
the server returned 30 of them and dropped precisely eleven — four `Person2(…, age = …)`, a
different class that happens to have a property of the same name, and seven SQL string literals
like `"age > :age"` and `"age DESC"`. On one line it kept the named argument in
`Person(name = "Zaphod", age = 42)` while skipping the `"age":42` inside the JSON string literal
sitting next to it. On `withZeroNanos` it returned the six calls to the *function* and excluded
`DaoTest.kt:239` and `:247`, which use an unrelated extension property of the same name.

This is the thing grep structurally cannot do, and it is the reason to wire a language server
into an agent at all.

Everything else in the navigation family works too, and works **across the language boundary**:
`goToDefinition` jumps from Kotlin into `Entity.java`, `Dao.java` and `EntityMeta.java` in the
same module; `goToImplementation` on the Java interface `Entity` returned all **9** implementors
— six Kotlin, three Java, including one reached transitively through a Java sub-interface.
`hover` is as good as before and the nullability tell still holds (`data class Person(id: Long?, …)`
on a built project). `documentSymbol` remains flawless, with one wrinkle worth knowing: its line
numbers point at the start of the declaration *including* the KDoc and annotations, not at the
identifier. `[verified 2026-09-15, vaadin-boot]` That wrinkle is not a kotlin-lsp quirk — jdtls
does the same thing, reporting `WebServer (Interface) - Line 5` for an interface declared on line
39, line 5 being where its javadoc block opens. Do not feed a `documentSymbol` line number
straight into a positional query on either server.

`[verified 2026-09-15, vaadin-boot]` On the multi-module repo it holds up across a *module*
boundary too, and then does something I did not expect it to survive. Asked for references to the
Jetty `VaadinBoot` from a Kotlin file, it returned **25 refs across 8 files — exactly ground
truth**, spanning four modules and both languages, and containing **not one reference to the
Tomcat class of the same fully-qualified name**. The same discrimination shows up in navigation:

```
goToDefinition  testapp-kotlin/…/Bootstrap.kt         75:9 → vaadin-boot/…/VaadinBoot.java:53:12
goToDefinition  testapp-kotlin-tomcat/…/Bootstrap.kt  75:9 → vaadin-boot-tomcat/…/VaadinBoot.java:20:12
```

Identical source line, identical symbol, identical FQN — resolved to different files according to
which module's dependencies the *calling file* sits behind. `hover` at the first of those renders
the Java javadoc, the Java signature and a Kotlin-ized view of the class, and the platform-type
tell survives the crossing: `VaadinBootBase<VaadinBoot?>`.

Two gaps. `goToDefinition` does not resolve into external dependencies — but `hover` does, with
full javadoc and a path into the sources jar, so the information is reachable and the gap is
visible rather than silent. And `workspaceSymbol` is **Kotlin-only**: searching `EntityMeta`
returned only the Kotlin `EntityMetaTest`, silently omitting the Java class of that exact name
that the same server will happily `goToDefinition` into.

`[verified 2026-09-15, vaadin-boot]` That second gap is worse than "Kotlin-only" makes it sound.
Searching `VaadinBoot` on the multi-module repo returned **two results, both of them lowercase
`vaadinBoot` local properties**, and omitted all four Java *classes* of that exact name — one of
which is the declaration the same server had resolved `goToDefinition` into a minute earlier. It
is not merely filtering by language; the things it does return are the least useful matches
available. jdtls, asked the same query, returned all six Java symbols, correctly separated by
package and module.

### Call Hierarchy: not broken, blind

`[verified 2026-09-15]` This is the finding I did not expect, and then the finding I got wrong.
`prepareCallHierarchy` resolves the item — correctly, for both expression-body and block-body
functions. Then:

```
incomingCalls  Person.kt 68:9  (withZeroNanos)
→ No incoming calls found (nothing calls this function)
```

At that same position, one query earlier, `findReferences` listed all six call sites. It is not a
rootedness artifact and it is not an indexing race. On `jdbi-orm` it is empty for every symbol I
tried, and `outgoingCalls` matches it: `PersonDao.findAll2()` is reported to call nothing, and its
entire body is `jdbi().withHandle { handle.createQuery(…).map(rowMapper).list() }`.

I concluded that Call Hierarchy does not work. That conclusion was wrong, and the second
repository is what broke it.

`[verified 2026-09-15, vaadin-boot]` On `vaadin-boot`, Call Hierarchy works — some of the time,
with a rule behind it:

| Query | Edge crosses | Result |
|---|---|---|
| `incomingCalls` `Counter.incrementCounter` | main ← main, same file | **1 caller, correct** |
| `incomingCalls` `Counter` | main ← main, **different file** | **1 caller, correct** |
| `incomingCalls` `wget` | test ← test | **empty** — 2 real callers |
| `incomingCalls` `Bootstrap.contextInitialized` | main ← **test** | **empty** — 1 real caller |
| `outgoingCalls` `JettyTest.testAppIsUp` | test → main *and* test | **both `src/main` callees, `src/test` callee dropped** |

The first row also disposes of a smaller suspicion: the caller it found was
`Counter.onAttach`, and the call sits inside a lambda passed to `scheduleWithFixedDelay`. It named
the enclosing method correctly, the same thing jdtls does well.

**Every call-hierarchy edge whose far end lives in a test source set is silently dropped.** The
last row is the cleanest demonstration, because one query contains both outcomes: asked what
`testAppIsUp()` calls, the server returned the two `src/main` properties it touches and omitted
`wget(...)` on line 44, which is three lines below them and declared in `src/test`.

It is not an indexing gap. `findReferences` at the *identical position* on `wget` returns all
three references, both call sites included. The index knows. Call Hierarchy declines to look.

Which retro-explains the entire `jdbi-orm` result. That repo's 23 Kotlin files were **all under
`src/test`** — so every Kotlin call-hierarchy query I ran had a test-source far end, and every
one came back empty. I had a sample of one source set and read it as a sample of the feature. The
`outgoingCalls` example goes the same way once you look at what `findAll2()` actually calls:
`jdbi()`, `withHandle`, `createQuery`, `map`, `list` — every one of them an *external library*
symbol, and external callees are omitted too, as `vaadin-boot` confirms separately
(`super.onAttach`, `UI.getCurrent` and `scheduleWithFixedDelay` are all missing from an otherwise
correct result). "Reported to call nothing" was two narrow rules wearing a trenchcoat.

So the README's omissions are a documentation gap, and its inclusion of Call Hierarchy is
defensible after all — the feature exists and works. What the README does not say is that it
cannot see your tests, which for an agent is close to the worst possible half to lose: "who calls
this?" is most often asked precisely when deciding whether something is dead code, and the test
suite is where the evidence that it is not tends to live.

### jdtls: the Java control I never actually ran

On Java, jdtls earns its reputation. Hover gives full javadoc for project, dependency and JDK
symbols; `goToDefinition` and `workspaceSymbol` behave; and — the one place it beats kotlin-lsp
outright — **its call hierarchy works**. `incomingCalls` on `EntityMeta.getDatabaseTableName()`
returned all 15 callers and correctly named the enclosing lambda (`withHandle(Handle) : Integer`)
rather than the method containing it.

`[verified 2026-09-15, vaadin-boot]` And it works on the axis kotlin-lsp fails: `incomingCalls`
on the `VaadinBoot()` constructor returned four callers, **three of them in `src/test`**, across
two modules. Whatever makes kotlin-lsp's call hierarchy skip test sources, jdtls does not share
it. `goToImplementation` is just as solid — asked for implementors of the `WebServer` interface it
returned all **5**, spanning three modules and including two reached transitively through a nested
subclass in a test source set.

That it cannot read Kotlin is not a defect. It is a Java language server; nobody promised
otherwise, and `Person2 cannot be resolved to a type` in a Java test file that references a Kotlin
class is the correct thing for it to say. What I wanted to know was what it does with the half of
the repo it cannot see — and the answer is that it depends on the operation, in a way no caller
can predict.

Six `incomingCalls` queries, one clean rule:

| Callers of the Java symbol | Result |
|---|---|
| Java only — `getDatabaseTableName` (15), `isFieldPersisted` (2), `save(boolean)` (1) | **correct** |
| Java **and** Kotlin — `EntityMeta.of` (9+17), `getProperty` (4+9) | **`Internal error`** |
| Kotlin only — `Entity.save()` (0+127), `DaoOfAny.findAll()` (0+58) | **"nothing calls this function"** |

The middle row is a crash, and a crash is *fine* — it is loud, reproducible, and an agent that
sees `LSP request 'callHierarchy/incomingCalls' failed … Internal error` falls back to grep.

`[verified 2026-09-15, vaadin-boot]` **The middle row did not reproduce, and that is bad news.**
The same shape on `vaadin-boot` — `VaadinBootBase.run()`, two Java callers and two Kotlin ones —
did not crash. It returned the two Java callers, cleanly formatted, with no error and no
indication that half the answer was missing. So "Java-and-Kotlin callers produce a loud failure"
is not a property of jdtls; it is a property of `jdbi-orm`. The plausible mechanism is the one
thing the two repos differ on here: in `jdbi-orm` the Kotlin and Java share a module, so jdtls
must chew on a source root full of files it cannot parse; in `vaadin-boot` the Kotlin lives in
modules of its own, which jdtls imports and then finds nothing in. Nothing to choke on, nothing
to report. The conclusion below about crashes being trustworthy still stands — what I can no
longer say is which queries will give you one.

The bottom row is the problem. `Entity.save()` is a documented public API method with **127 call
sites across six files**, and jdtls will tell you nothing calls it. Same shape in
`findReferences` (9 refs, seven of them javadoc `{@link}`s inside the declaring file itself) and
in `goToImplementation` (3 of 9 implementors). No warning, no partial-result flag, no difference
in wording from a genuinely unused symbol.

### jdtls also over-reports, which nothing else here does

`[verified 2026-09-15, vaadin-boot]` Every failure catalogued so far is a missing result. This one
is the opposite, and I had no category for it.

`vaadin-boot` ships two classes named `com.github.mvysny.vaadinboot.VaadinBoot` — same simple
name, same package, one in the Jetty module and one in the Tomcat module, and neither module
depends on the other. This is deliberate: an app picks one container artifact, and putting both on
the classpath is a documented mistake. Asked for references to the Jetty one, jdtls answered:

```
findReferences  vaadin-boot/…/VaadinBoot.java 21:14
→ Found 28 references across 10 files
```

Twenty of those are right. **Eight belong to the other class** — `testapp-tomcat/Main.java`,
`TomcatTest.java`, the declaration line of `vaadin-boot-tomcat/VaadinBoot.java` itself, and a
`{@link}` in `TomcatWebServer`. And the five Kotlin references are missing, as expected. So the
answer is wrong in both directions at once: it under-reports across the language boundary and
over-reports across the module boundary, and the two errors partially cancel into a plausible
number.

The sharp part is that the same server does not make this mistake elsewhere. `goToDefinition`
from `testapp/Main.java` and from `testapp-tomcat/Main.java` — identical source lines — resolve to
the correct module's class each time. `incomingCalls` on the constructor correctly excludes the
Tomcat twin. `workspaceSymbol` lists all three `VaadinBoot` classes as distinct entries with their
packages. Only `findReferences` flattens them, which suggests it is keyed by name against a global
index while the other operations resolve against the project's real classpath.

For an agent, this is a worse shape than an empty list. An empty list at least invites suspicion.
A list of 28 hits spanning ten files, with correct line and column numbers, every entry pointing
at real source text containing the real identifier, reads as the authoritative answer — and acting
on it means editing a module that does not use the symbol you asked about.

### The comparison that matters

Same repo, same module, same minute, same symbol — `Entity.save()`, declared in Java, called from
Kotlin:

| | `findReferences` | `incomingCalls` | `goToImplementation` on `Entity` |
|---|---|---|---|
| **kotlin-lsp** | **111** refs / 7 files ✓ | "nothing calls this function" ✗ | **9** impls, both languages ✓ |
| **jdtls** | **9** refs / 1 file ✗ | "nothing calls this function" ✗ | **3** impls, Java only ✗ |
| ground truth | 9 Java + ~102 Kotlin | 127 `.save()` sites | 9 |

The uncomfortable part is not that jdtls is Java-only. It is that on a mixed module the
*Kotlin* server is the better **Java** reference engine, and that the bottom-left cell and the
middle column are indistinguishable to the caller — an empty list and a wrong empty list look
exactly the same.

`[verified 2026-09-15, vaadin-boot]` The second repo puts the same question to both servers, and
the margin is wider. Symbol: the Jetty `VaadinBoot`, declared in Java, used from Java and Kotlin
across four modules, with an identically-named twin in a fifth.

| | `findReferences` on `VaadinBoot` |
|---|---|
| **kotlin-lsp**, asked from Kotlin | **25** refs / 8 files — exact, both languages, no twin ✓ |
| **jdtls**, asked from Java | **28** refs / 10 files — 20 right, 8 from the twin, 5 Kotlin missing ✗ |
| ground truth | 20 Java + 5 Kotlin = 25 |

Twice now, on two repositories that share almost nothing structurally, the Kotlin server has
given the better answer about a Java symbol. That is no longer a curiosity about one codebase.
If your repo has any Kotlin in it at all, the Kotlin server is the one to ask about your Java —
which is close to the opposite of the advice anyone would give from the feature lists alone.

### One honest caveat about reference search

`findReferences` on `Person.save(Boolean)` — an override — returns 1: the declaration. That is
defensible, because no call site in the repo names that overload. But the naive reading, "nothing
uses this override, delete it", is wrong: 127 `.save()` calls dispatch to it at runtime through
`Entity.save()`. Reference search answers a syntactic question. An agent deciding whether a method
is dead has to ask about the interface method too, and neither server volunteers that.

## How to verify this yourself

*This section is written to be handed to an agent. It is the deliverable of this post.*

### Ground rules

1. **Run the session from the repository root.** `cd ~/work/my/<repo> && claude`. Not a
   subagent. Not a session rooted elsewhere. This is the whole trap.
2. **Establish ground truth with `grep` first, then ask the LSP.** Never the other way round —
   otherwise you are calibrating your expectations to the tool you are testing. Exclude build
   output: `build/` obviously, but also `bin/`, which jdtls creates in every module it imports
   and fills with *copies of your Kotlin sources*. Grepping a repo jdtls has touched will
   otherwise double-count every Kotlin call site you are trying to count.
3. **Build the project first** so dependencies resolve, then restart the language server, so
   results are not unresolved-project artifacts.
4. **Throw away your first two queries.** They are cold-start noise, and — see above — they can
   come back as plausible empty answers rather than errors. Wait until the server process drops
   off the CPU, then re-run them.
5. **On a mixed-language repo, ask both servers the same question.** Half the findings here came
   from putting one server's answer next to the other's on one symbol. Either alone looks
   authoritative.
6. **Report raw output verbatim.** No interpretation in the same step as measurement.
7. **Verify column positions with `awk`,** not by eye. I wasted a cycle querying character 13 of
   the wrong line and briefly believed a false negative:
   ```bash
   awk 'NR==19{for(i=1;i<=30;i++) printf "%d:%s ", i, substr($0,i,1); print ""}' File.kt
   ```
8. **Vary the source set on purpose.** For every symbol you test, know whether the *far end* of
   the relationship — the caller, the callee, the implementor — sits in `src/main` or `src/test`,
   and test both. This is the rule I did not have, and not having it cost me a whole section:
   `jdbi-orm`'s Kotlin was entirely under `src/test`, so a limitation scoped to test sources
   looked exactly like a feature that was broken outright.
9. **Run the matrix on a second repository with a different shape before you believe any of it.**
   Single-module vs. multi-module, languages mixed in one module vs. split across modules, Kotlin
   in `src/main` vs. only in `src/test`. Two of this post's conclusions survived the first repo
   and died on the second, and neither looked fragile at the time. One repository measures the
   repository at least as much as it measures the server.

### Pre-flight: prove the workspace is rooted

Before any measurement, confirm the server imported the project — see the `~/.cache/jdtls` loop
above for Java. For Kotlin, the cheap proof is a cross-file `goToDefinition`: pick a symbol
defined in file A and used in file B, and jump from B to A. If that fails, **stop** — every
subsequent result is meaningless.

On a multi-module build, check the *count* as well as the names: the loop should list every
module in `settings.gradle.kts`, plus a root entry. `vaadin-boot`'s seven modules came back as
eight entries including the Kotlin-only ones, which is what a healthy import of a polyglot Gradle
build looks like — jdtls imports Kotlin modules as projects even though it cannot read a line
inside them.

**Then run the source-set canary, which is new and which I now consider mandatory.** Pick a
function in `src/main` that is called only from `src/test`, and ask for its `incomingCalls`. If
the answer is empty while `findReferences` at the identical position lists the call sites, the
server's call hierarchy cannot see your tests, and every "nothing calls this" you collect for the
rest of the session means "nothing in `src/main` calls this". kotlin-lsp fails this canary; jdtls
passes it.

### The matrix

For each operation, record: result, correct?, and how it failed if it did (silent wrong answer
vs. explicit refusal — that distinction is the most interesting output).

| Operation | Test | Correct answer looks like |
|---|---|---|
| `hover` | local symbol; dependency symbol; JDK symbol | KDoc/javadoc renders |
| `documentSymbol` | any file | full nested structure |
| `goToDefinition` | same file | jumps |
| `goToDefinition` | **cross-file, same module** | jumps — *rootedness canary* |
| `goToDefinition` | **Kotlin → Java, same module** | jumps |
| `goToDefinition` | **Kotlin → Java, across a module dependency** | jumps |
| `goToDefinition` | ***two classes sharing an FQN in unrelated modules***, from each side | each resolves to its own module's class |
| `goToDefinition` | external dependency | jumps, or documented as unsupported |
| `findReferences` | symbol used in ≥3 files | all of them, not just the declaration |
| `findReferences` | **a symbol whose name also appears in strings / on a sibling class** | the real ones only — this is where it beats grep |
| `findReferences` | ***a symbol with an identically-named twin in another module*** | the twin's call sites absent — watch for over-reporting, not just gaps |
| `workspaceSymbol` | a known class name, **in each language** | found |
| `prepareCallHierarchy` | expression-body fun; block-body fun | resolves both |
| `incomingCalls` | function with ≥5 known callers | all callers |
| `incomingCalls` | **the same, with callers in the other language only** | all callers, or a refusal |
| `incomingCalls` | ***a `src/main` function called only from `src/test`*** | all callers — *source-set canary* |
| `outgoingCalls` | function calling ≥3 things | all callees |
| `outgoingCalls` | ***a function calling both a `src/main` and a `src/test` symbol*** | both — one query, both outcomes |
| `goToImplementation` | interface with ≥2 impls **in both languages** | all impls |
| `goToImplementation` | ***impls spread across modules, incl. a test source set*** | all impls |
| rename | a public method used cross-file | every call site updated atomically |

The rows in bold are the ones the `jdbi-orm` run added; the *bold italic* ones came from
`vaadin-boot`, and between them they produced every finding that overturned something. A matrix
that only asks easy questions gets a clean sheet from a server that is quietly half-blind — and a
matrix run on one repository only asks the questions that repository happens to contain.

Rename is now the only cell still empty. `[verified 2026-09-15]` The LSP tool in Claude Code
exposes nine operations — `goToDefinition`, `findReferences`, `hover`, `documentSymbol`,
`workspaceSymbol`, `goToImplementation`, `prepareCallHierarchy`, `incomingCalls`,
`outgoingCalls` — and rename is not among them, so a terminal agent cannot reach it at all. It
needs a different client: the VS Code extension, or an LSP client driven by hand.

It no longer settles the docs question, though — find-references turned out to work, so the
omission was a docs gap either way. What rename would settle now is narrower and less urgent:
whether it is reference-search-complete, given that reference search itself is sound.

### Suggested subjects

Pick repos that isolate one variable each:

- **Kotlin + Java in one Gradle module** — does the cross-language boundary resolve?
  (`jdbi-orm`: 23 Kotlin / 50 Java, all Kotlin under `src/test`) — the first one measured above
- **Kotlin and Java in *separate* modules of one multi-module build** — is the boundary still a
  boundary when it is a project dependency? (`vaadin-boot`: 16 Kotlin / 28 Java, seven modules,
  Kotlin in both `src/main` and `src/test`) — the second one measured above, and the one that
  produced the source-set canary and the over-reporting finding
- **A repo that ships two classes with the same FQN in unrelated modules** — the sharpest
  disambiguation test there is, and rarer than it should be. `vaadin-boot` has one by design
  (its Jetty and Tomcat artifacts both publish `…vaadinboot.VaadinBoot`); if you maintain
  something with an `-api` / `-impl` split or a shaded twin, you may already have one.
- **Large pure-Kotlin multi-module** — does it scale? (`vok`: ~576 Kotlin files)
- **Maven rather than Gradle** — the README claims both; verify.
- **A repo with an already-healthy jdtls workspace** — as the Java control.

### Concrete first probes

In `jdbi-orm` at `266e843`, with the project built and ground truth established by `grep`. These
are the verified values, not expectations — if you get something else, suspect your setup before
you suspect the server:

```
goToDefinition  Person.kt 68:96   (.withZeroNanos) → AbstractMappingTests.kt:272:13   ✓ rootedness canary
goToDefinition  Person.kt 30:5    (Entity)         → Entity.java:51:18                ✓ cross-language
findReferences  Person.kt 68:9    (withZeroNanos)  → 7 refs / 3 files                 ✓ exact
findReferences  Person.kt 19:13   (age)            → 57 refs / 5 files                ✓ exact
incomingCalls   Person.kt 68:9    (withZeroNanos)  → EMPTY — WRONG. Real callers are
                                                     DaoTest.kt:196,197,222,223 and
                                                     AbstractMappingTests.kt:46 (twice)
                                                     — all of them under src/test, which is
                                                     the actual reason; see the canary
findReferences  EntityMeta.java 38:20  via jdtls   → 37 refs / 7 files, Java only
                 (same symbol via kotlin-lsp, from a Kotlin file) → 57 refs / 10 files, both
```

An earlier draft of this post listed the `withZeroNanos` callers as `DaoTest.kt:165,166,191,192`.
Those line numbers were stale. Which is its own small lesson about hand-maintained ground truth,
and the reason step 2 says to re-run the `grep` rather than trust the table.

`[verified 2026-09-15, vaadin-boot]` And in `vaadin-boot` at `86a7988`, built with
`./gradlew testClasses`. These are the probes that vary source set and module, so they are the
ones worth running first on a repo of your own:

```
goToDefinition  testapp-kotlin/…/Bootstrap.kt        75:9  → vaadin-boot/…/VaadinBoot.java:53:12
goToDefinition  testapp-kotlin-tomcat/…/Bootstrap.kt 75:9  → vaadin-boot-tomcat/…/VaadinBoot.java:20:12
                 ↑ same line, same FQN, different module — both servers get this right
findReferences  testapp-kotlin/…/JettyTest.kt 23:29 (VaadinBoot, via kotlin-lsp)
                                                           → 25 refs / 8 files  ✓ exact, both languages
findReferences  vaadin-boot/…/VaadinBoot.java 21:14 (via jdtls)
                                                           → 28 refs / 10 files ✗ 8 belong to the
                                                             Tomcat twin, 5 Kotlin refs missing
incomingCalls   testapp-kotlin/…/Counter.kt 13:7  (Counter)      → 1 caller, MainView.kt  ✓ main ← main
incomingCalls   testapp-kotlin/…/TestUtils.kt 9:5 (wget)         → EMPTY  ✗ source-set canary;
                                                                   findReferences at 9:5 finds
                                                                   JettyTest.kt:44,50
outgoingCalls   testapp-kotlin/…/JettyTest.kt 38:9 (testAppIsUp) → 2 of 3; the src/test callee
                                                                   wget() on line 44 is dropped
incomingCalls   common/…/VaadinBootBase.java 254:17 (run, via jdtls)
                                                           → 2 of 4 — the 2 Kotlin callers are
                                                             missing, silently. No Internal error.
workspaceSymbol "VaadinBoot" via kotlin-lsp → 2 lowercase properties, zero classes  ✗
                "VaadinBoot" via jdtls      → all 6 Java symbols, packages distinguished  ✓
```

## Open questions

Answered:

1. ~~Does `findReferences` work when properly rooted?~~ **Yes, and it is the best feature in the
   server** — four exact answers on `jdbi-orm`, and on `vaadin-boot` an exact 25/8 across four
   modules and two languages while correctly ignoring an identically-named class in a fifth.
2. ~~Is the omission of find-references and go-to-definition from the README a docs gap or
   real?~~ **A docs gap.** Both work. ~~The live problem is the opposite one: Call Hierarchy *is*
   on the list and returns empty in both directions.~~ **Retracted** — Call Hierarchy works; it
   is blind to test source sets, which on `jdbi-orm` was indistinguishable from not working. The
   README's real omission is that condition.
3. ~~Does the Kotlin→Java boundary resolve inside one module?~~ **Yes, in one direction.**
   kotlin-lsp reads Java — definitions, hover, references, implementations. jdtls does not read
   Kotlin, which is expected; what is not expected is that it reports the gap as an empty result.
4. ~~Does the Kotlin→Java boundary also resolve *across* modules?~~ **Yes, and precisely.**
   kotlin-lsp resolves a Kotlin call site into Java in a module its own module merely depends on,
   and picks correctly between two classes with the same fully-qualified name in sibling modules.
5. ~~How does jdtls compare, measured rather than assumed?~~ Measured above. Excellent on pure
   Java — hover, `goToImplementation`, and a call hierarchy that does read test sources. But
   `findReferences` merges classes that share an FQN across modules, which is the only
   *over*-reporting failure either server produced, and the most dangerous shape in the post.

Still open:

5. Does rename work, and is it reference-search-complete? Unreachable from a terminal agent —
   the Claude Code LSP tool exposes no rename operation.
6. Maven vs Gradle — any difference? Both subjects are Gradle, so neither run says anything
   about it.
7. Current state of `fwcd/kotlin-language-server`.
8. Does the paid IntelliJ LSP extension work outside VS Code, i.e. is it usable by a terminal
   agent at all?
9. Does any of this scale? One small single-module repo cost 2.6 GB of RSS and roughly two
   minutes of indexing; the seven-module one was cheaper, at 1.4 GB for jdtls against
   1.7 GB + 1.3 GB for two kotlin-lsp instances. A large pure-Kotlin multi-module tree is still
   the obvious next subject.
10. **Is kotlin-lsp's call hierarchy blind to test source sets specifically, or to any source set
    other than the one it considers primary?** Both my subjects have exactly two. A build with a
    third — an `integrationTest` set, or a custom source set — would separate "tests are special"
    from "only `main` is visible", and those imply very different workarounds.
11. **Does jdtls' FQN-merging in `findReferences` extend to shaded or relocated jars?** The
    `vaadin-boot` case is two source modules. A shaded dependency that relocates a package into
    a name a project source file also uses is the same collision with worse consequences, and is
    far more common than a deliberately duplicated class.
12. **Does kotlin-lsp's `workspaceSymbol` omit Java classes, or omit classes it did not index as
    Kotlin?** It returned lowercase properties over exact-name Java classes, which looks less like
    a language filter than like a different index being consulted than the one `goToDefinition`
    uses.

## The part that generalises

Now that the numbers are in, the finding that outlives them is not about Kotlin at all:
**when you wire a tool into an agent loop, how it fails matters as much as how well it works.**

A tool that degrades loudly is safe at any quality level — the agent detects the refusal, falls
back to `grep`, tells you. A tool that degrades silently is dangerous in proportion to how much
the agent trusts it, and an empty result is the worst possible shape for a silent failure,
because "no results" and "no answer" are indistinguishable to the caller while implying opposite
actions.

The runs bear that out with some symmetry. Over two servers and two repositories I collected
five distinct empty lists — kotlin-lsp's call hierarchy, which means *your callers are in a
source set I do not read*; jdtls' `incomingCalls` on a Kotlin-called method, which means *I
cannot read that language*; kotlin-lsp's `workspaceSymbol` on a Java class, which means the same
thing in mirror image; kotlin-lsp's `outgoingCalls` on a function whose callees are all in
libraries, which means *I only report project symbols*; and a cold-start `No definition found`,
which means *ask me again in two minutes*. Five different causes, one identical rendering, and in
every case the phrasing implies the one thing that is not true: that the server looked and there
was nothing there.

`No incoming calls found (nothing calls this function)` is the worst of them, because the
parenthetical is not a rendering of the result — it is an interpretation, supplied by the tool,
of a result the tool has no grounds to interpret. An agent that reads it has been handed a
conclusion, not data.

Exactly once did a server refuse out loud, and it was jdtls returning `Internal error` from
`callHierarchy/incomingCalls`. A crash. On the day's evidence it was the most trustworthy thing
either of them said — though the second repository showed that the very same query shape can
return a quiet half-answer instead, so you cannot rely on being told.

And the second repository added a failure mode I had not budgeted for, which is worse than any
empty list: **a wrong answer that is not empty.** jdtls' 28 references include eight belonging to
a different class, with correct file paths, correct line and column numbers, every one pointing at
real source text containing the real identifier. There is no cue. An empty list at least prompts
a second thought; a confident, well-formed, over-long list gets acted on. If I had to restate the
lesson to cover both runs: **a tool in an agent loop should be judged on what its wrong answers
look like, and the dangerous ones are the answers shaped exactly like right ones.**

Which is also the case for running the matrix twice. Everything I got wrong in the first draft, I
got wrong because one repository answered clearly and I mistook a clear answer for a general one.

I would take a reference search that refuses over one that returns an empty list.
