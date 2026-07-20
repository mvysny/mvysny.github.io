---
layout: post
title: The LLM Trifecta, and Why It Isn't the Whole Answer
---

Writing a general-purpose AI assistant is a huge amount of fun. You wire up a
local model, hand it a few tools — read my notes, search the web, send a
message — and suddenly the thing is *useful*. It books, it summarizes, it
remembers. I've been building exactly such an assistant,
[pikuri-assistant](https://codeberg.org/mvysny/pikuri), a privacy-first
agent that runs a local model so your conversation never leaves your machine.

And then you read one security paper and the fun curdles a little, because the
assistant — the *good* one, the one that reads your medical notes and also
browses the web and also sends email — is the single hardest thing to secure in
the entire agent zoo. This post is about why, and about the two defenses I keep
circling: the **lethal trifecta** (a structural fix) and an **automated
prompt-injection detector** (a detective fix). Neither is enough alone. I think
the future is both.

## What the trifecta is

The framing is Simon Willison's, from his post
[The lethal trifecta for AI agents](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/).
An agent is one prompt injection away from disaster when it holds **all three**
of these at once:

1. **Access to private data** — it can read your inbox, your notes, your source,
   your CRM.
2. **Exposure to untrusted content** — any path by which attacker-controlled
   text reaches the model: a web page, an email, a tool result, a calendar
   invite.
3. **A way to send data out** — email, an HTTP request, even a Markdown image
   whose URL the attacker gets to shape.

Remove *any one* leg and the same injection fizzles. An agent that reads your
secrets and browses hostile pages but has no egress can be told to leak — and
has no way to do it. That's the whole game.

The reason you can't just tell the model "ignore malicious instructions" is that
there is no NX bit for tokens. Modern CPUs mark memory as either data or
executable code, and that one bit ended a whole era of exploits. An LLM has no
equivalent: the system prompt, your question, and the poisoned web page all
arrive as one undifferentiated stream of tokens. There is no flag that says
"this part is instructions, that part is only data." That's prompt injection,
and it is unsolved industry-wide.

## Why it matters right now

This stopped being theoretical. In June 2025 Microsoft patched **EchoLeak**
(CVE-2025-32711), a *zero-click* attack on Microsoft 365 Copilot: an attacker
sent an ordinary-looking email, Copilot ingested it while doing its job, hidden
instructions told it to pull private data and embed that data in a link — and
the data left. No user clicked anything. All three legs, one email.

EchoLeak is a textbook trifecta detonation, and it won't be the last. Prompt
injection now sits at the top of the
[OWASP Top 10 for LLM Applications](https://www.securance.com/blog/prompt-injection-the-owasp-1-ai-threat-in-2026/),
and the industry-wide honest summary is Willison's: the guardrail vendors who
advertise catching ~95% of attacks are quoting **a failing grade** — in
security, blocking 95% of attempts means the attacker just sends attempt number
twenty.

So there are two schools of defense, and I want to compare them head-on.

## Objective 1: trifecta break vs. automated injection detector

### The structural fix: break a leg

The trifecta says: don't try to spot the malicious sentence. Arrange things so
that an agent which *reads* a malicious sentence **can't do anything harmful
with it**. Give any untrusted-touching agent at most two of the three legs. This
is the strongest, cheapest defense there is, and it has a property no filter can
match: **it holds even if the model is completely fooled**, because you cannot
call a tool you were never given.

In pikuri this is the first thing to reach for. The vector-DB recall agent has
no network tool at all — it is safe by construction. The OS assistant
[severs the network leg in the kernel](https://codeberg.org/mvysny/pikuri/src/branch/master/book/07-os-assistant.md)
and only reattaches the internet through a quarantined sub-agent behind a
human-authored gate. The full reasoning lives in the
[security chapter](https://codeberg.org/mvysny/pikuri/src/branch/master/book/06-security.md).

Here's the honest problem: **the trifecta break cripples the very assistant you
wanted.** A general assistant's whole appeal *is* the trifecta. You want it to
read your private notes (leg 1), pull in a web page or an email (leg 2), and act
on the result by sending something (leg 3). Take a leg away and you've amputated
the feature. That's exactly why `pikuri-assistant` is
[the last, still-unfinished chapter](https://codeberg.org/mvysny/pikuri/src/branch/master/book/13-assistant.md):
it's the one binary that reaches for all three legs on purpose, and there is no
clean structural cut that leaves it whole.

Privilege separation helps less than you'd hope, too. Push egress into a
sub-agent and the parent can just *ask* the sub-agent to send the thing. A
summary of a secret still contains the secret. The boundary between agents
filters *instructions*, not *content* — and content fidelity is exactly what an
exfiltration attack needs.

### The detective fix: scan for the injection

The other school says: inspect the untrusted text and refuse it if it looks like
an attack. Run a mechanical pre-pass for the obvious tricks (zero-width
characters, bidi overrides, tag characters) and then an LLM-driven scan of every
field for injection-shaped instructions. Pikuri ships a version of this as the
[MCP Verifier](https://codeberg.org/mvysny/pikuri/src/branch/master/book/05-mcp.md).

And it is genuinely useful — it catches the low-effort stuff, and it never
amputates a leg, so your assistant stays whole. But it is **best-effort, not
airtight**, and you must design around that. An LLM detector is itself an LLM
reading attacker-controlled text; adversarial phrasing that fools the main model
tends to fool the scanner too — you can even just tell the detector to ignore
the injection. This is Willison's other, older warning:
[you can't solve AI security problems with more AI](https://simonwillison.net/2022/Sep/17/prompt-injection-more-ai/).
A filter built from the same opaque machinery it's guarding gives you no
guarantee — unlike SQL parameterization, there's no point where you can prove the
attack is neutralized. It's the 95%-is-a-failing-grade problem wearing a
different hat. Worse, a detector's coverage is only as wide as where you run it:
pikuri's Verifier checks a tool's *registration-time* description but not the
bytes it *returns at runtime* — and runtime is exactly where the poisoned web
page shows up.

| | Break the trifecta | Injection detector |
|---|---|---|
| **Fails safe when the model is fooled?** | Yes — the tool isn't there | No — a fooled scanner passes it |
| **Keeps the assistant fully capable?** | No — amputates a leg | Yes — nothing removed |
| **Coverage** | Total, for the removed leg | Only where you run it; misses runtime bytes |
| **Confidence** | Provable | Statistical, <100% |

Read that table and the trap is obvious: the structural fix is *reliable but
crippling*, the detective fix is *capable but leaky*. You are asked to pick
between an assistant that's safe and useless and one that's useful and unsafe.

## Objective 2: an educated guess about where this goes

Here's what I think happens next.

**Prompt injection attacks will get worse, not better — because we will keep
handing agents more power.** The whole trajectory of this field is toward
agents that touch more of your life: your calendar, your bank, your home, your
codebase, your car. Every capability we add is a new leg or a fatter one, and
the economic pressure is entirely one-directional — a more capable assistant is
a more valuable assistant, and nobody ships the crippled version. So the attack
surface grows monotonically. EchoLeak was the opening move.

**No LLM-based detector will ever be 100%.** As long as the detector is a model
reading untrusted tokens, it inherits the exact weakness it's guarding against.
Expecting a scanner to hit 100% is expecting the NX bit to emerge from a
statistical process. It won't. It'll get better — 95, 98, 99 — and every one of
those is still a failing grade against an adversary who retries.

So neither defense wins alone, and that points at the actual answer:

**The way forward is a combination — structural where you can afford it,
detective everywhere else, and a non-LLM decision point between the two.** Break
the legs you don't need; you'll be surprised how many you don't. For the legs
you must keep, wrap them in detection *and* in mechanisms that don't depend on a
model's judgment at all. The most promising of those, to me, is
[the human as author, not approver](https://codeberg.org/mvysny/pikuri/src/branch/master/ideas/more-confirmers.md):
once private data has entered the context, the outbound query or URL has to be
*retyped by a human*, not merely approved. A patient human approving requests
fails to encoding and slow drip — patience actually makes the covert channel
*wider*. But a covert channel cannot survive being retyped by someone who isn't
trying to leak. That's a real trifecta break, and crucially it lives *outside*
the LLM.

The other piece is knowing when you're exposed at all. A
[trifecta detector](https://codeberg.org/mvysny/pikuri/src/branch/master/ideas/trifecta-detector.md)
— a boot-time check that tags each tool as private/untrusted/egress, unions the
legs an agent can reach (including through its sub-agents), and warns when one
agent holds all three — is a smoke alarm, not a firewall. It can't prove you're
safe. It can tell you *which leg to break*, which is the first useful question.

Put together: the detector tells you you're standing in the trifecta; the
structural cut removes a leg where the feature can spare it; the injection
scanner filters the untrusted leg you kept; and a non-LLM author-gate stands
between the untrusted step and the egress step for the cases where you couldn't
cut anything. No single layer is trustworthy. The stack might be.

## Building it in the open

This is the design I'm building toward in
[pikuri](https://codeberg.org/mvysny/pikuri) — a privacy-first assistant on a
local model, small enough to
[audit in an evening](https://codeberg.org/mvysny/pikuri/src/branch/master/book/06-security.md),
where the security posture is structural first and detective second rather than
the other way round. The assistant chapter is still a stub, and honestly that's
the point: the general assistant is the hard case, and I'd rather ship it late
and honest than early and leaking. If any of this is your problem too, the book
and the design notes are all in the open.
