---
layout: post
title: The State of Java and Kotlin Language Servers
date: 2026-09-15 12:45:28 +0300
---

> **DRAFT — working document.** Verified facts are marked `[verified]` with a date; things I
> believe but have not run are marked `[unverified]`. The measurement section is deliberately
> unfinished: the protocol is written, the numbers are not filled in. See *How to verify this
> yourself* at the end — that section is written for an agent to execute.

An agent editing a codebase has two ways to answer "what else touches this?": `grep`, or a
language server. The difference is not convenience. `grep` finds text and cannot tell you what
it missed; a language server finds *symbols* and knows the difference between a call and a
comment. Which one your agent gets is mostly decided by which language you picked, and — as it
turns out — by something much dumber than that.

This is a snapshot as of **September 2026**. Every number here will rot; the methodology at the
bottom is the part meant to outlive it.

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
buildNumber      263.4702.0
productCode      ILS
```

with a bundled JetBrains Runtime (`jbr/`) and `intellij.*` platform jars. The community server
is a plain Java app with none of those. If you are benchmarking, check `product-info.json`
before you believe anything.

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
something narrower than it sounds. **This is the single most important open question in this
post** and the protocol below is built to answer it.

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

Two dead ends, so nobody repeats them: `[verified 2026-09-15]` nuking `~/.cache/jdtls/<ws>` does
not help, because the cache was never the problem. And subagents cannot be used to work around
it — they inherit the parent's working directory, *and* the LSP tool is not exposed to them at
all (five `ToolSearch` variants returned nothing).

`[unverified]` A subagent also reported receiving a `Tool loaded.` notice immediately after a
`ToolSearch` that had returned `No matching deferred tools found`, twice, with no schema
attached. Possibly a harness bug; worth reproducing before claiming it.

## What I can say about quality, honestly

`[verified 2026-09-15, but under a broken root — treat as a floor, not a measurement]`

Working, even with no workspace model:

- **`hover`** — KDoc plus a synthesized signature. Genuinely good. On a built project it
  resolved nullability correctly (`data class Person(id: Long?, …)`); on an unbuilt one it got
  that same parameter wrong (`id: Long`), which is itself a useful signal that hover quality
  tracks project state.
- **`documentSymbol`** — flawless. Full nested structure, companion objects, properties with
  getters, even test-DSL method names containing spaces.
- **`prepareCallHierarchy`** — resolved a method.

Unknown, because the root was wrong when I tried: `findReferences`, `incomingCalls`,
`goToDefinition`, `workspaceSymbol`, `goToImplementation`, and whether rename does what its
README entry implies.

Also observed `[verified]`: cold start is a race — a query issued immediately after the first
one failed outright with `Cannot send notification to LSP server 'plugin:kotlin-lsp:kotlin-lsp':
server is starting`. An agent needs to handle that, and retry rather than conclude.

## How to verify this yourself

*This section is written to be handed to an agent. It is the deliverable of this post.*

### Ground rules

1. **Run the session from the repository root.** `cd ~/work/my/<repo> && claude`. Not a
   subagent. Not a session rooted elsewhere. This is the whole trap.
2. **Establish ground truth with `grep` first, then ask the LSP.** Never the other way round —
   otherwise you are calibrating your expectations to the tool you are testing.
3. **Build the project first** so dependencies resolve, then restart the language server, so
   results are not unresolved-project artifacts.
4. **Report raw output verbatim.** No interpretation in the same step as measurement.
5. **Verify column positions with `awk`,** not by eye. I wasted a cycle querying character 13 of
   the wrong line and briefly believed a false negative:
   ```bash
   awk 'NR==19{for(i=1;i<=30;i++) printf "%d:%s ", i, substr($0,i,1); print ""}' File.kt
   ```

### Pre-flight: prove the workspace is rooted

Before any measurement, confirm the server imported the project — see the `~/.cache/jdtls` loop
above for Java. For Kotlin, the cheap proof is a cross-file `goToDefinition`: pick a symbol
defined in file A and used in file B, and jump from B to A. If that fails, **stop** — every
subsequent result is meaningless.

### The matrix to fill in

For each operation, record: result, correct?, and how it failed if it did (silent wrong answer
vs. explicit refusal — that distinction is the most interesting output).

| Operation | Test | Correct answer looks like |
|---|---|---|
| `hover` | local symbol; dependency symbol; JDK symbol | KDoc/javadoc renders |
| `documentSymbol` | any file | full nested structure |
| `goToDefinition` | same file | jumps |
| `goToDefinition` | **cross-file, same module** | jumps — *rootedness canary* |
| `goToDefinition` | **Kotlin → Java, same module** | jumps |
| `goToDefinition` | external dependency | jumps, or documented as unsupported |
| `findReferences` | symbol used in ≥3 files | all of them, not just the declaration |
| `workspaceSymbol` | a known class name | found |
| `prepareCallHierarchy` | expression-body fun; block-body fun | resolves both |
| `incomingCalls` | function with ≥5 known callers | all callers |
| `outgoingCalls` | function calling ≥3 things | all callees |
| `goToImplementation` | interface with ≥2 impls | all impls |
| rename | a public method used cross-file | every call site updated atomically |

Rename is the highest-value cell: it is on the published feature list while find-references is
not, so measuring it directly settles whether that omission is real or a docs gap. The LSP tool
in Claude Code exposes no rename operation, so this one needs a different client — the VS Code
extension, or an LSP client driven by hand.

### Suggested subjects

Pick repos that isolate one variable each:

- **Kotlin + Java in one Gradle module** — does the cross-language boundary resolve?
  (`jdbi-orm`: 21 Kotlin / 51 Java)
- **Large pure-Kotlin multi-module** — does it scale? (`vok`: ~576 Kotlin files)
- **Maven rather than Gradle** — the README claims both; verify.
- **A repo with an already-healthy jdtls workspace** — as the Java control.

### Concrete first probes

In `jdbi-orm`, with the project built, ground truth established by `grep`:

```
findReferences  Person.kt 19:13   (age)            → expect Person.kt:43, AbstractMappingTests.kt:112,116,
                                                     AbstractDatabaseTests.kt:34, DaoTest.kt:25
incomingCalls   Person.kt 68:9    (withZeroNanos)  → expect DaoTest.kt:165,166,191,192 and
                                                     AbstractMappingTests.kt:46  (5 callers)
goToDefinition  Person.kt 68:96   (.withZeroNanos) → expect AbstractMappingTests.kt:272
goToDefinition  Person.kt 30:5    (Entity)         → expect Entity.java, same module (cross-language)
findReferences  EntityMeta.java 38:20              → expect cross-file; ~41 mentions repo-wide
```

## Open questions

1. Does `findReferences` work when properly rooted? **The whole post turns on this.**
2. Does rename work, and is it reference-search-complete?
3. Is the omission of find-references and go-to-definition from the README a docs gap or real?
4. Does the Kotlin→Java boundary resolve inside one module?
5. Maven vs Gradle — any difference?
6. Current state of `fwcd/kotlin-language-server`.
7. Does the paid IntelliJ LSP extension work outside VS Code, i.e. is it usable by a terminal
   agent at all?
8. How does jdtls compare on the same matrix, measured rather than assumed? My Java column so
   far rests on reputation, not on a control I actually ran.

## The part that generalises

Whatever the numbers turn out to be, one finding here is not about Kotlin and does not expire:
**when you wire a tool into an agent loop, how it fails matters as much as how well it works.**

A tool that degrades loudly is safe at any quality level — the agent detects the refusal, falls
back to `grep`, tells you. A tool that degrades silently is dangerous in proportion to how much
the agent trusts it, and an empty result is the worst possible shape for a silent failure,
because "no results" and "no answer" are indistinguishable to the caller while implying opposite
actions.

I would take a reference search that refuses over one that returns an empty list.
