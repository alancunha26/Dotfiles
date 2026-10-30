---
name: how
description: "Explains subsystem architecture, runtime flow, where code belongs. Use for 'how does X work', 'what is happening with X', 'how is this mounted', 'why is X installed', walkthroughs before a change, 'where should this live', 'which package owns this'. History is why; 'I didn't get it' is bro."
---

# How

## Overrides

- For placement questions ("where should this live", "which package owns this"), end with one recommended location, the evidence for it (closest existing code, import direction, the repo's AGENTS.md or CLAUDE.md layering rules), and the runner-up.

Explore the codebase to answer "how does X work?" questions. Produce architectural explanations at the level of a senior engineer onboarding onto a subsystem, enough to build a working mental model, not so much that it reads like annotated source code.

Every spawn is an `Agent` subagent with `subagent_type: Explore` (read-only). Explorers use `model: sonnet`, and every explainer uses `model: opus`. Pick each subagent's reasoning level and fast or standard speed for the job, per the Subagents section of the **poteto-mode** skill.

## 1. Assess complexity

If the scope is ambiguous, state your interpretation and explore. The user can redirect.

- **Simple** (a single module, a small utility, a narrow question such as "how does function X work"): no explorers. Spawn one explainer that explores and explains in one pass, built from `references/explainer-prompt.md` without the explorer-findings section. Go to step 4.
- **Complex** (a subsystem spanning multiple files or services, a cross-cutting feature, a full architectural overview): go to step 2.

When in doubt, take the simple path.

## 2. Explore (complex only)

Decompose the question into 2 to 4 angles, each a distinct slice of the subsystem. Spawn all explorers in a single message, each with `references/explorer-prompt.md` and its angle filled in.

## 3. Synthesize (complex only)

Once all explorers have returned, spawn one explainer with `references/explainer-prompt.md` and every explorer's findings filled in.

## 4. Present

Present the explainer's output. Light edits for clarity or context from the conversation are fine. Do not substantially rewrite it.

## Output format

The explanation uses the sections defined in `references/explainer-prompt.md`, dropping any that do not apply: Overview, Key Concepts, How It Works, Where Things Live, Gotchas.

Adapted from cursor/plugins pstack (MIT, (c) 2026 Lauren Tan).

## Local rules

Machine-specific rules, if present: references/local.md (read it when it exists).
