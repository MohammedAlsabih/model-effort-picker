# model-effort-picker

A Claude skill that recommends which Claude model and effort level to start a session with, then keeps checking quietly during the work and speaks up only when a change would help.

Based on Anthropic's guide [Which Claude model should you build with?](https://claude.dev/blog/which-claude-model-should-you-build-with/). The recommendations live in a table inside `SKILL.md`. Update that table by hand when the guide changes.

## What it does

- **On the first request of a session:** classifies the task and suggests a model and an effort level, for example "Start this session with Sonnet 5.5 · effort medium". If you are already on that model it carries on with the task. If not, it pauses before doing any work so you can switch while the context is still small, then you resend or reply "continue".
- **During the work:** checks again at checkpoints, such as repeated failures, a task that turns out simpler or bigger than expected, heavy log reading, a very large context, or the end of a phase. It stays silent unless it has a change to suggest.
- **Subagents:** when Claude spawns a subagent, the skill picks the cheapest model that fits the job, for example Haiku for reading logs, Sonnet for a scoped edit, and Fable for planning a migration. It also skips delegation when the work is small or is one chain of dependent steps.
- **Language:** answers in the language you write in.

The skill only recommends. You switch models yourself, with `/model` and `/effort` in Claude Code or from the model menu in the Claude app.

## Install

### Claude app (claude.ai, desktop, mobile)
1. Download this repo and zip the `model-effort-picker/` folder. The zip must contain the folder itself, not just the files inside it.
2. Go to **Customize > Skills**, click **+**, then **Create skill**, then **Upload a skill**.
3. Upload the zip.

### Claude Code
```bash
git clone https://github.com/MohammedAlsabih/model-effort-picker.git
mkdir -p ~/.claude/skills
cp -r model-effort-picker/model-effort-picker ~/.claude/skills/
```
Then run `/skills` in Claude Code to check that `model-effort-picker` is listed.

To make sure the skill loads in every session and before every subagent, add this to `~/.claude/CLAUDE.md`:

```markdown
## Model routing
At the start of every session, and before spawning any subagent, load the `model-effort-picker` skill and follow it: recommend the session's model and effort on the first request, and set each subagent's model from its routing table.
```

## Optional: periodic-review hook (Claude Code only)

A `PostToolUse` hook reminds Claude every 25 tool calls to run the review. Set `MODEL_REVIEW_EVERY` to change the interval.

```bash
mkdir -p ~/.claude/hooks
cp model-effort-picker/model-effort-picker/hooks/model-review.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/model-review.sh
```
Then merge `model-effort-picker/hooks/settings-hook.json` into `~/.claude/settings.json`. If that file already has a `"hooks"` key, add the `PostToolUse` entry under it rather than replacing the file. Run `/hooks` to confirm the hook is loaded.

The hook works on macOS and Linux and needs no `jq` or Python. On Windows, use WSL or Git Bash.

## Updating

Edit the table in `model-effort-picker/SKILL.md` and change the "Last updated" date. People who installed through Claude Code get the update with `git pull` followed by the copy step again. People who uploaded the zip need to upload a new zip.
