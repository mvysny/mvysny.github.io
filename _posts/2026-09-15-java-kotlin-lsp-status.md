---
layout: post
title: The State of Java and Kotlin Language Servers
date: 2026-09-15 12:45:28 +0300
---

> **Working document.** Verified facts are marked `[verified]` with a date; things I believe but
> have not run are marked `[unverified]`. Measurements were run against three repositories in turn:
> `jdbi-orm`, then `vaadin-boot` (findings marked `[verified 2026-09-15, vaadin-boot]`), then
> `vaadin-boot-example-maven` (`[verified 2026-09-15, maven]`). Each later subject retracted
> something from the earlier ones; those retractions are told once, in place, where the measurement
> that caused them sits. One measurement bypassed the harness to drive kotlin-lsp over stdio; it is
> marked `[verified 2026-09-15, maven, stdio]`.

An agent editing a codebase has two ways to answer "what else touches this?": `grep`, or a
language server. The difference is not convenience. `grep` finds text and cannot tell you what
it missed; a language server finds *symbols* and knows the difference between a call and a
comment. Which one your agent gets is mostly decided by which language you picked, and — as it
turns out — by something much dumber than that.

I set out to measure whether Kotlin's server is good enough to trust. It is, at the thing I most
doubted. The uncomfortable answers were elsewhere: in what each server says when asked about code
it cannot see, and — the lesson that cost me the most — in how much of what I thought I had
measured was really a property of the one repository I measured it on.

If you read nothing else here, read this: **start the session in the repository root, or every
answer you get is quietly worthless.** The language server is rooted at the session's working
directory, you cannot move it once the session is running, and when it is rooted wrong one of the
two servers does not tell you — it just answers wrong. That is the whole of *The trap* below, and
it cost me a published draft.

This is a snapshot as of **September 2026**. Every number here will rot; the methodology at the
bottom is the part meant to outlive it.

## What is under test

`[verified 2026-09-15]` **`Kotlin/kotlin-lsp`, JetBrains' free standalone server.** The repository
carries an Alpha badge and a *Project Status* section reading "⚠️ The project is currently in the
Alpha state ⚠️". It ships a VS Code extension and a standalone `kotlin-lsp` CLI for any LSP-capable
editor. This is what a terminal agent gets today, and it is the only Kotlin server this post
measures. Two other things exist and are out of scope here: the community
`fwcd/kotlin-language-server`, which most older writing on this topic means, and the IntelliJ IDEA
LSP extension announced in August 2026, which targets VS Code and its forks and needs an Ultimate
subscription once the preview ends. Neither is what is installed on this machine.

On the Java side, **Eclipse JDT LS** — what VS Code's Java extension runs, with a decade of
maturity behind it.

`[verified 2026-09-15]` Worth stating because it is easy to benchmark the wrong binary. The machine
has JetBrains' server, not the community one:

```
name             kotlin-server
version          2026.3
versionSuffix    EAP
buildNumber      263.4702.0
productCode      ILS
minRequiredJavaVersion  25
```

with a bundled JetBrains Runtime (`jbr/`) and `intellij.*` platform jars. The community server is a
plain Java app with none of those. Check `product-info.json` before you believe anything.

The Java side of every number below is **Eclipse JDT LS `1.61.0.202609031315`**, launcher
`org.eclipse.equinox.launcher_1.8.0.v20260804-1928`, resolving the JDK as Java 25.0.4.1.

Neither server is cheap. At rest, after indexing one small single-module repo, `kotlin-lsp` held
**2658 MB** RSS (plus a second 1849 MB instance and a 141 MB launcher) against jdtls' **1870 MB**.

## Supported features, as published

`[verified 2026-09-15]` From `Kotlin/kotlin-lsp`'s README, verbatim:

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

Note what is absent: **find-references and go-to-definition are not on that list.** Rename is, and
call hierarchy is. That is an unusual combination, because rename is normally implemented on top of
reference search — so either the omission is a documentation gap or rename is doing something
narrower than it sounds. This was the question the whole post was built to answer.

`[verified 2026-09-15]` And note what a terminal agent can do with the list. The LSP tool in Claude
Code exposes nine operations — `goToDefinition`, `findReferences`, `hover`, `documentSymbol`,
`workspaceSymbol`, `goToImplementation`, `prepareCallHierarchy`, `incomingCalls`, `outgoingCalls`.
**Seven of the eleven published features are unreachable through them**: completion, diagnostics and
quick fixes, semantic highlighting, organize imports, rename, formatting, folding. What remains
measurable is hover, call hierarchy, and whether the build system was understood at all. Meanwhile
the two best things in the server are the two that are not on the list. Hold that inversion in your
head, because the measurements keep producing it.

## The trap that invalidated my first attempt

`[verified 2026-09-15]` **The Claude Code harness roots the language server at the session's
working directory.** If you start a session in repo A and query a file in repo B, the server does
not import B. It analyses the file standalone, with no workspace model.

`[verified 2026-09-15]` And the root is decided once, at startup. **There is no way to move it from
inside a running session.** `cd` in a Bash call changes where shell commands run and nothing else;
the language server keeps the workspace it was given. So this is not a mistake you notice and
correct mid-session — the only fix is to quit and start again from the repository root, which is why
it is worth checking before you ask the first question rather than after you disbelieve the tenth.

What that looks like from the agent's side is the dangerous part, because the two servers degrade
differently:

| | Behaviour with no workspace model |
|---|---|
| Eclipse JDT LS | `EntityMeta.java is a non-project file, only syntax errors are reported` |
| `kotlin-lsp` | `Found 1 reference` (the declaration) · `No incoming calls found (nothing calls this function)` |

Both are equally blind. One says so. The other returns a confident, well-formed, wrong answer —
and the natural next action on "nothing calls this function" is to delete the function.

I took the Kotlin answers at face value and concluded its reference search was broken. The check
that exposed my error: `goToDefinition` also failed on a Kotlin extension property **defined in
another file of the same source set**. That is not a find-references limitation. That is no project
at all. Rooted properly, the same query returns 7 references, and the canary passes:

```
goToDefinition  Person.kt 68:96  (.withZeroNanos)
→ Defined in .../AbstractMappingTests.kt:272:13
```

The exact query, on the exact symbol, that failed before. The trap was the root.

`No incoming calls found`, though, says the same thing under a good root — a genuine limitation I
had wrongly filed under my own setup error, which is the other way this mistake goes. What it
actually means took a second repository to find; see *Call Hierarchy: not broken, blind*.

**Diagnosing rootedness before trusting any result:**

```bash
# What projects has jdtls actually imported?
for d in ~/.cache/jdtls/jdtls-*; do
  echo "$d -> $(ls $d/.metadata/.plugins/org.eclipse.core.resources/.projects/ 2>/dev/null | tr '\n' ',')"
done
```

A workspace containing only `jdt.ls-java-project` is the single-file fallback — nothing was
imported. A healthy one lists the actual Gradle/Maven module names. `[verified]` On this machine a
correctly-imported multi-module workspace listed 13 modules for one repo and 17 for another, so
jdtls imports Gradle fine when given the root.

`[verified 2026-09-15]` A detail that bit me while setting up the rerun: **the workspace hash is
derived from the path, so a git worktree is a different workspace from its own main checkout.**
Running from `jdbi-orm/.claude/worktrees/lsp-tests` produced a brand new `jdtls-16fae7d5…` alongside
the main checkout's `jdtls-7090b22b…`. Both healthy, but the worktree re-imports Gradle from scratch
and pays for it.

**Subagents are not the escape hatch**, which is the first thing you will try, because spawning one
"in the other repo" is the obvious move when you cannot move yourself. `[verified 2026-09-15]` Two
separate facts kill it, and either would be enough. A subagent **inherits the parent session's
working directory**, so it is rooted exactly where you already are. And **the LSP tool is not
exposed to subagents at all** — five `ToolSearch` variants returned nothing — so even correctly
rooted it would have no language server to ask. A subagent sent to answer "what calls this?" falls
back to `grep` without saying so, and hands you back prose that reads exactly like the prose it
would have written from real symbol data.

One more dead end, so nobody repeats it: `[verified 2026-09-15]` nuking `~/.cache/jdtls/<ws>` does
not help. The cache was never the problem.

## Cold start is a race, and it does not always lose loudly

`[verified]` The honest version of this failure: a query issued immediately after the first one dies
with `Cannot send notification to LSP server 'plugin:kotlin-lsp:kotlin-lsp': server is starting`.
That is fine. That is a refusal.

`[verified 2026-09-15]` On the measurement run it did something else. The first two queries of the
session, fired while `intellij-server` was pegged at 298% CPU indexing, came back as:

```
goToDefinition Person.kt 68:96 → "No definition found. This may occur if the cursor is not on a
                                  symbol, or if the definition is in an external library…"
hover          Person.kt 68:96 → "No hover information available…"
```

Two minutes later the identical query returned the correct answer. So **cold start has two failure
modes and one of them is a silent wrong answer wearing a plausible explanation.** Never trust an
empty result from a first query.

## The subjects

`[verified 2026-09-15]` **`jdbi-orm`** — 23 Kotlin files (**all under `src/test`**; remember that,
it decides a whole section), 50 Java files, a single Gradle module, so Kotlin and Java sit in the
same compilation unit and the cross-language boundary is real rather than staged. Session rooted at
the repo, `./gradlew testClasses` green first, then `./gradlew downloadSources`. Ground truth
established by `grep` before each query, never after.

`[verified 2026-09-15, vaadin-boot]` **[`vaadin-boot`](https://github.com/mvysny/vaadin-boot)** —
16 Kotlin files, 28 Java files, **seven Gradle modules**, Kotlin confined to two modules of its own,
so the cross-language boundary is a *project dependency* rather than a shared compilation unit, and
Kotlin appears in both `src/main` and `src/test`. It also has a property I could not have designed
better: the project deliberately ships **two classes with the identical fully-qualified name**,
`com.github.mvysny.vaadinboot.VaadinBoot`, one in the Jetty module and one in the Tomcat module, in
modules that do not depend on each other. That accident produced the sharpest result of any run.

`[verified 2026-09-15, maven]`
**[`vaadin-boot-example-maven`](https://github.com/mvysny/vaadin-boot-example-maven)** — four Java
files in `src/main`, one in `src/test`, **no Kotlin**, one Maven module. Built with
`./mvnw -C test-compile`, then `./mvnw dependency:sources`. It varies exactly one thing.

## kotlin-lsp: reference search is the best thing in it

The feature that is *not* on the published list is excellent. Four reference queries, four exact
answers:

| Query | Result | Ground truth |
|---|---|---|
| `findReferences` `Person.withZeroNanos()` | **7 refs / 3 files** | exact |
| `findReferences` `Person.age` | **57 refs / 5 files** | exact |
| `findReferences` `Entity.save()` — *a Java symbol*, asked from Kotlin | **111 refs / 7 files** | exact |
| `findReferences` `EntityMeta` — *a Java class*, asked from Kotlin | **57 refs / 10 files** | exact (two entries duplicated) |

"Exact" is doing real work in that table. `grep -w age` returns 41 lines in `DaoTest.kt` alone; the
server returned 30 of them and dropped precisely eleven — four `Person2(…, age = …)`, a different
class that happens to have a property of the same name, and seven SQL string literals like
`"age > :age"` and `"age DESC"`. On one line it kept the named argument in
`Person(name = "Zaphod", age = 42)` while skipping the `"age":42` inside the JSON string literal
sitting next to it. On `withZeroNanos` it returned the six calls to the *function* and excluded
`DaoTest.kt:239` and `:247`, which use an unrelated extension property of the same name.

This is the thing grep structurally cannot do, and it is the reason to wire a language server into
an agent at all.

The rest of the navigation family works too, and works **across the language boundary**:
`goToDefinition` jumps from Kotlin into `Entity.java`, `Dao.java` and `EntityMeta.java` in the same
module; `goToImplementation` on the Java interface `Entity` returned all **9** implementors — six
Kotlin, three Java, including one reached transitively through a Java sub-interface. `hover` is
solid and the nullability tell holds (`data class Person(id: Long?, …)` on a built project).

`[verified 2026-09-15, vaadin-boot]` Across a *module* boundary it does something I did not expect
it to survive. Asked for references to the Jetty `VaadinBoot` from a Kotlin file, it returned
**25 refs across 8 files — exactly ground truth**, spanning four modules and both languages, and
containing **not one reference to the Tomcat class of the same fully-qualified name**. The same
discrimination shows up in navigation:

```
goToDefinition  testapp-kotlin/…/Bootstrap.kt         75:9 → vaadin-boot/…/VaadinBoot.java:53:12
goToDefinition  testapp-kotlin-tomcat/…/Bootstrap.kt  75:9 → vaadin-boot-tomcat/…/VaadinBoot.java:20:12
```

Identical source line, identical symbol, identical FQN — resolved to different files according to
which module's dependencies the *calling file* sits behind. `hover` at the first renders the Java
javadoc, the Java signature and a Kotlin-ized view of the class, and the platform-type tell survives
the crossing: `VaadinBootBase<VaadinBoot?>`.

Two gaps. `goToDefinition` does not resolve into external dependencies — but `hover` does, with full
javadoc and a path into the sources jar, so the information is reachable and the gap is visible
rather than silent. And `workspaceSymbol` is **Kotlin-only**: searching `EntityMeta` returned only
the Kotlin `EntityMetaTest`, silently omitting the Java class of that exact name that the same
server will happily `goToDefinition` into.

`[verified 2026-09-15, vaadin-boot]` That second gap is worse than "Kotlin-only" makes it sound.
Searching `VaadinBoot` on the multi-module repo returned **two results, both of them lowercase
`vaadinBoot` local properties**, and omitted all four Java *classes* of that exact name — one of
which is the declaration the same server had resolved `goToDefinition` into a minute earlier. It is
not merely filtering by language; the things it does return are the least useful matches available.
jdtls, asked the same query, returned all six Java symbols, correctly separated by package and
module.

### Declaration positions are approximate on both servers

`documentSymbol` is otherwise flawless, with one wrinkle: its line numbers point at the start of the
declaration *including* the KDoc and annotations, not at the identifier.
`[verified 2026-09-15, vaadin-boot]` That is not a kotlin-lsp quirk — jdtls reports
`WebServer (Interface) - Line 5` for an interface declared on line 39, line 5 being where its javadoc
opens. `[verified 2026-09-15, maven]` And it is not a `documentSymbol` quirk either; the third
subject produced the same offset from three more operations:

```
documentSymbol        Bootstrap (Class)          - Line 7   ← declared on 13; 7 opens the javadoc
documentSymbol        contextInitialized(…)      - Line 14  ← declared on 15; 14 is @Override
incomingCalls         bootstrapApp() : void      - Line 36  ← declared on 37; 36 is @BeforeAll
prepareCallHierarchy  testGreeting() : void      - Line 77  ← declared on 78; 77 is @Test
```

So the rule is broad: **every operation that names an enclosing declaration reports the line where
its javadoc-or-annotation block opens, not the identifier.** The one number in that run that *was*
exact is the nested one — `[calls at: 38:25]` hit the correct column when checked with `awk`. Which
is a usable distinction: positions describing a *reference* are precise, positions describing a
*declaration* are approximate, whatever operation produced them. Do not feed a declaration line
number straight into a positional query on either server.

## Call Hierarchy: not broken, blind

`[verified 2026-09-15]` `prepareCallHierarchy` resolves the item correctly, for both
expression-body and block-body functions. Then:

```
incomingCalls  Person.kt 68:9  (withZeroNanos)
→ No incoming calls found (nothing calls this function)
```

At that same position, one query earlier, `findReferences` listed all six call sites. On `jdbi-orm`
it is empty for every symbol I tried, and `outgoingCalls` matches: `PersonDao.findAll2()` is
reported to call nothing, and its entire body is
`jdbi().withHandle { handle.createQuery(…).map(rowMapper).list() }`.

I concluded that Call Hierarchy does not work. That conclusion was wrong, and the second repository
is what broke it.

`[verified 2026-09-15, vaadin-boot]` On `vaadin-boot`, Call Hierarchy works — some of the time, with
a rule behind it:

| Query | Edge crosses | Result |
|---|---|---|
| `incomingCalls` `Counter.incrementCounter` | main ← main, same file | **1 caller, correct** |
| `incomingCalls` `Counter` | main ← main, **different file** | **1 caller, correct** |
| `incomingCalls` `wget` | test ← test | **empty** — 2 real callers |
| `incomingCalls` `Bootstrap.contextInitialized` | main ← **test** | **empty** — 1 real caller |
| `outgoingCalls` `JettyTest.testAppIsUp` | test → main *and* test | **both `src/main` callees, `src/test` callee dropped** |

The first row also disposes of a smaller suspicion: the caller it found was `Counter.onAttach`, and
the call sits inside a lambda passed to `scheduleWithFixedDelay`. It named the enclosing method
correctly, the same thing jdtls does well.

**Every call-hierarchy edge whose far end lives in a test source set is silently dropped.** The last
row is the cleanest demonstration, because one query contains both outcomes: asked what
`testAppIsUp()` calls, the server returned the two `src/main` properties it touches and omitted
`wget(...)` on line 44, which is three lines below them and declared in `src/test`.

It is not an indexing gap. `findReferences` at the *identical position* on `wget` returns all three
references, both call sites included. The index knows. Call Hierarchy declines to look.

Nor is it a general source-set filter in the server. On `jdbi-orm`, `goToImplementation` on `Entity`
returned six Kotlin implementors — and every Kotlin file in that repo is under `src/test`. The same
server that cannot see test sources through call hierarchy sees them perfectly well through
implementation search. The blindness belongs to one operation, not to the index.

Which retro-explains the entire `jdbi-orm` result. That repo's 23 Kotlin files were **all under
`src/test`** — so every Kotlin call-hierarchy query I ran had a test-source far end, and every one
came back empty. I had a sample of one source set and read it as a sample of the feature. The
`outgoingCalls` example goes the same way once you look at what `findAll2()` actually calls:
`jdbi()`, `withHandle`, `createQuery`, `map`, `list` — every one an *external library* symbol, and
external callees are omitted too, as `vaadin-boot` confirms separately (`super.onAttach`,
`UI.getCurrent` and `scheduleWithFixedDelay` are all missing from an otherwise correct result).
"Reported to call nothing" was two narrow rules wearing a trenchcoat.

So the README's inclusion of Call Hierarchy is defensible — the feature exists and works. What the
README does not say is that it cannot see your tests, which for an agent is close to the worst
possible half to lose: "who calls this?" is most often asked precisely when deciding whether
something is dead code, and the test suite is where the evidence that it is not tends to live.

## jdtls: the Java control I never actually ran

On Java, jdtls earns its reputation. Hover gives full javadoc for project, dependency and JDK
symbols; `goToDefinition` and `workspaceSymbol` behave; and — the one place it beats kotlin-lsp
outright — **its call hierarchy works**. `incomingCalls` on `EntityMeta.getDatabaseTableName()`
returned all 15 callers and correctly named the enclosing lambda (`withHandle(Handle) : Integer`)
rather than the method containing it.

`[verified 2026-09-15, vaadin-boot]` And it works on the axis kotlin-lsp fails: `incomingCalls` on
the `VaadinBoot()` constructor returned four callers, **three of them in `src/test`**, across two
modules. `goToImplementation` is just as solid — asked for implementors of the `WebServer` interface
it returned all **5**, spanning three modules and including two reached transitively through a
nested subclass in a test source set.

That it cannot read Kotlin is not a defect; `Person2 cannot be resolved to a type` in a Java test
file that references a Kotlin class is the correct thing for it to say. What I wanted to know was
what it does with the half of the repo it cannot see — and the answer is that it depends on the
operation, in a way no caller can predict.

Six `incomingCalls` queries, one clean rule:

| Callers of the Java symbol | Result |
|---|---|
| Java only — `getDatabaseTableName` (15), `isFieldPersisted` (2), `save(boolean)` (1) | **correct** |
| Java **and** Kotlin — `EntityMeta.of` (9+17), `getProperty` (4+9) | **`Internal error`** |
| Kotlin only — `Entity.save()` (0+127), `DaoOfAny.findAll()` (0+58) | **"nothing calls this function"** |

The middle row is a crash, and a crash is *fine* — it is loud, reproducible, and an agent that sees
`LSP request 'callHierarchy/incomingCalls' failed … Internal error` falls back to grep.

`[verified 2026-09-15, vaadin-boot]` **The middle row did not reproduce, and that is bad news.** The
same shape on `vaadin-boot` — `VaadinBootBase.run()`, two Java callers and two Kotlin ones — did not
crash. It returned the two Java callers, cleanly formatted, with no error and no indication that
half the answer was missing. So "Java-and-Kotlin callers produce a loud failure" is not a property
of jdtls; it is a property of `jdbi-orm`. The plausible mechanism is the one thing the two repos
differ on here: in `jdbi-orm` the Kotlin and Java share a module, so jdtls must chew on a source
root full of files it cannot parse; in `vaadin-boot` the Kotlin lives in modules of its own, which
jdtls imports and then finds nothing in. Nothing to choke on, nothing to report. Crashes are still
trustworthy — what I can no longer say is which queries will give you one.

The bottom row is the problem. `Entity.save()` is a documented public API method with **127 call
sites across six files**, and jdtls will tell you nothing calls it. Same shape in `findReferences`
(9 refs, seven of them javadoc `{@link}`s inside the declaring file itself) and in
`goToImplementation` (3 of 9 implementors). No warning, no partial-result flag, no difference in
wording from a genuinely unused symbol.

### jdtls also over-reports, which nothing else here does

`[verified 2026-09-15, vaadin-boot]` Every failure catalogued so far is a missing result. This one
is the opposite, and I had no category for it.

`vaadin-boot` ships two classes named `com.github.mvysny.vaadinboot.VaadinBoot` — same simple name,
same package, one in the Jetty module and one in the Tomcat module, and neither module depends on
the other. Asked for references to the Jetty one, jdtls answered:

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

The sharp part is that the same server does not make this mistake elsewhere. `goToDefinition` from
`testapp/Main.java` and from `testapp-tomcat/Main.java` — identical source lines — resolve to the
correct module's class each time. `incomingCalls` on the constructor correctly excludes the Tomcat
twin. `workspaceSymbol` lists all three `VaadinBoot` classes as distinct entries with their
packages. Only `findReferences` flattens them, which suggests it is keyed by name against a global
index while the other operations resolve against the project's real classpath.

For an agent, this is a worse shape than an empty list. A list of 28 hits spanning ten files, with
correct line and column numbers, every entry pointing at real source text containing the real
identifier, reads as the authoritative answer — and acting on it means editing a module that does
not use the symbol you asked about.

## Maven changes nothing, which is what I wanted to know

`[verified 2026-09-15, maven]` jdtls imports `vaadin-boot-example-maven` cleanly — the workspace loop
lists a real module name, not the `jdt.ls-java-project` fallback — and every operation behaves as it
did on Gradle. Both `findReferences` probes exact and crossing main↔test (4 refs / 2 files, 3 refs /
2 files with the `{@link}` included); `goToImplementation` resolves through a *dependency's*
interface; `workspaceSymbol` names packages; `hover` renders javadoc for local, dependency and JDK
symbols alike, tagged `vaadin-ordered-layout-flow-25.2.7.jar` and
`Java 25.0.4.1 (module: java.base)`, generics substituted; and `goToDefinition` into an external
library refuses out loud, exactly as documented. The probes worth stealing are in *Concrete first
probes* below.

The source-set canary passes here in both directions: `contextInitialized()` lives in `src/main` and
its only caller is a `@BeforeAll` method in `src/test`, and `outgoingCalls` crosses back the other
way. So nothing in the jdtls half of this post is Gradle-specific.

One difference, and it is in the side effects rather than the answers: **the Maven importer does not
create `bin/`.** Ground rule 2's warning about jdtls filling every imported module with copies of
your sources is a Gradle-importer artifact; on Maven, excluding `target/` is the whole job.

Cold start also behaved, which is worth recording *because* the rule says not to count on it: the
first query of the session, fired while the import was still running, returned a correct answer
rather than a plausible empty one. A five-file repo imports faster than you can mistrust it. Rule 4
stands — it guards against a race you can lose, not one you always lose.

And the honest limit: this subject has no Kotlin in it, so it says nothing about kotlin-lsp's Maven
support, which is the half of the README claim I actually doubted.

### The empty list I had assigned to the wrong server

`[verified 2026-09-15, maven]` The one new failure the third repo produced is a correction, not an
addition. Asked what a method calls:

```
outgoingCalls  MainViewTest.java 78:17 (testGreeting)      → No outgoing calls found
                                                             (this function calls nothing)
outgoingCalls  MainView.java     17:12 (the constructor)   → No outgoing calls found
                                                             (this function calls nothing)
```

`testGreeting()` calls `_setValue`, `_get` twice, `_click` and `expectNotifications`, plus
`spec.withLabel` and `spec.withText` inside two lambdas. The constructor calls `new TextField`,
`addClassName`, `new Button`, `Notification.show`, `addThemeVariants`, `addClickShortcut` and `add`.
Both come back empty.

The second query isolates the cause, and is why I ran it: none of those seven are static imports, so
the rule is not "statically imported calls are invisible". **External callees are omitted** — which
is precisely the rule I had catalogued as kotlin-lsp's. It is not a kotlin-lsp property. jdtls has
it too, and renders it with the same interpretive parenthetical.

Neither Gradle subject could have caught this. `jdbi-orm`'s all-external `findAll2()` was asked of
kotlin-lsp only, and no jdtls `outgoingCalls` in either run happened to land on a method whose
callees were *all* in libraries. A browserless Vaadin test is nothing but framework calls, so this
repo could not dodge the question. It is also the shape where an agent most often asks it — "what
does this touch?" is asked about wrappers and test helpers far more than about leaf logic — and on
both servers the answer is "nothing".

## The comparison that matters

Same repo, same module, same minute, same symbol — `Entity.save()`, declared in Java, called from
Kotlin:

| | `findReferences` | `incomingCalls` | `goToImplementation` on `Entity` |
|---|---|---|---|
| **kotlin-lsp** | **111** refs / 7 files ✓ | "nothing calls this function" ✗ | **9** impls, both languages ✓ |
| **jdtls** | **9** refs / 1 file ✗ | "nothing calls this function" ✗ | **3** impls, Java only ✗ |
| ground truth | 9 Java + ~102 Kotlin | 127 `.save()` sites | 9 |

The uncomfortable part is not that jdtls is Java-only. It is that on a mixed module the *Kotlin*
server is the better **Java** reference engine, and that the bottom-left cell and the middle column
are indistinguishable to the caller — an empty list and a wrong empty list look exactly the same.

`[verified 2026-09-15, vaadin-boot]` The second repo puts the same question to both servers, and the
margin is wider. Symbol: the Jetty `VaadinBoot`, declared in Java, used from Java and Kotlin across
four modules, with an identically-named twin in a fifth.

| | `findReferences` on `VaadinBoot` |
|---|---|
| **kotlin-lsp**, asked from Kotlin | **25** refs / 8 files — exact, both languages, no twin ✓ |
| **jdtls**, asked from Java | **28** refs / 10 files — 20 right, 8 from the twin, 5 Kotlin missing ✗ |
| ground truth | 20 Java + 5 Kotlin = 25 |

Twice now, on two repositories that share almost nothing structurally, the Kotlin server has given
the better answer about a Java symbol. That is no longer a curiosity about one codebase. If your
repo has any Kotlin in it at all, the Kotlin server is the one to ask about your Java — **from a
Kotlin use site of it.** Every win above was asked from a `.kt` position; on a `.java` document
kotlin-lsp answers almost nothing, and the harness would not route one to it anyway (see *kotlin-lsp
is not a Java server* below). Still, close to the opposite of the advice anyone would give from the
feature lists alone.

**One honest caveat about reference search.** `findReferences` on `Person.save(Boolean)` — an
override — returns 1: the declaration. That is defensible, because no call site in the repo names
that overload. But the naive reading, "nothing uses this override, delete it", is wrong: 127
`.save()` calls dispatch to it at runtime through `Entity.save()`. Reference search answers a
syntactic question. An agent deciding whether a method is dead has to ask about the interface method
too, and neither server volunteers that.

### kotlin-lsp is not a Java server

`[verified 2026-09-15, maven, stdio]` Since kotlin-lsp reads Java so well from Kotlin, the obvious
follow-up is whether it answers on a `.java` file at all — and on a project with no Kotlin, whether
it is simply a better jdtls.

It cannot be asked through the harness. The kotlin-lsp plugin claims `.kt` and `.kts`; jdtls claims
`.java`. Point the LSP tool at `MainView.java` and it goes to jdtls, and only a jdtls process
starts. Reaching kotlin-lsp would take a local plugin override mapping `.java` to it with jdtls
disabled.

So I drove kotlin-lsp directly: a small stdio client sending the same requests the LSP tool makes,
against the installed `263.4702.0-EAP`, on `vaadin-boot-example-maven`. The Maven import itself was
fine — it ran `./mvnw`, took about 20 seconds, resolved the classpath from `~/.m2` and logged
`Successfully imported`. Then, all on `MainView.java`:

| Request | kotlin-lsp |
|---|---|
| `hover` on `VerticalLayout`, a library class | ✓ declaration and javadoc |
| `hover` on `textField.getValue()` | ✓ signature and javadoc, including "Overrides", read from the `-sources.jar`s |
| `documentSymbol` | ✗ empty |
| `goToDefinition` on `Notification.show`, `VerticalLayout` | ✗ empty |
| `findReferences` on local `textField`; on class `MainView`, which the test uses | ✗ empty |
| `goToImplementation`, `workspaceSymbol "MainView"`, call hierarchy | ✗ null / empty |
| diagnostics after injecting a type error, `new TextField(42, 43, 44)` | ✗ none, pull or push |

The requests went out about five minutes after startup, long after the import finished, so this is
not the cold-start race, and the server log shows no errors. jdtls on the same positions found all 4
references to `MainView`, 3 of them in `MainViewTest.java`, and returned the document symbols.

So kotlin-lsp understands the Java project model and resolves Java symbols for hover, but does not
serve navigation, symbols or diagnostics on a `.java` document. That reconciles with everything
above rather than contradicting it: it reads Java *as seen from Kotlin*. One confound I have not
separated — this project also has no Kotlin, so "the document is `.java`" and "the project has no
Kotlin" changed together. It makes no difference to an agent, since the harness routes `.java` to
jdtls either way; it matters only to someone wiring kotlin-lsp into a different client.

## Verdict

As of September 2026, for an agent working in a terminal:

**Java: jdtls is mature. Trust it, with two exceptions.** On pure Java it was right about everything
measured, on Gradle and Maven alike, including a call hierarchy that reads test sources. Both
exceptions look exactly like correct answers: `findReferences` merges classes that share a
fully-qualified name across modules, and anything used only from Kotlin is silently missing from
references, implementations and call hierarchy.

**Kotlin: kotlin-lsp is Alpha, and split down the middle.** Its navigation — references,
definitions, implementations, hover — is production-grade, crosses languages and modules precisely,
and on mixed repos beats jdtls at *Java* symbols, provided you ask from a Kotlin use site. Its call
hierarchy silently drops every edge whose far end is in a test source set. It is not a Java server.
And seven of its eleven advertised features cannot be reached through the Claude Code LSP tool at
all.

**Using the two together:**

- **"What touches this?"** For a symbol declared in Kotlin, ask kotlin-lsp. For a Java symbol in a
  repo with Kotlin, `grep` the Kotlin sources for its name first: if there is a use site, ask
  kotlin-lsp from there and take its answer. If there is none, jdtls is safe — there are no Kotlin
  references for it to miss — except across FQN twins.
- **"Is this dead code?"** Never through call hierarchy, on either server: kotlin-lsp cannot see
  tests, jdtls cannot see Kotlin, and `outgoingCalls` on both leaves out every library callee. Use
  `findReferences` as above, on the method *and* on whatever it overrides.
- **Before any of it,** start the session in the repository root and run both canaries. Nothing
  above holds otherwise, and a wrongly rooted kotlin-lsp will not tell you.

**Limits of this verdict.** Two small-to-medium Gradle repositories and one Maven repository.
kotlin-lsp's Maven import works; its Kotlin analysis on a Maven project was not measured. Memory is
steep — 2.6 GB for kotlin-lsp on a small repo — and nothing large was tried. And it expires:
kotlin-lsp is Alpha, and the IntelliJ LSP extension changes the picture the moment it runs outside VS
Code or settles its price.

## How to verify this yourself

*This section is written to be handed to an agent. It is the deliverable of this post.*

### Ground rules

1. **Run the session from the repository root.** `cd ~/work/my/<repo> && claude`. Not a subagent, not
   a session rooted elsewhere, and not a session you `cd` afterwards — the root is fixed at startup
   and cannot be changed from inside, so getting it wrong means quitting and starting over. This is
   the whole trap.
2. **Establish ground truth with `grep` first, then ask the LSP.** Never the other way round —
   otherwise you are calibrating your expectations to the tool you are testing. Exclude build
   output: `build/` obviously, but also `bin/`, which the Gradle importer makes jdtls create in
   every module and fill with *copies of your Kotlin sources*. `[verified 2026-09-15, maven]` On a
   Maven project jdtls creates no `bin/`, and excluding `target/` is enough.
3. **Build the project first** so dependencies resolve, then restart the language server, so results
   are not unresolved-project artifacts.
4. **Throw away your first two queries.** They are cold-start noise, and they can come back as
   plausible empty answers rather than errors. Wait until the server process drops off the CPU, then
   re-run them.
5. **On a mixed-language repo, ask both servers the same question.** Half the findings here came
   from putting one server's answer next to the other's on one symbol. Either alone looks
   authoritative.
6. **Report raw output verbatim.** No interpretation in the same step as measurement.
7. **Verify column positions with `awk`,** not by eye. I wasted a cycle querying character 13 of the
   wrong line and briefly believed a false negative:
   ```bash
   awk 'NR==19{for(i=1;i<=30;i++) printf "%d:%s ", i, substr($0,i,1); print ""}' File.kt
   ```
8. **Vary the source set on purpose.** For every symbol you test, know whether the *far end* of the
   relationship — the caller, the callee, the implementor — sits in `src/main` or `src/test`, and
   test both. Not having this rule cost me a whole section: `jdbi-orm`'s Kotlin was entirely under
   `src/test`, so a limitation scoped to test sources looked exactly like a feature that was broken
   outright.
9. **Run the matrix on a second repository with a different shape before you believe any of it.**
   Single-module vs. multi-module, languages mixed in one module vs. split across modules, Kotlin in
   `src/main` vs. only in `src/test`. Two of this post's conclusions survived the first repo and
   died on the second, and neither looked fragile at the time. One repository measures the
   repository at least as much as it measures the server.

### Pre-flight: prove the workspace is rooted

Before any measurement, confirm the server imported the project — see the `~/.cache/jdtls` loop
above for Java. For Kotlin, the cheap proof is a cross-file `goToDefinition`: pick a symbol defined
in file A and used in file B, and jump from B to A. If that fails, **stop** — every subsequent
result is meaningless.

On a multi-module build, check the *count* as well as the names: the loop should list every module
in `settings.gradle.kts`, plus a root entry. `vaadin-boot`'s seven modules came back as eight
entries including the Kotlin-only ones, which is what a healthy import of a polyglot Gradle build
looks like — jdtls imports Kotlin modules as projects even though it cannot read a line inside them.

**Then run the source-set canary, which I now consider mandatory.** Pick a function in `src/main`
that is called only from `src/test`, and ask for its `incomingCalls`. If the answer is empty while
`findReferences` at the identical position lists the call sites, the server's call hierarchy cannot
see your tests, and every "nothing calls this" you collect for the rest of the session means
"nothing in `src/main` calls this". kotlin-lsp fails this canary; jdtls passes it, on Gradle and on
Maven alike.

### The matrix

For each operation, record: result, correct?, and how it failed if it did — silent wrong answer vs.
explicit refusal, which is the most interesting output.

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
| `findReferences` | ‡ **a *Kotlin* symbol referenced from Java** | the Java call sites, asked of kotlin-lsp |
| any | † **kotlin-lsp on a `.java` document** — needs a client other than the harness | answers, or you know it will not |
| `workspaceSymbol` | a known class name, **in each language** | found |
| `prepareCallHierarchy` | expression-body fun; block-body fun | resolves both |
| `incomingCalls` | function with ≥5 known callers | all callers |
| `incomingCalls` | **the same, with callers in the other language only** | all callers, or a refusal |
| `incomingCalls` | ‡ **a `src/main` Kotlin function called from `src/main` Java** | all callers — the language axis, unconfounded by source set |
| `incomingCalls` | ***a `src/main` function called only from `src/test`*** | all callers — *source-set canary* |
| `outgoingCalls` | function calling ≥3 things | all callees |
| `outgoingCalls` | ***a function calling both a `src/main` and a `src/test` symbol*** | both — one query, both outcomes |
| `outgoingCalls` | **a function whose callees are *all* in external libraries** † | all callees, or a refusal — never "calls nothing" |
| `goToImplementation` | interface with ≥2 impls **in both languages** | all impls |
| `goToImplementation` | ***impls spread across modules, incl. a test source set*** | all impls |
| rename | a public method used cross-file | every call site updated atomically |

The rows in bold are the ones the `jdbi-orm` run added; the *bold italic* ones came from
`vaadin-boot`; the ones marked † came from `vaadin-boot-example-maven`. The two marked ‡ are not
results — they are the cells I have not filled and consider the most valuable remaining, for the
reasons in *Still open* below. Between them, the rest produced every finding that overturned
something. A matrix that only asks easy questions gets a clean sheet from a server that is quietly
half-blind — and a matrix run on one repository only asks the questions that repository happens to
contain.

### Suggested subjects

Pick repos that isolate one variable each. The first three are measured above; the rest are the
holes.

- **Kotlin + Java in one Gradle module** — does the cross-language boundary resolve?
- **Kotlin and Java in *separate* modules of one multi-module build** — is the boundary still a
  boundary when it is a project dependency? This is what produced the source-set canary and the
  over-reporting finding.
- **A repo that ships two classes with the same FQN in unrelated modules** — the sharpest
  disambiguation test there is. If you maintain something with an `-api` / `-impl` split or a shaded
  twin, you may already have one.
- **A polyglot *Maven* build** — the README claims Gradle and Maven; the Maven repo measured here
  has no Kotlin, so it settles the jdtls half and only the jdtls half.
- **A build with a *third* source set** — an `integrationTest` set, or a custom one. Separates "call
  hierarchy is blind to tests" from "call hierarchy sees only `main`".
- **Large pure-Kotlin multi-module** — does it scale? (`vok`: ~576 Kotlin files)
- **A repo whose methods mostly wrap a framework** — any test suite, any thin service layer. This
  surfaced the external-callee rule, and is a far more common shape than any of the exotic ones
  above.

### Concrete first probes

Exact positions and verified values, so you can check your setup against a known answer rather than
against your expectations. The ones already quoted verbatim above are not repeated.

`jdbi-orm` at `266e843`, built, ground truth by `grep`:

```
goToDefinition  Person.kt 30:5    (Entity)         → Entity.java:51:18     ✓ cross-language
findReferences  Person.kt 19:13   (age)            → 57 refs / 5 files     ✓ exact
incomingCalls   Person.kt 68:9    (withZeroNanos)  → EMPTY — WRONG. Real callers are
                                                     DaoTest.kt:196,197,222,223 and
                                                     AbstractMappingTests.kt:46 (twice)
                                                     — all under src/test, which is the
                                                     actual reason; see the canary
findReferences  EntityMeta.java 38:20  via jdtls   → 37 refs / 7 files, Java only
                 (same symbol via kotlin-lsp, from a Kotlin file) → 57 refs / 10 files, both
```

An earlier draft listed the `withZeroNanos` callers as `DaoTest.kt:165,166,191,192`. Those line
numbers were stale — its own small lesson about hand-maintained ground truth, and the reason step 2
says to re-run the `grep` rather than trust the table.

`[verified 2026-09-15, vaadin-boot]` `vaadin-boot` at `86a7988`, built with `./gradlew testClasses`.
These vary source set and module, so they are the ones worth running first on a repo of your own:

```
incomingCalls   testapp-kotlin/…/Counter.kt 13:7  (Counter)      → 1 caller, MainView.kt  ✓ main ← main
incomingCalls   testapp-kotlin/…/TestUtils.kt 9:5 (wget)         → EMPTY  ✗ source-set canary;
                                                                   findReferences at 9:5 finds
                                                                   JettyTest.kt:44,50
outgoingCalls   testapp-kotlin/…/JettyTest.kt 38:9 (testAppIsUp) → 2 of 3; the src/test callee
                                                                   wget() on line 44 is dropped
incomingCalls   common/…/VaadinBootBase.java 254:17 (run, via jdtls)
                                                           → 2 of 4 — the 2 Kotlin callers are
                                                             missing, silently. No Internal error.
findReferences  testapp-kotlin/…/JettyTest.kt 23:29 (VaadinBoot, kotlin-lsp) → 25/8 ✓
                vaadin-boot/…/VaadinBoot.java 21:14 (jdtls)                  → 28/10 ✗
workspaceSymbol "VaadinBoot" via kotlin-lsp → 2 lowercase properties, zero classes  ✗
                "VaadinBoot" via jdtls      → all 6 Java symbols, packages distinguished  ✓
```

`[verified 2026-09-15, maven]` `vaadin-boot-example-maven` at `d95c806`, built with
`./mvnw -C test-compile`. All jdtls; the repo has no Kotlin. The canary:

```
incomingCalls   Bootstrap.java 15:17 (contextInitialized, src/main, sole caller in src/test)
                → 1 caller: MainViewTest.bootstrapApp, calls at 38:25   ✓ passes on Maven too
```

Then the trap and its control, which is the pair that matters: `outgoingCalls` on
`MainViewTest.java 78:17` and `MainView.java 17:12` both come back empty, while
`MainViewTest.java 37:24` — same file, same source set, project callees only — returns its 2
callees. Run either without the other and you will draw the wrong conclusion, which is the same
mistake this post has now made twice.

## Open questions

Answered above, in one line each:

1. ~~Does `findReferences` work when properly rooted?~~ **Yes — the best feature in the server.**
2. ~~Is the README's omission of find-references and go-to-definition a docs gap or real?~~ **A docs
   gap.** Its real omission is that Call Hierarchy cannot see test sources.
3. ~~Does the Kotlin→Java boundary resolve inside one module?~~ **Yes, in one direction.** jdtls not
   reading Kotlin is expected; reporting the gap as an empty result is not.
4. ~~Does it also resolve *across* modules?~~ **Yes, and precisely** — including between two classes
   sharing a fully-qualified name in sibling modules.
5. ~~How does jdtls compare, measured rather than assumed?~~ Excellent on pure Java, except that
   `findReferences` merges FQN twins — the only *over*-reporting failure either server produced.
6. ~~Maven vs Gradle?~~ **For jdtls, no difference in the answers and one in the side effects:** the
   Maven importer creates no `bin/`. The kotlin-lsp half survives below.
7. ~~Is kotlin-lsp a better Java server on a project with no Kotlin?~~ **No.** Its Maven import
   works, but on a `.java` document only hover answers, and the harness never routes `.java` to it
   anyway.

Still open, roughly in order of how cheaply each could be closed:

1. **Does kotlin-lsp's reference search find *Java* call sites of a *Kotlin* symbol?** Every
   `findReferences` above runs Kotlin→Java or Kotlin→Kotlin; the reverse direction is untested. It
   will probably work — kotlin-lsp already returns reference locations inside `.java` files when
   asked from Kotlin — but the verdict's "for a symbol declared in Kotlin, ask kotlin-lsp" leans on
   it. `jdbi-orm` already contains the subject: a Java test file that references the Kotlin class
   `Person2`. One query.
2. **Does kotlin-lsp's call hierarchy cross the language boundary at all?** All five `vaadin-boot`
   call-hierarchy rows are Kotlin→Kotlin. The one cross-boundary datapoint — `Entity.save()` on
   `jdbi-orm` — is confounded, because its callers were Kotlin *and* all under `src/test`, so the
   source-set rule already accounts for the empty answer. What is needed is a Java `src/main` caller
   of a Kotlin `src/main` function. Reference search crosses the boundary brilliantly; whether call
   hierarchy inherits that is unknown.
3. **Does kotlin-lsp's *Kotlin* analysis work on Maven?** The import does — on the pure-Java
   subject it ran `./mvnw`, resolved `~/.m2` and logged `Successfully imported` — but with no
   Kotlin in the tree there was nothing Kotlin to ask. A polyglot Maven build is still the missing
   subject, and it is not an exotic one.
4. **Is the call-hierarchy blindness about test source sets specifically, or about any source set
   other than the primary one?** Both Gradle subjects have exactly two. A build with a third — an
   `integrationTest` set, or a custom one — would separate those, and they imply very different
   workarounds.
5. **Does any of this scale?** One small single-module repo cost 2.6 GB of RSS and roughly two
   minutes of indexing; the seven-module one was cheaper, at 1.4 GB for jdtls against 1.7 GB +
   1.3 GB for two kotlin-lsp instances — and why there are consistently *two* instances is itself
   unexplained. A large pure-Kotlin multi-module tree is the obvious next subject.
6. **Does kotlin-lsp's `workspaceSymbol` omit Java classes, or omit classes it did not index as
   Kotlin?** It returned lowercase local properties over exact-name Java classes, which looks less
   like a language filter than like a different index being consulted than the one `goToDefinition`
   uses.
7. **Does jdtls' FQN-merging in `findReferences` extend to shaded or relocated jars?** The
   `vaadin-boot` case is two source modules. A shaded dependency that relocates a package into a
   name a project source file also uses is the same collision with worse consequences, and is far
   more common than a deliberately duplicated class.
8. **Is the external-callee omission in `outgoingCalls` a reading of the LSP spec, or the same
   performance shortcut taken twice?** Both servers do it, so it is not a quirk of either. If it is
   deliberate, the operation is by design useless on any method that wraps a framework — which is
   most methods in most test suites and most service layers — and the parenthetical "(this function
   calls nothing)" is then not merely unhelpful but actively false as a summary of documented
   behaviour.

And one that cannot be closed from here. **Rename** is the only matrix cell with no result, along
with the six other published features the Claude Code LSP tool does not expose. It needs a different
client — the VS Code extension, or an LSP client driven by hand. It no longer settles the docs
question, since find-references turned out to work; what it would settle is narrower: whether rename
is reference-search-complete, given that reference search itself is sound.

## The part that generalises

The finding that outlives the numbers is not about Kotlin at all: **when you wire a tool into an
agent loop, how it fails matters as much as how well it works.**

A tool that degrades loudly is safe at any quality level — the agent detects the refusal, falls back
to `grep`, tells you. A tool that degrades silently is dangerous in proportion to how much the agent
trusts it, and an empty result is the worst possible shape for a silent failure, because "no
results" and "no answer" are indistinguishable to the caller while implying opposite actions.

Over two servers and three repositories I collected five distinct empty lists — kotlin-lsp's call
hierarchy, which means *your callers are in a source set I do not read*; jdtls' `incomingCalls` on a
Kotlin-called method, which means *I cannot read that language*; kotlin-lsp's `workspaceSymbol` on a
Java class, which means the same thing in mirror image; `outgoingCalls` on a function whose callees
are all in libraries, which means *I only report project symbols*; and a cold-start
`No definition found`, which means *ask me again in two minutes*. Five different causes, one
identical rendering, and in every case the phrasing implies the one thing that is not true: that the
server looked and there was nothing there.

`[verified 2026-09-15, maven]` Note what the fourth of those lost when the third repository ran: its
owner. I had written it as kotlin-lsp's; jdtls produces it word for word. That is a small fact about
jdtls and a larger one about this list — I had been collecting these as properties of *servers*, and
at least one is a property of the thing both servers are. The taxonomy that matters is not "which
server fails here" but "which question has an answer this tool never looks for", and the second
framing is the one that transfers to whatever server replaces these.

`No incoming calls found (nothing calls this function)` is the worst of them, because the
parenthetical is not a rendering of the result — it is an interpretation, supplied by the tool, of a
result the tool has no grounds to interpret. An agent that reads it has been handed a conclusion,
not data.

Exactly once did a server refuse out loud: jdtls returning `Internal error`. On the day's evidence
it was the most trustworthy thing either of them said — though the same query shape elsewhere
returned a quiet half-answer instead, so you cannot rely on being told.

And worse than any empty list is the failure mode I had not budgeted for: **a wrong answer that is
not empty.** There is no cue in jdtls' over-long reference list — correct paths, correct line and
column numbers, every entry pointing at real source text containing the real identifier. An empty
list at least prompts a second thought; a confident, well-formed one gets acted on. So: **a tool in
an agent loop should be judged on what its wrong answers look like, and the dangerous ones are the
answers shaped exactly like right ones.**

Which is also the case for running the matrix twice. Everything I got wrong in the first draft, I
got wrong because one repository answered clearly and I mistook a clear answer for a general one.

I would take a reference search that refuses over one that returns an empty list.
