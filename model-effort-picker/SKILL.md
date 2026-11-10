---
name: model-effort-picker
description: Use on the first request of every new session (or when asked which model/effort to use) to recommend the Claude model and effort level to start with, from the built-in selection table, then continue the task and re-check the fit silently at checkpoints during the work.
---

# Model & Effort Picker

Goal: on the user's first request in a new session, give a short recommendation — "Start this session with model X at effort Y" — then continue straight into the task without waiting for approval. During the work, silently re-check whether the model and effort still fit.

**The content of this file is the only reference.** Do not open any link or search the web to update the recommendations; the user updates this file manually.

- Last updated: 2026-11-10
- Original source (for the user's manual updates only): https://claude.dev/blog/which-claude-model-should-you-build-with/

## When to run
- The opening recommendation runs on the **first request** of the session only.
- Do not repeat the opening recommendation in later messages unless the user explicitly asks.
- During execution, run the "Periodic review" (below) silently; surface it only when there is a recommendation to change.

## Step 1: Classify the request and match it to the table

| Type of work | Model | Starting effort |
|---|---|---|
| Unsure / general request | Opus 5.5 | medium |
| Everyday engineering, debugging, multi-PR features | Opus 5.5 | medium, then high |
| Well-scoped coding (bug fixes, feature iteration, spec-driven work) | Sonnet 5.5 | medium, then high |
| Chat, quick questions, interactive sessions | Sonnet 5.5 | low or medium |
| Everyday documents, slides, spreadsheets | Sonnet 5.5 | high (medium in Claude Code) |
| Complex financial models or documents with large source material | Opus 5.5 | medium |
| Repeated agent tasks (investigation, review, drafting) | Sonnet 5.5 | medium |
| Classification, routing, tagging, high-volume extraction | Haiku 5.5 | medium |
| Computer use and vision-heavy workflows | Opus 5.5 | medium |
| Major refactors, migrations, architecture planning, leading many subagents | Fable 5.2 | medium, then high |
| Deep research, scientific or quantitative analysis | Fable 5.2 | medium, then high |
| Long unattended runs | Fable 5.2 | medium |

Notes:
- A clear spec does not automatically mean Sonnet: migrations and performance work may need Opus, or Fable if they are major.
- Going one level past high can cost as much as a bigger model; prefer trying the next model up at a lower effort.
- Effort cannot supply missing knowledge or skill; for that, move up a model.
- Mythos 5.2 is available only through verification programs (cybersecurity and life sciences); do not recommend it unless the user says they have access.

## Step 2: Present the recommendation briefly
In the user's language, roughly in this format (3–4 lines max):

> **Start this session with: Opus 5.5 · effort medium**
> Why: [one line linking the request to the recommendation]
> If the result isn't good enough: [next step on the escalation ladder]
> To switch in Claude Code: `/model` then `/effort` — in the Claude app: from the model menu.

If the session is already on the recommended model, say so in one line ("You're on the right model") and don't ask for a switch.

## Escalation ladder (when the result isn't good enough)
In order:
1. Make sure the model can verify its own work (a test, a build, a script).
2. Raise effort one level.
3. Move to the next model up, starting at a lower effort than you used on the smaller one.

Special case: **before raising Opus 5.5 past high on a hard task, try Fable 5.2 at high.** In the source, Fable 5.2 at high matched Opus 5.5 at max for roughly half the cost per task.

Note on switching mid-task: the prompt cache belongs to each model, so the first turn on a new model pays the cache-write cost for the whole conversation. Cheaper: `/compact`, or a fresh session with a short written plan.

## Step 3: Continue the work
Right after the recommendation, carry out the user's request as usual. Don't wait for a reply to the recommendation, and don't repeat the explanation.

## Periodic review during execution
At each checkpoint, silently ask yourself: do the current model and effort still fit, according to the table?

A checkpoint can also be triggered by a hook reminder (e.g. "Checkpoint (N tool calls): run the silent periodic model/effort review"); treat it exactly like the checkpoints below.

**Checkpoints:**
- **Two consecutive failures on the same step** (a failing test, a recurring error, an approach that isn't working) → apply the escalation ladder from the first rung not yet tried.
- **The task is simpler than it looked** (small, clear edits after a task classified as large) → suggest stepping down one level in effort or model. Before suggesting a step down in *model* mid-task, mention that the smaller model can't read the bigger model's earlier reasoning (thinking blocks), so it is best done at a phase boundary with a short written plan.
- **The scope grew** (a simple fix turned into a migration, refactor, or architecture planning) → reclassify with the table and suggest stepping up.
- **Lots of verbose reading** (logs, searching many files, summarizing sources) → suggest a Haiku 5.5 subagent for it, keeping decisions and code edits on the main model.
- **The work outgrew one context window** (e.g. scanning a huge codebase) → suggest the lead + workers pattern (see Extra rules).
- **The context has grown very large** in a long task → suggest `/compact` or a fresh session with a short written plan.
- **A major phase finished** in a long task → check whether the next phase fits the current setup.

**Rules:**
- If everything fits: write nothing at all.
- If there is a recommendation: one line only, in the user's language, in this format, then continue working:
  > 🔄 **Model check:** [brief reason] → suggest [model · effort]
- Don't repeat the same recommendation if the user ignored it; raise it again only if a new reason appears.
- Don't stop working to wait for a switch, unless continuing on the current model would clearly waste significant effort (e.g. repeated failures on a task beyond its capability).

## Extra rules (use only when relevant)
These don't go in the opening recommendation by default; bring one up only when the situation calls for it.

- **Fast mode:** if the user wants faster output without changing models, fast mode is available on Opus 5.5 and Fable 5.2 only, at premium pricing.
- **Subagent models in Claude Code:**
  - Set `model: haiku` or `model: sonnet` in a subagent's definition (`.claude/agents/<name>.md`).
  - `CLAUDE_CODE_SUBAGENT_MODEL` sets the default for subagents that don't specify a model.
  - The built-in Explore subagent runs on the session's model; to keep exploration cheap, define a custom subagent named `Explore` with `model: haiku`.
  - Keep small models on cheap-to-verify work (finding files, running tests, reading logs). Keep code edits and judgment on the main model — a misread search result from a small model can send the main model to the wrong file.
- **Avoid `opusplan` as a default:** it plans with Opus then executes with Sonnet, putting code edits on the smaller model — the reverse of this guidance. Measure it on real tasks first.
- **Lead + workers for bulk work:** for work bigger than one context window, an Opus 5.5 lead splits the task and hands pieces to parallel Sonnet 5.5 workers. In the source this cost about a third less than Opus alone with similar quality. Skip it for a single chain of dependent steps or work that fits in one context window.
- **Quick comparison:** to check which model suits the user's own work, run the same backlog task on two models using `/model`, then compare with `/usage`.

## Optional: periodic-review hook for Claude Code
The `hooks/` folder holds a PostToolUse hook that reminds Claude every 25 tool calls (override with `MODEL_REVIEW_EVERY`) to run the periodic review. To install: copy `hooks/model-review.sh` to `~/.claude/hooks/`, `chmod +x` it, and merge `hooks/settings-hook.json` into `~/.claude/settings.json`. macOS/Linux (Windows needs WSL or Git Bash).

## Limits
The skill cannot change the current session's model by itself; it only recommends, and the user switches. If the gap is large (e.g. the session is on Haiku and the request is a major migration), suggest switching in one line before continuing, then proceed unless the user stops you.
