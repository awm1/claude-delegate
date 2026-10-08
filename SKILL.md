---
name: delegate
description: "Delegate a scoped implementation subtask to a local headless coding-agent CLI (Codex by default, swappable) running in an isolated git worktree, then independently verify its work against the project's real gates (from its delegate profile) before reporting back or accepting anything. Use when the user asks to delegate/offload/hand off a task to Codex or another agent CLI, or invokes /delegate by name. Do not use for tasks the user wants done directly."
---

## What this is

I (Claude Code) am the orchestrator. I scope the subtask, run a headless agent CLI in its
own git worktree, then verify the result myself against the project's gates. The agent's
own "done" or "tests pass" never counts; only gates I re-run do.

Every command goes through `<skill-dir>/bin/delegate` (below: `delegate`). It reads its
configuration from `<main-repo>/.claude/delegate.local.env`, or from `$DELEGATE_CONFIG`,
and dispatches to `backends/$DELEGATE_BACKEND.sh`. Backend-specific behavior and gotchas
are documented in `backends/<backend>.md`; read it before the first run in a session.
Project gates and rules are in the file at `$DELEGATE_PROFILE`; `delegate config` shows
its path.

## Prerequisites

- `delegate check` passes: the backend is healthy and the worktree root is gitignored.
- The project's standing rules reach the agent: through `AGENTS.md` for Codex, or a
  persona agent for Kilo (see the backend doc).

## Workflow

1. **Scope the subtask.** Write one precise, self-contained task file in the scratchpad.
   Include the exact files or area, concrete acceptance criteria (which failing test
   proves the gap, what passing looks like) and the exact commands to run. Front-load the
   facts you already know: when a fix depends on framework or ORM internals, give the
   agent the established facts or even the literal diff. Agents otherwise spend dozens of
   steps re-reading vendor source. Once you have seen the agent go down a specific rabbit
   hole, forbid it by name. A generic "stay focused" does not work.
   `delegate run` prepends `prompts/preamble.md` (no git writes or stash, no DB or
   credential hunting, no push/MR) and the profile's `## Prompt additions`. Don't repeat
   those. `delegate prompt <task-file>` shows the assembled result.

2. **Create and provision the worktree.**
   `delegate new <branch> [<base-ref>]` runs `git worktree add` under
   `$DELEGATE_WORKTREE_ROOT`, then the provisioning hooks from `provision.d/`, and prints
   the path. Use plain git worktrees, not a CLI's own `--worktree` flag. Then check that
   `git -C <main-repo> status --short` is unchanged.

3. **Run the agent.** Pass `delegate run <worktree> <task-file>` directly as the Bash
   command with `run_in_background: true`. Never append a shell `&`: the completion
   notification would then fire for a launcher that exits at once, and the agent would
   run unsupervised. Note the output file path from the tool result.

   **Watching progress.** Right after launching, start a `Monitor` on
   `delegate progress <output-file>` with a description such as
   `"<backend> progress: <branch>"` and a `timeout_ms` near the cap. If it times out,
   re-arm with `delegate progress <output-file> --new`. A Monitor timeout kills only the
   tail, not the agent. When the user asks for progress, `tail -n 40 <output-file>` and
   summarize it in plain words. The background task's completion notification is the
   authoritative "done" signal; when it arrives, `TaskStop` the Monitor.

4. **Verify; don't trust.** Read the diff yourself (`git -C <wt> status --short`,
   `git -C <wt> diff`), then re-run the gates from the profile's `## Gates` section in
   that worktree. Always check:
   - the tests that prove the change exist and fail without it (read them);
   - new classes are registered (autoload or service config, as the project needs);
   - migrations are idempotent: read them, don't take the agent's word for it;
   - no collateral churn (generated or bundled files outside the task); restore it
     with `git -C <wt> show HEAD:<path> > <path>`;
   - `git stash list | wc -l` is unchanged if the run mentions a stash.

5. **Iterate or hand back.** If a gate fails, either feed it back or take the fix over
   myself. Say which one, rather than looping silently. To feed it back:
   `delegate stop <wt>` (when the process is still alive), write the failure output to a
   follow-up file, then launch `delegate resume <wt> <followup-file>` the same way as
   step 3, with a fresh Monitor. If the agent drifts twice, stop it and write the literal
   change into the prompt.

6. **Report, don't merge.** Summarize the diff, the gate results and the worktree path.
   Committing, pushing, removing the worktree (`git worktree remove --force`, since
   provisioning leaves untracked symlinks) and opening an MR/PR are separate steps, done
   only when the user asks. Never let a delegated run touch issue trackers or monitoring
   (`DELEGATE_DISABLE_MCP` enforces this), and never push on my own initiative.

## Swapping the backend

Set `DELEGATE_BACKEND` in the local config. To add a new CLI, follow
`backends/CONTRACT.md` (copy `_template.sh`, implement five functions, then probe).
