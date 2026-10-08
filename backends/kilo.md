# Kilo backend

Adapter: `kilo.sh`. This was the original backend; it is kept as a working fallback and
as a second example of the adapter contract.

## Setup

- `kilo` on PATH.
- Kilo does not auto-load `AGENTS.md` the way Codex does. Create a persona agent that
  encodes the project rules, then set `DELEGATE_KILO_AGENT` to its name:
  ```
  kilo agent create --path .kilo/agent --mode subagent --permissions bash,read,edit,glob,grep
  ```
- There is no per-invocation MCP disable. Deny the servers listed in `DELEGATE_DISABLE_MCP`
  in that agent's permissions. `delegate check` warns while the variable is non-empty.

## Gotchas

- `--worktree` exists only on the top-level `kilo` (TUI) command, not on `kilo run`.
  Passed to `kilo run`, it prints help and exits 0. This is one reason the skill always
  creates worktrees with plain `git worktree add`.
- `--auto` approves every permission that is not explicitly denied, so the agent's
  permission list is the actual sandbox.
- `backend_progress_filter` only prints event types for now. Map the `--format json`
  schema the way `codex.sh` does if you use Kilo regularly.
