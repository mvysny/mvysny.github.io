---
layout: post
title: So You Hooked ChatGPT Up to Your Gmail
date: 2026-08-08 12:43:16 +0300
---

[Last time](../thunderbird-trifecta/) I walked a prompt injection past every
guard in an email assistant, and showed the payload — a stolen password —
leaving inside a friendly-looking reply, spelled out as a first-letter acrostic
that a human reviewer reads straight past. Fair objection: *that was a homemade
Ruby gem you wrote yourself, Martin. Who runs those? I just clicked "Connect
Gmail" in ChatGPT.*

Right. And that's the point of this post. The premise survives the move to the
mass market completely intact — the wiring got more popular, not more secure.
Depending on how you connected the two, you land somewhere between "the same
hole" and "a bigger one," and the ugly part is that **you probably don't know
which.**

## The one idea to carry over

From the [last post](../thunderbird-trifecta/), keep exactly one tool — the test
that decides whether a human "in the loop" is worth anything:

> **Does the human see the exact bytes that leave, or only a proxy for them?**

A plaintext compose window passes: what's on screen is what egresses, byte for
byte. A `curl` behind a confirmation prompt fails: you approve a command, the
bytes are computed later. An attachment fails: you approve a filename and a
thumbnail, not the bits inside. Hold that test; we're going to run three
real-world Gmail wirings through it.

And keep the conclusion, because it's about to matter more, not less: a human
reading a plaintext window is the **strongest** gate that exists, and the
acrostic beat it anyway. So watch what happens when the gate gets *weaker*.

## The gate depends entirely on the plumbing

"Connect ChatGPT to my Gmail" is not one thing. It's at least two, and they sit
on opposite ends of the danger scale. I verified both as they stand in August
2026.

### Stack A — the native connector (the good case)

OpenAI's own Gmail connector, added in mid-2026, lets ChatGPT search, read,
draft, and send from your inbox. Its sending is
deliberately clipped: **one email per prompt, with your approval, and no
attachments.** (Same shape on the Claude side of the house.)

That restraint is real and worth naming. "No attachments" is precisely the
[attachment corollary](../thunderbird-trifecta/) from last post — they removed
the surface where a human approves a reference to bytes nobody saw. "Approval
required" puts a human commit in the path. This is the *careful* wiring.

And it is **no safer than the compose window that already lost.** It's an
*approver* seat: you read the model's proposed message and bless it. The acrostic
walks past it for the identical reason it walked past Thunderbird — you approve
prose that reads as benign, because it *is* benign prose that also happens to
spell something. If anything the payload visibility is *worse*: a compose window
shows you a literal plaintext draft, whereas a chat approval tends to show you a
rendered, summarized "I'll send this to Lauri…" — closer to approving an intent
than inspecting bytes. Best case, it ties the thing that already failed.

One sting for European readers: that native sending connector is **not available
in the EU, EEA, Switzerland, or the UK** — it's US-only, paid-plan, web-only.
Which means the reader most likely to want "ChatGPT, answer my mail" *here* is
pushed straight past the careful option into the next one.

### Stack B — a community MCP server (the common case)

The next one is what you actually install when the native path is missing or too
limited: a community Gmail MCP server. The most popular is
[GongRzhe/Gmail-MCP-Server](https://github.com/GongRzhe/Gmail-MCP-Server),
billed as Gmail-for-Claude-Desktop, ~18 tools. I read what it exposes. Its
`send_email` tool:

- **sends immediately** through the Gmail API — it is not a draft;
- accepts **HTML bodies**, **CC**, **BCC**, and **file attachments**;
- has **no confirmation step of its own.**

Every single field there is one that the Thunderbird gem in the last post
*deliberately refused* — plaintext only, no attachments, a five-field allowlist,
a recipient-novelty warning. This server offers the whole attack surface back,
gift-wrapped. HTML alone reopens `<span style="display:none">`; attachments
reopen the invisible-bits channel; BCC reopens the exact route that got *caught*
in v1 last time — here with nothing to catch it.

So where's the gate? One layer up, in the host. Claude Desktop pops a tool-
approval dialog before a call runs. But it carries an **"Always allow"** button,
and there's a small cottage industry of
[auto-approve](https://github.com/PyneSys/claude_autoapprove_mcp) hacks because
people find the clicking tedious. Click it once for `send_email` and the human
leaves the loop entirely. Now it's **autonomous egress** — the top-left, loudest
cell of the whole trifecta grid. This is EchoLeak with your own hands on the
wrench.

## The inversion: a weak gate needs no acrostic

Here's the thing that took me a second to see, and it's the reason this post
exists instead of a one-line footnote on the last one.

The acrostic was a *sophisticated* attack. Why did it have to be? Because the
gate was strong — a human was reading the literal outbound bytes, so the payload
had to survive a careful human read, so it had to be disguised as ordinary prose.
**The strength of the gate is what forced the attacker to be clever.**

Weaken the gate and the attacker climbs right back up the ladder they were
pushed down. No human reading the bytes? Then don't bother with an acrostic —
dump the secret as raw base64 in an HTML comment, or as an attachment, or just
`bcc: attacker@evil.com`. The cleverness was never the point; it was a tax
imposed by a strong reviewer. Remove the reviewer and the tax goes to zero.

So **attack sophistication is inversely proportional to gate strength**, and
that cuts exactly the wrong way for "it's more convenient now." The convenient
wiring — autonomous send, always-allowed — is the one that needs the *least*
clever attack to leak everything.

## The scorecard

Run all three through the one test. `:private` (your mailbox) and `:untrusted`
(every message you didn't write) are present in all of them — it's email.

| wiring | egress leg | human sees the bytes? | attachments / HTML? | what an attacker needs |
|---|---|---|---|---|
| Thunderbird compose (last post) | approver — plaintext window | **yes, byte-exact** | no / no | an acrostic (and it works) |
| ChatGPT/Claude native connector | approver — chat approval | partial (rendered summary) | no / partial | an acrostic (and it works) |
| Community MCP + "Always allow" | **autonomous** | **no** | **yes / yes** | nothing clever — raw base64, BCC, an attachment |

The careful native option, at its best, *ties* the gate that already lost. The
common DIY option, once you click the button everyone clicks, removes the gate
altogether. Nowhere on this table is there a wiring that *wins* — because none
of them is the one move that would: **author, not approver.** Not one of these
makes you type the outbound bytes yourself; they all let the model propose and
you bless. And a covert channel survives being blessed. It does not survive being
retyped by someone who isn't trying to leak.

## What to actually do

- **If you only need "read my mail and answer questions about it," grant only
  that.** That's two legs, not three — the trifecta broken by construction. The
  trap is that most Gmail MCP servers register `send_email` whether you asked for
  it or not, and a poisoned model can call any tool it was handed. Prefer a
  server or a config that *doesn't expose a send tool at all* over one where you
  simply intend not to use it.
- **If you grant send, never "Always allow" it.** That per-call human read is
  your entire firewall. It's a weak one — see the acrostic — but weak beats
  absent by a wide margin, and clicking the button trades the last thing you have
  for saving one click per email.
- **Prefer draft-only over send.** A tool that writes to your Gmail *Drafts* and
  stops, leaving you to open Gmail and send, is much closer to the plaintext
  compose window than an autonomous `send_email` is. It's still an approver seat,
  so the acrostic still applies — but it puts the real, rendered message in front
  of you in Gmail's own UI instead of a chat summary.
- **Understand what you've actually got: a smoke alarm, not a firewall.** Same as
  last post. The honest ceiling of every wiring above is that it stops *silent*
  exfil — bytes nobody saw — and only the ones where a human genuinely reads the
  message stop even that. The clean-by-construction fix, author-not-approver,
  isn't on the menu of any mainstream connector I could find.

## The uncomfortable summary

Last post ended on the strongest human gate losing to the weakest trick. Going
mainstream didn't fix that hole — it *distributed* it, and mostly with a weaker
gate or no gate at all. The most careful mass-market option ties the thing that
already failed; the most common one hands you a one-click path to fully
autonomous exfiltration and, being ungated, doesn't even require the attacker to
be clever about it.

The trifecta didn't need a vulnerability in any of this. It just needed an inbox,
a model doing its job well, and a Send button someone was willing to stop
pressing.

*The assistant, the guards I keep referring to, and the design notes are all in
the open at [codeberg.org/mvysny/pikuri](https://codeberg.org/mvysny/pikuri).*
