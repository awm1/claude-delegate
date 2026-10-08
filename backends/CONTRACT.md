# Backend adapter contract

A backend is any headless coding-agent CLI. `bin/delegate` sources
`backends/$DELEGATE_BACKEND.sh` and calls these shell functions:

| Function | Arguments | Must |
|---|---|---|
| `backend_check` | – | Verify the CLI is installed and authenticated; non-zero exit when unusable. |
| `backend_run` | `<worktree> <prompt-file>` | Start a new session headlessly in the worktree (see requirements below). Use `exec`, so the pid that `bin/delegate` recorded is the agent. |
| `backend_resume` | `<worktree> <prompt-file>` | Continue the latest session in that worktree with a follow-up prompt, under the same constraints as `backend_run`. |
| `backend_stop` | `<worktree> <pid-file>` | Kill the running agent. |
| `backend_progress_filter` | stdin | Turn the event stream into one readable line per event. Never fail on non-JSON lines. |

Available environment: `DELEGATE_MAIN_REPO`, `DELEGATE_DISABLE_MCP`, `DELEGATE_EXTRA_ARGS`,
`SKILL_DIR`, and any `DELEGATE_<BACKEND>_*` variables you document in `config.example.env`.

## Requirements for `backend_run` and `backend_resume`

1. **Non-interactive.** No TTY prompts and no stdin reads. Always redirect stdin from `/dev/null`.
2. **Sandboxed to the worktree.** File writes stay inside the worktree. Prefer the CLI's
   own sandbox. Never use flags that remove it.
3. **No outward-facing tools.** Every MCP server or integration named in
   `DELEGATE_DISABLE_MCP` is off for this invocation only, without editing the user's
   config. If the CLI cannot do that, `backend_check` must warn (see `kilo.sh`).
4. **Foreground.** The orchestrator backgrounds the whole `delegate run` call. Never
   fork or detach.
5. **Resumable.** Keep the session (no ephemeral mode), so `backend_resume` can feed
   gate failures back to it.
6. **Structured output** on stdout, ideally JSONL, so `backend_progress_filter` can
   report progress while the run is still going.
7. **No secrets in arguments.** Auth comes from the CLI's own config or environment.

## Porting checklist

1. `cp backends/_template.sh backends/<name>.sh` and implement the five functions.
2. Write `backends/<name>.md` covering setup, how the project rules reach the agent
   (`AGENTS.md`, a persona file or a system prompt), and gotchas.
3. Check that `DELEGATE_BACKEND=<name> bin/delegate check` passes.
4. Probe in a scratch repo: `git init`, add `.claude/` to `.gitignore`, commit, then run
   `bin/delegate new probe` and `bin/delegate run <wt> task.md` with a trivial task
   ("add a line to README"). Confirm that:
   - the event stream appears and `bin/delegate progress <log>` renders it;
   - the change lands in the worktree only;
   - `bin/delegate stop` followed by `bin/delegate resume` continues the same session;
   - a disabled MCP server is really unavailable (ask the agent to list its tools).
5. Set `DELEGATE_BACKEND=<name>` in your local config.
