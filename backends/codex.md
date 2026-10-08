# Codex backend

Adapter: `codex.sh`. Tested with codex-cli 0.154 through 0.160.

## Setup

- `codex` on PATH. Run `delegate check`; `codex doctor` must report `0 fail`.
- Model and provider live in `~/.codex/config.toml` (or a `-p` profile passed through
  `DELEGATE_EXTRA_ARGS`). With a custom provider such as an OpenAI-compatible proxy,
  `codex login status` says "Not logged in". That is expected, and `codex doctor` is the
  real health check.
- Codex auto-loads `AGENTS.md` from the repo root. Put the project's standing rules
  there (a copy of `CLAUDE.md` works). Prompts then only need the task-specific detail.
- Name every MCP server from your Codex config that a headless run must not use in
  `DELEGATE_DISABLE_MCP`. The adapter disables each one per invocation with
  `-c mcp_servers.<name>.enabled=false`, so your interactive config is never modified.

## Gotchas the adapter already handles

- **`</dev/null` is mandatory.** `codex exec` appends stdin as a `<stdin>` block even when
  a prompt argument is given. In a backgrounded shell, stdin is an open pipe that never
  closes, so the run hangs forever after `Reading additional input from stdin...` with no
  events and no file changes. If that line is the only output after a couple of minutes,
  this is the cause.
- **`--approve-for-me` implies `--sandbox workspace-write`.** Combining the two is a hard
  CLI error. Never use `--dangerously-bypass-approvals-and-sandbox`.
- **The MCP server key stays unquoted.** `mcp_servers."my-server".enabled=false` replaces
  the whole table and breaks config loading ("invalid transport").
- **Global flags go before `resume`.** `codex exec resume --last … --approve-for-me` fails
  with "unexpected argument".
- **No `--ephemeral`.** The session has to survive for `resume`.

## Gotchas the orchestrator must handle

- **Stop before resuming.** A live process holds the thread, and `resume` then fails with
  "thread … already has an active writer". Run `delegate stop <wt>` first.
- **Auto-review needs a model.** `--approve-for-me` sends escalations (anything outside
  the sandbox, including writes to the git index under `.git/worktrees/<name>/`) to an
  auto-review model. If that model is missing on your provider, every escalation is
  rejected. Either way, the agent cannot `git add`, `git commit`, `git checkout -- <path>`
  or `git stash` inside the worktree, and the preamble tells it not to try. To restore a
  file without touching the index, use `git show HEAD:<path> > <path>`.
- **Background the dispatcher, not Codex.** Pass `delegate run …` itself as the Bash
  tool's `run_in_background` command. A trailing `&` makes the tracked process a launcher
  that exits at once: the completion notice arrives early, and Codex is left unsupervised
  or gets reaped.

## Event stream

`--json` writes JSONL with the `thread.*` and `turn.*` envelope events plus `item.*`
events (`agent_message`, `command_execution`, `error`, file changes, reasoning, MCP
calls). `backend_progress_filter` turns them into one line each, shows unknown item types
as `[type]`, and skips non-JSON banner lines.
