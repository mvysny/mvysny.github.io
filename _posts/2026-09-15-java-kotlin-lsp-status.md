---
layout: post
title: The State of Java and Kotlin Language Servers
date: 2026-09-15 12:45:28 +0300
---

> **A snapshot, September 2026.** Measured on 2026-09-15 against three repositories through the
> Claude Code LSP tool, plus one experiment that drove kotlin-lsp directly over stdio. Every number
> here will rot; the methodology at the bottom is the part meant to outlive it.

An agent editing a codebase has two ways to answer "what else touches this?": `grep`, or a language
server. `grep` finds text and cannot tell you what it missed; a language server finds *symbols* and
knows a call from a comment. Which one your agent gets is mostly decided by the language you picked
— and, it turns out, by something much dumber than that.

I set out to measure whether Kotlin's language server is good enough to trust. It is, at the thing I
most doubted. The uncomfortable answers were elsewhere: in what each server says about code it
cannot see, and in how much of what I thought I had measured was really a property of the one
repository I measured it on.

If you read nothing else, read this: **start the session in the repository root, or every answer
you get is quietly worthless.** The language server is rooted at the session's working directory,
you cannot move it once the session is running, and when it is rooted wrong, one of the two servers
does not tell you — it just answers wrong. See *The trap* below; it cost me a retracted draft.

## What is under test

**Kotlin: `Kotlin/kotlin-lsp`**, JetBrains' free standalone server. Its README carries an Alpha
badge and says so outright ("⚠️ The project is currently in the Alpha state ⚠️"). It ships a VS Code
extension and a standalone CLI for any LSP-capable editor. It is what a terminal agent gets today,
and the only Kotlin server measured here. Two others exist and are out of scope: the community
`fwcd/kotlin-language-server`, which most older writing on this topic means, and the IntelliJ IDEA
LSP extension announced in August 2026, which targets VS Code and its forks and needs an Ultimate
subscription once the preview ends.

It is easy to benchmark the wrong binary, so check `product-info.json`. This machine had:

```
name             kotlin-server
version          2026.3
versionSuffix    EAP
buildNumber      263.4702.0
productCode      ILS
minRequiredJavaVersion  25
```

with a bundled JetBrains Runtime (`jbr/`) and `intellij.*` platform jars. The community server is a
plain Java app with neither.

**Java: Eclipse JDT LS `1.61.0.202609031315`** (launcher
`org.eclipse.equinox.launcher_1.8.0.v20260804-1928`, JDK 25.0.4.1) — what VS Code's Java extension
runs, with a decade of maturity behind it.

Neither is cheap. After indexing one small single-module repo, kotlin-lsp held **2658 MB** RSS, plus
a second 1849 MB instance and a 141 MB launcher; jdtls held **1870 MB**.

The three subjects, each chosen to vary what the previous one held fixed:

- **`jdbi-orm`** — 23 Kotlin files, **all under `src/test`** (that detail decides a whole section),
  50 Java files, one Gradle module. Kotlin and Java share a compilation unit, so the cross-language
  boundary is real rather than staged.
- **[`vaadin-boot`](https://github.com/mvysny/vaadin-boot)** — 16 Kotlin files, 28 Java files,
  **seven Gradle modules**, with Kotlin in two modules of its own and in both `src/main` and
  `src/test`, so the language boundary is a project dependency. It also deliberately ships **two
  classes with the same fully-qualified name**, `com.github.mvysny.vaadinboot.VaadinBoot`: one in
  the Jetty module, one in the Tomcat module, neither depending on the other. That produced the
  sharpest result of any run.
- **[`vaadin-boot-example-maven`](https://github.com/mvysny/vaadin-boot-example-maven)** — four Java
  files in `src/main`, one in `src/test`, no Kotlin, one Maven module.

Each was built first (`./gradlew testClasses` and `downloadSources`; `./mvnw -C test-compile` and
`dependency:sources`), the session was rooted at the repo, and ground truth came from `grep` before
each query, never after.

## What the README promises

From `Kotlin/kotlin-lsp`'s README, verbatim:

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

**Find-references and go-to-definition are not on it**, yet rename is — odd, since rename is normally
built on reference search. Either the list has a gap, or rename does something narrower than it
sounds. That question started this post.

A terminal agent can reach less of the list than it suggests. The Claude Code LSP tool exposes nine
operations — `goToDefinition`, `findReferences`, `hover`, `documentSymbol`, `workspaceSymbol`,
`goToImplementation`, `prepareCallHierarchy`, `incomingCalls`, `outgoingCalls` — and **seven of the
eleven published features are unreachable through them**: completion, diagnostics and quick fixes,
semantic highlighting, organize imports, rename, formatting, folding. Meanwhile the two best things
in the server turn out to be the two that are not on the list.

## The trap

**The Claude Code harness roots the language server at the session's working directory.** Start a
session in repo A, query a file in repo B, and the server does not import B; it analyses the file
standalone, with no workspace model.

**The root is decided once, at startup, and cannot be moved from inside the session.** `cd` in a
Bash call changes where shell commands run and nothing else. This is not a mistake you correct
mid-session: the only fix is to quit and start again from the repository root. Check it before the
first question, not after you disbelieve the tenth.

Rooted wrong, the two servers degrade differently:

| | Behaviour with no workspace model |
|---|---|
| Eclipse JDT LS | `EntityMeta.java is a non-project file, only syntax errors are reported` |
| `kotlin-lsp` | `Found 1 reference` (the declaration) · `No incoming calls found (nothing calls this function)` |

Both are equally blind. One says so. The other returns a confident, well-formed, wrong answer — and
the natural next action on "nothing calls this function" is to delete the function.

I took the Kotlin answers at face value and concluded its reference search was broken. What exposed
the error was `goToDefinition` failing on an extension property **defined in another file of the
same source set**: that is not a limitation of reference search, that is no project at all. Rooted
properly, the same reference query returns 7 hits and the jump works:

```
goToDefinition  Person.kt 68:96  (.withZeroNanos)
→ Defined in .../AbstractMappingTests.kt:272:13
```

`No incoming calls found`, though, persisted under a good root — a genuine limitation I had wrongly
blamed on my own setup, which is the other way this mistake goes. See *Call Hierarchy: not broken,
blind*.

**To check what jdtls actually imported:**

```bash
# What projects has jdtls actually imported?
for d in ~/.cache/jdtls/jdtls-*; do
  echo "$d -> $(ls $d/.metadata/.plugins/org.eclipse.core.resources/.projects/ 2>/dev/null | tr '\n' ',')"
done
```

A workspace containing only `jdt.ls-java-project` is the single-file fallback: nothing was imported.
A healthy one lists the real Gradle or Maven module names. The workspace is keyed by path, so a git
worktree gets its own and re-imports the build from scratch.

**Subagents are no escape hatch**, though spawning one "in the other repo" is the obvious move when
you cannot move yourself. Two facts rule it out, either one sufficient. A subagent **inherits the
parent's working directory**, so it is rooted exactly where you are. And **the LSP tool is not
exposed to subagents at all** — five `ToolSearch` variants found nothing. A subagent asked "what
calls this?" falls back to `grep` without saying so, and its answer reads exactly like one written
from real symbol data.

Nor does deleting `~/.cache/jdtls/<ws>` help. The cache was never the problem.

## Cold start is a race, and it does not always lose loudly

Sometimes a query issued right after startup fails honestly: `Cannot send notification to LSP server
'plugin:kotlin-lsp:kotlin-lsp': server is starting`. That is a refusal, and a refusal is fine.

On the measurement run it did something else. The first two queries, fired while `intellij-server`
sat at 298% CPU indexing, came back as:

```
goToDefinition Person.kt 68:96 → "No definition found. This may occur if the cursor is not on a
                                  symbol, or if the definition is in an external library…"
hover          Person.kt 68:96 → "No hover information available…"
```

Two minutes later the identical query returned the correct answer. **Cold start has two failure
modes, and one is a silent wrong answer with a plausible explanation attached.** Never trust an
empty result from a first query.

## kotlin-lsp: reference search is the best thing in it

The feature missing from the README is excellent. On `jdbi-orm`, four reference queries, four exact
answers:

| Query | Result | Ground truth |
|---|---|---|
| `findReferences` `Person.withZeroNanos()` | **7 refs / 3 files** | exact |
| `findReferences` `Person.age` | **57 refs / 5 files** | exact |
| `findReferences` `Entity.save()` — *a Java symbol*, asked from Kotlin | **111 refs / 7 files** | exact |
| `findReferences` `EntityMeta` — *a Java class*, asked from Kotlin | **57 refs / 10 files** | exact (two entries duplicated) |

"Exact" is doing real work there. `grep -w age` returns 41 lines in `DaoTest.kt` alone; the server
returned 30 and dropped precisely eleven — four `Person2(…, age = …)`, a different class with a
property of the same name, and seven SQL string literals like `"age > :age"` and `"age DESC"`. On
one line it kept the named argument in `Person(name = "Zaphod", age = 42)` and skipped the `"age":42`
inside the JSON string literal next to it. On `withZeroNanos` it returned the six calls to the
*function* and excluded `DaoTest.kt:239` and `:247`, which use an unrelated extension property of
the same name.

This is what grep structurally cannot do, and the reason to wire a language server into an agent at
all.

The rest of the navigation family also works **across the language boundary**: `goToDefinition`
jumps from Kotlin into `Entity.java`, `Dao.java` and `EntityMeta.java`, and `goToImplementation` on
the Java interface `Entity` returns all **9** implementors — six Kotlin, three Java, one of them
reached through a Java sub-interface. `hover` is solid, and the nullability tell holds
(`data class Person(id: Long?, …)`).

On `vaadin-boot` it holds across *modules* too, and passes a test I did not expect it to. Asked from
a Kotlin file for references to the Jetty `VaadinBoot`, it returned **25 refs in 8 files — exactly
ground truth**, spanning four modules and both languages, with **not one reference to the Tomcat
class of the same fully-qualified name**. Navigation discriminates the same way:

```
goToDefinition  testapp-kotlin/…/Bootstrap.kt         75:9 → vaadin-boot/…/VaadinBoot.java:53:12
goToDefinition  testapp-kotlin-tomcat/…/Bootstrap.kt  75:9 → vaadin-boot-tomcat/…/VaadinBoot.java:20:12
```

Same source line, same symbol, same FQN — resolved to different files according to which module the
*calling file* depends on. `hover` there renders the Java javadoc and signature, and the
platform-type tell survives the crossing: `VaadinBootBase<VaadinBoot?>`.

Two gaps. `goToDefinition` does not resolve into external libraries — but `hover` does, with full
javadoc and a path into the sources jar, so that gap is visible rather than silent. `workspaceSymbol`
is the bad one. Searching `EntityMeta` returned only the Kotlin `EntityMetaTest`, omitting the Java
class of that exact name. Searching `VaadinBoot` returned **two lowercase `vaadinBoot` local
properties** and none of the four Java classes of that name — including the one `goToDefinition` had
just jumped into. jdtls, asked the same, returned all six Java symbols, separated by package and
module.

### Declaration positions are approximate, on both servers

Operations that name an enclosing declaration report the line where its javadoc or annotation block
opens, not the identifier. kotlin-lsp's `documentSymbol` does it, and jdtls does it across
operations:

```
documentSymbol        WebServer (Interface)      - Line 5   ← declared on 39; 5 opens the javadoc
documentSymbol        Bootstrap (Class)          - Line 7   ← declared on 13; 7 opens the javadoc
documentSymbol        contextInitialized(…)      - Line 14  ← declared on 15; 14 is @Override
incomingCalls         bootstrapApp() : void      - Line 36  ← declared on 37; 36 is @BeforeAll
prepareCallHierarchy  testGreeting() : void      - Line 77  ← declared on 78; 77 is @Test
```

Positions describing a *reference* are exact — `[calls at: 38:25]` hit the right column when checked
with `awk`. Never feed a declaration's line number straight into a positional query.

## Call Hierarchy: not broken, blind

On `jdbi-orm`, `prepareCallHierarchy` resolves the item correctly, for expression-body and
block-body functions alike. Then:

```
incomingCalls  Person.kt 68:9  (withZeroNanos)
→ No incoming calls found (nothing calls this function)
```

One query earlier, at the same position, `findReferences` listed all six call sites. Every symbol I
tried came back empty, and `outgoingCalls` agreed: `PersonDao.findAll2()`, whose entire body is
`jdbi().withHandle { handle.createQuery(…).map(rowMapper).list() }`, reportedly calls nothing. I
concluded that Call Hierarchy did not work. `vaadin-boot` showed that it does — under a rule:

| Query | Edge crosses | Result |
|---|---|---|
| `incomingCalls` `Counter.incrementCounter` | main ← main, same file | **1 caller, correct** |
| `incomingCalls` `Counter` | main ← main, **different file** | **1 caller, correct** |
| `incomingCalls` `wget` | test ← test | **empty** — 2 real callers |
| `incomingCalls` `Bootstrap.contextInitialized` | main ← **test** | **empty** — 1 real caller |
| `outgoingCalls` `JettyTest.testAppIsUp` | test → main *and* test | **both `src/main` callees, `src/test` callee dropped** |

**Every edge whose far end lives in a test source set is silently dropped.** The last row shows both
outcomes in one query: asked what `testAppIsUp()` calls, the server returned the two `src/main`
properties it touches and omitted `wget(...)` three lines below, declared in `src/test`. The first
row shows the rest is sound: that call sits inside a lambda passed to `scheduleWithFixedDelay`, and
the server correctly named the enclosing `Counter.onAttach`.

It is not the index: `findReferences` at the same position on `wget` returns all three references.
Nor is it a general source-set filter: on `jdbi-orm`, `goToImplementation` found six Kotlin
implementors, every one of them under `src/test`. The blindness belongs to call hierarchy alone.

That explains `jdbi-orm` completely. Its Kotlin is all test code, so every call-hierarchy query there
had a test-source far end; I had sampled one source set and read it as a sample of the feature.
`findAll2()` fell to a second rule: every callee is an external library symbol, and those are
omitted too — on `vaadin-boot`, `super.onAttach`, `UI.getCurrent` and `scheduleWithFixedDelay` are
missing from an otherwise correct result. "Calls nothing" was two narrow rules wearing a trenchcoat.

So Call Hierarchy belongs on the README. What the README does not say is that it cannot see your
tests — close to the worst half to lose, because "who calls this?" is usually asked when deciding
whether something is dead, and the tests are where the evidence tends to live.

## jdtls: excellent at Java, blind to Kotlin

On Java, jdtls earns its reputation. Hover gives full javadoc for project, dependency and JDK
symbols; `goToDefinition` and `workspaceSymbol` behave; and **its call hierarchy works** — the one
place it beats kotlin-lsp outright. `incomingCalls` on `EntityMeta.getDatabaseTableName()` returned
all 15 callers and named the enclosing lambda (`withHandle(Handle) : Integer`) rather than the method
around it. On `vaadin-boot`, `incomingCalls` on the `VaadinBoot()` constructor returned four callers
across two modules, **three of them in `src/test`**, and `goToImplementation` on `WebServer` found
all **5** implementors across three modules, two of them through a nested subclass in test code.

It cannot read Kotlin, and says so correctly: `Person2 cannot be resolved to a type` in a Java test
that references a Kotlin class. The question is what it does with the half of the repo it cannot
see. On `jdbi-orm`, six `incomingCalls` queries sorted cleanly:

| Callers of the Java symbol | Result |
|---|---|
| Java only — `getDatabaseTableName` (15), `isFieldPersisted` (2), `save(boolean)` (1) | **correct** |
| Java **and** Kotlin — `EntityMeta.of` (9+17), `getProperty` (4+9) | **`Internal error`** |
| Kotlin only — `Entity.save()` (0+127), `DaoOfAny.findAll()` (0+58) | **"nothing calls this function"** |

The middle row is a crash, and a crash is *fine*: loud, reproducible, and an agent that sees
`LSP request 'callHierarchy/incomingCalls' failed … Internal error` falls back to grep.

**It did not reproduce.** On `vaadin-boot`, `VaadinBootBase.run()` — two Java callers, two Kotlin —
returned the two Java callers, cleanly, with no hint that half the answer was missing. The likely
difference: in `jdbi-orm` the Kotlin shares a module with the Java, so jdtls chokes on files it
cannot parse; in `vaadin-boot` the Kotlin sits in modules of its own, which jdtls imports and finds
empty. Crashes are still trustworthy. You just cannot count on getting one.

The bottom row is the real problem. `Entity.save()` is documented public API with 127 `.save()` call
sites, and jdtls says nothing calls it. `findReferences` has the same shape (9 refs, seven of them
javadoc `{@link}`s in the declaring file), and so does `goToImplementation` (3 of 9). No warning, no
partial-result flag, no difference in wording from a genuinely unused symbol.

### jdtls also over-reports

Every failure so far is a missing result. This one is the opposite. Asked for references to the
Jetty `VaadinBoot`, jdtls answered:

```
findReferences  vaadin-boot/…/VaadinBoot.java 21:14
→ Found 28 references across 10 files
```

Twenty are right. **Eight belong to the Tomcat twin** — `testapp-tomcat/Main.java`, `TomcatTest.java`,
the twin's own declaration line, and a `{@link}` in `TomcatWebServer`. The five Kotlin references are
missing, as expected. The answer is wrong in both directions at once, and the two errors partly
cancel into a plausible number.

Only `findReferences` does this. `goToDefinition` from the identical lines in `testapp/Main.java` and
`testapp-tomcat/Main.java` resolves to the right class each time; `incomingCalls` on the constructor
excludes the twin; `workspaceSymbol` lists the classes separately. Reference search looks keyed by
name against a global index, while the other operations resolve against each module's real
classpath.

For an agent this is worse than an empty list. Twenty-eight hits across ten files, with correct lines
and columns, each pointing at real source text containing the real identifier, reads as
authoritative — and acting on it means editing a module that does not use the symbol.

## Maven changes nothing for jdtls

On `vaadin-boot-example-maven`, jdtls imports cleanly — a real module name in the workspace, not the
fallback — and behaves exactly as on Gradle: exact references across main and test,
`goToImplementation` through a dependency's interface, javadoc on hover for local, dependency and JDK
symbols, and an explicit "not indexed" refusal when asked to jump into a library. The source-set
canary passes in both directions. The one difference is a side effect: the Maven importer does not
litter modules with `bin/` directories.

This subject has no Kotlin, so it says nothing about kotlin-lsp on Maven. It did correct something.

### Both servers omit library callees

```
outgoingCalls  MainViewTest.java 78:17 (testGreeting)      → No outgoing calls found
                                                             (this function calls nothing)
outgoingCalls  MainView.java     17:12 (the constructor)   → No outgoing calls found
                                                             (this function calls nothing)
```

`testGreeting()` calls `_setValue`, `_get` twice, `_click` and `expectNotifications`, plus
`spec.withLabel` and `spec.withText` inside two lambdas. The constructor calls `new TextField`,
`addClassName`, `new Button`, `Notification.show`, `addThemeVariants`, `addClickShortcut` and `add` —
none of them static imports, which rules that out as the cause. Meanwhile `bootstrapApp()` in the
same test file, whose callees are project code, returns both of them.

**External callees are omitted** — the rule I had filed as kotlin-lsp's. jdtls does the same, with
the same parenthetical. Neither Gradle subject happened to ask jdtls about a method whose callees were
all libraries; a browserless Vaadin test is nothing else. And that is exactly where agents ask: "what
does this touch?" comes up about wrappers and test helpers far more than about leaf logic, and both
servers answer "nothing".

## The comparison that matters

Same repo, same module, same symbol — `Entity.save()`, declared in Java, called from Kotlin:

| | `findReferences` | `incomingCalls` | `goToImplementation` on `Entity` |
|---|---|---|---|
| **kotlin-lsp** | **111** refs / 7 files ✓ | "nothing calls this function" ✗ | **9** impls, both languages ✓ |
| **jdtls** | **9** refs / 1 file ✗ | "nothing calls this function" ✗ | **3** impls, Java only ✗ |
| ground truth | 9 Java + ~102 Kotlin | 127 `.save()` sites | 9 |

The uncomfortable part is not that jdtls is Java-only. It is that on a mixed module the *Kotlin*
server is the better **Java** reference engine — and that a correct empty list and a wrong one look
identical.

On `vaadin-boot` the margin is wider. The Jetty `VaadinBoot`, declared in Java, used from Java and
Kotlin across four modules, with its twin in a fifth:

| | `findReferences` on `VaadinBoot` |
|---|---|
| **kotlin-lsp**, asked from Kotlin | **25** refs / 8 files — exact, both languages, no twin ✓ |
| **jdtls**, asked from Java | **28** refs / 10 files — 20 right, 8 from the twin, 5 Kotlin missing ✗ |
| ground truth | 20 Java + 5 Kotlin = 25 |

Two structurally unrelated repositories, one result: if your repo has any Kotlin, ask the Kotlin
server about your Java — **from a Kotlin use site.** Every win above was asked from a `.kt` file; on a
`.java` file kotlin-lsp answers almost nothing, as the next section shows. That is close to the
opposite of what either feature list would suggest.

One caveat about reference search. `findReferences` on `Person.save(Boolean)`, an override, returns
only its declaration. That is defensible — no call site names the override — but "nothing uses it,
delete it" is wrong: `.save()` calls on a `Person` dispatch to it at runtime through `Entity.save()`.
Reference search answers a syntactic question. To decide whether a method is dead, also ask about
what it overrides; neither server volunteers that.

### kotlin-lsp is not a Java server

Since kotlin-lsp reads Java so well from Kotlin: does it answer on a `.java` file — and on a project
without Kotlin, is it simply a better jdtls?

The harness will not let you ask. The kotlin-lsp plugin claims `.kt` and `.kts` and jdtls claims
`.java`, so the LSP tool on `MainView.java` goes to jdtls; reaching kotlin-lsp would need a local
plugin override mapping `.java` to it, with jdtls disabled. So I drove kotlin-lsp directly over
stdio, with a small client sending the same requests the LSP tool makes, on
`vaadin-boot-example-maven`. The Maven import worked — `./mvnw`, about 20 seconds, classpath resolved
from `~/.m2`, `Successfully imported`. Then, on `MainView.java`:

| Request | kotlin-lsp |
|---|---|
| `hover` on `VerticalLayout`, a library class | ✓ declaration and javadoc |
| `hover` on `textField.getValue()` | ✓ signature and javadoc, including "Overrides", read from the `-sources.jar`s |
| `documentSymbol` | ✗ empty |
| `goToDefinition` on `Notification.show`, `VerticalLayout` | ✗ empty |
| `findReferences` on local `textField`; on class `MainView`, which the test uses | ✗ empty |
| `goToImplementation`, `workspaceSymbol "MainView"`, call hierarchy | ✗ null / empty |
| diagnostics after injecting a type error, `new TextField(42, 43, 44)` | ✗ none, pull or push |

The requests went out five minutes after startup, well after the import finished, and the log showed
no errors. jdtls at the same positions found all 4 references to `MainView`, 3 of them in
`MainViewTest.java`, and returned the document symbols.

kotlin-lsp understands the Java project model and resolves Java symbols for hover, but serves no
navigation, symbols or diagnostics on a `.java` file: it reads Java *as seen from Kotlin*. One
confound remains — the project also had no Kotlin, so "`.java` document" and "no Kotlin in the
project" changed together. For an agent that is moot, since the harness routes `.java` to jdtls
either way.

## Verdict

As of September 2026, for an agent working in a terminal:

**Java: jdtls is mature. Trust it, with two exceptions.** On pure Java it was right about everything
measured, on Gradle and Maven, including a call hierarchy that sees test code. Both exceptions look
exactly like correct answers: `findReferences` merges classes that share a fully-qualified name
across modules, and anything used only from Kotlin is silently missing from references,
implementations and call hierarchy.

**Kotlin: kotlin-lsp is Alpha, and split down the middle.** Its navigation — references,
definitions, implementations, hover — is production-grade, precise across languages and modules, and
on mixed repos better than jdtls at *Java* symbols, provided you ask from a Kotlin use site.
`workspaceSymbol` is unreliable. Call hierarchy silently drops every edge that ends in test code. It
is not a Java server. And seven of its eleven advertised features cannot be reached through the
Claude Code LSP tool.

**Using the two together:**

- **"What touches this?"** For a symbol declared in Kotlin, ask kotlin-lsp. For a Java symbol, `grep`
  the Kotlin sources for its name first: if it is used there, ask kotlin-lsp from that use site. If
  not, jdtls is safe — it has no Kotlin references to miss — except across FQN twins.
- **"Is this dead code?"** Never via call hierarchy, on either server: kotlin-lsp cannot see tests,
  jdtls cannot see Kotlin, and both omit library callees. Use `findReferences` as above, on the method
  *and* on whatever it overrides.
- **Before any of it,** start the session in the repository root and run the canaries in *Pre-flight*
  below. A wrongly rooted kotlin-lsp will not tell you.

**Limits.** Two small-to-medium Gradle repositories and one Maven repository. kotlin-lsp's Maven
import works; its Kotlin analysis on Maven is unmeasured. Nothing large was tried. And this verdict
expires: kotlin-lsp is Alpha, and the IntelliJ LSP extension changes the picture the moment it runs
outside VS Code or settles its price.

## How to verify this yourself

*This section is written to be handed to an agent.*

### Ground rules

1. **Run the session from the repository root.** `cd ~/work/my/<repo> && claude`. Not a subagent, not
   a session rooted elsewhere, and not a session you `cd` afterwards — the root is fixed at startup,
   so getting it wrong means quitting and starting over.
2. **Establish ground truth with `grep` first, then ask the LSP.** Never the other way round, or you
   calibrate your expectations to the tool under test. Exclude build output — `build/` or `target/`,
   and on Gradle also `bin/`, which jdtls creates in every imported module and fills with *copies of
   your Kotlin sources*.
3. **Build the project first**, then restart the language server, so results are not
   unresolved-project artifacts.
4. **Throw away your first two queries.** Cold start can return plausible empty answers rather than
   errors. Wait until the server drops off the CPU, then re-run them.
5. **On a mixed-language repo, ask both servers the same question.** Half the findings here came from
   putting one server's answer next to the other's. Either alone looks authoritative.
6. **Report raw output verbatim.** Interpret in a separate step.
7. **Verify column positions with `awk`,** not by eye. A query at the wrong column looks exactly like
   a false negative:
   ```bash
   awk 'NR==19{for(i=1;i<=30;i++) printf "%d:%s ", i, substr($0,i,1); print ""}' File.kt
   ```
8. **Vary the source set on purpose.** For every symbol, know whether the *far end* of the
   relationship — caller, callee, implementor — sits in `src/main` or `src/test`, and test both.
   Without this rule, a limitation scoped to test code looked like a broken feature.
9. **Run the matrix on a second repository of a different shape before you believe any of it.**
   Single- vs. multi-module, languages mixed in one module vs. split across modules, Kotlin in
   `src/main` vs. only in `src/test`. Two conclusions here survived the first repo and died on the
   second, and neither looked fragile at the time.

### Pre-flight

First prove the workspace is real. For jdtls, run the `~/.cache/jdtls` loop from *The trap*; on a
multi-module build it should list every module plus a root entry — `vaadin-boot`'s seven modules came
back as eight entries, Kotlin-only modules included. For kotlin-lsp, `goToDefinition` from a use in
one file to a definition in another. If either fails, **stop**: every later result is meaningless.

Then run the **source-set canary**. Pick a `src/main` function called only from `src/test` and ask
for its `incomingCalls`. If that comes back empty while `findReferences` at the same position lists
the call sites, the server's call hierarchy cannot see tests, and every "nothing calls this" it gives
you means "nothing in `src/main` calls this". kotlin-lsp fails the canary; jdtls passes it on Gradle
and Maven.

### The matrix

For each row, record the result, whether it is correct, and — the most useful column — whether a
failure was a silent wrong answer or an explicit refusal. **Bold** rows are the hard questions that
overturned a conclusion here; without them, a server that is quietly half-blind gets a clean sheet.
Rows marked ‡ have not been run yet.

| Operation | Test | Correct answer looks like |
|---|---|---|
| `hover` | local symbol; dependency symbol; JDK symbol | KDoc/javadoc renders |
| `documentSymbol` | any file | full nested structure |
| `goToDefinition` | same file | jumps |
| `goToDefinition` | **cross-file, same module** | jumps — *rootedness canary* |
| `goToDefinition` | **Kotlin → Java, same module** | jumps |
| `goToDefinition` | **Kotlin → Java, across a module dependency** | jumps |
| `goToDefinition` | **two classes sharing an FQN in unrelated modules, from each side** | each resolves to its own module's class |
| `goToDefinition` | external dependency | jumps, or refuses explicitly |
| `findReferences` | symbol used in ≥3 files | all of them, not just the declaration |
| `findReferences` | **a name that also appears in strings or on a sibling class** | the real ones only — where it beats grep |
| `findReferences` | **a symbol with an identically-named twin in another module** | none of the twin's — watch for over-reporting |
| `findReferences` | ‡ **a Kotlin symbol referenced from Java, via kotlin-lsp** | the Java call sites |
| any | **kotlin-lsp on a `.java` document** (needs a client other than the harness) | answers, or you know it will not |
| `workspaceSymbol` | **a known class name, in each language** | found |
| `prepareCallHierarchy` | expression-body fun; block-body fun | resolves both |
| `incomingCalls` | function with ≥5 known callers | all callers |
| `incomingCalls` | **the same, with callers only in the other language** | all callers, or a refusal |
| `incomingCalls` | ‡ **a `src/main` Kotlin function called from `src/main` Java** | all callers — the language axis without the source-set confound |
| `incomingCalls` | **a `src/main` function called only from `src/test`** | all callers — *source-set canary* |
| `outgoingCalls` | function calling ≥3 things | all callees |
| `outgoingCalls` | **a function calling both `src/main` and `src/test` symbols** | both |
| `outgoingCalls` | **a function whose callees are all in external libraries** | all callees, or a refusal — never "calls nothing" |
| `goToImplementation` | **interface with implementations in both languages** | all of them |
| `goToImplementation` | **implementations across modules, including test code** | all of them |
| rename | a public method used cross-file | every call site updated atomically |

### Suggested subjects

Pick repos that each isolate one variable:

- **Kotlin and Java in one module** — does the language boundary resolve at all?
- **Kotlin and Java in separate modules** — does it survive a project dependency?
- **Two classes sharing an FQN in unrelated modules** — the sharpest disambiguation test there is. An
  `-api` / `-impl` split or a shaded twin may already give you one.
- **A framework-heavy codebase** — any test suite or thin service layer. This is the shape that
  exposes the library-callee rule, and it is far more common than the others.
- **The holes this post leaves** — a polyglot Maven build, a build with a third source set, and
  something large (`vok`, ~576 Kotlin files).

### Concrete first probes

Exact positions and verified values, so you can check your setup against a known answer rather than
against your expectations. Probes already quoted above are not repeated.

`jdbi-orm` at `266e843`:

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

`vaadin-boot` at `86a7988` — these vary source set and module, so run them first on a repo of your
own:

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

`vaadin-boot-example-maven` at `d95c806`, all jdtls. The canary:

```
incomingCalls   Bootstrap.java 15:17 (contextInitialized, src/main, sole caller in src/test)
                → 1 caller: MainViewTest.bootstrapApp, calls at 38:25   ✓ passes on Maven too
```

Then the trap and its control, which only work as a pair: `outgoingCalls` on
`MainViewTest.java 78:17` and `MainView.java 17:12` both come back empty, while
`MainViewTest.java 37:24` — same file, same source set, project callees only — returns its 2 callees.
Run either without the other and you will draw the wrong conclusion.

## Open questions

Roughly cheapest first:

1. **Does kotlin-lsp find *Java* references to a *Kotlin* symbol?** Every `findReferences` here ran
   the other way. It probably works — kotlin-lsp already returns hits inside `.java` files — but the
   verdict leans on it. `jdbi-orm` has the subject: a Java test that references the Kotlin class
   `Person2`.
2. **Does kotlin-lsp's call hierarchy cross languages?** Every clean data point is Kotlin→Kotlin; the
   one cross-language query, `Entity.save()`, had only test-code callers, so the source-set rule
   already explains its empty answer. Needed: a Java `src/main` caller of a Kotlin `src/main` function.
3. **Does kotlin-lsp analyse Kotlin on Maven?** Its Maven import works; the only Maven subject had no
   Kotlin to ask about.
4. **Blind to tests, or to everything but `main`?** Both Gradle subjects have exactly two source sets.
   An `integrationTest` set would tell the two apart, and the workarounds differ.
5. **Does it scale?** 2.6 GB for kotlin-lsp on a small repo; on the seven-module one, 1.4 GB for jdtls
   against 1.7 GB + 1.3 GB for kotlin-lsp — which, for reasons I cannot explain, keeps running two
   instances.
6. **Why does kotlin-lsp's `workspaceSymbol` prefer local properties over exact-name Java classes?** It
   looks less like a language filter than like a different index from the one `goToDefinition` uses.
7. **Does jdtls' FQN merging hit shaded jars?** A relocated package that collides with a project
   package is the same bug in a far more common shape.
8. **Is omitting library callees a reading of the LSP spec, or the same shortcut taken twice?** If it
   is deliberate, `outgoingCalls` is useless by design on any method that wraps a framework, and
   "(this function calls nothing)" is simply false.

Out of reach from a terminal agent: **rename**, and the six other published features the LSP tool
does not expose. They need a different client. Rename no longer settles the docs question — reference
search works — only whether rename is as complete as reference search.

## The part that generalises

The finding that outlives the numbers is not about Kotlin: **when you wire a tool into an agent loop,
how it fails matters as much as how well it works.**

A tool that fails loudly is safe at any quality level: the agent sees the refusal, falls back to
`grep`, and tells you. A tool that fails silently is dangerous in proportion to how much the agent
trusts it, and an empty result is the worst shape a silent failure can take, because "no results"
and "no answer" look the same while implying opposite actions.

Across two servers and three repositories I collected five kinds of empty list: kotlin-lsp's call
hierarchy (*your callers are in a source set I do not read*), jdtls on a Kotlin-called method (*I
cannot read that language*), kotlin-lsp's `workspaceSymbol` on a Java class (roughly the mirror
image), `outgoingCalls` on library callees (*I only report project symbols*), and cold start (*ask me
again in two minutes*). Five causes, one rendering, and each implies the one thing that is not true:
that the server looked and found nothing.

The fourth started out as kotlin-lsp's and turned out to be jdtls' too, word for word. The useful
taxonomy is not "which server fails here" but "which question has an answer this tool never looks
for" — and that framing will transfer to whatever replaces these servers.

`No incoming calls found (nothing calls this function)` is the worst of them, because the
parenthetical is not the result. It is an interpretation the tool has no grounds to make, and an
agent reading it has been handed a conclusion, not data.

Loud failures were rare: `server is starting`, a "not indexed" for library code, and one jdtls
`Internal error` — which the same query shape elsewhere replaced with a quiet half-answer.

Worse than any empty list is **a wrong answer that is not empty.** jdtls' over-long reference list
carries no cue at all: correct paths, lines and columns, every entry real source text containing the
real identifier. An empty list invites a second thought; a confident, well-formed one gets acted on.
**Judge a tool in an agent loop by what its wrong answers look like. The dangerous ones are shaped
exactly like right ones.**

That is also the case for running the matrix more than once. Everything I got wrong, I got wrong
because one repository answered clearly and I mistook a clear answer for a general one.

I would take a server that refuses over one that returns an empty list.
