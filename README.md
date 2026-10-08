# claude-delegate

A [Claude Code](https://claude.com/claude-code) skill. Claude acts as the orchestrator
and delegates a scoped coding task to a local headless agent CLI in an isolated git
worktree: [Codex](https://github.com/openai/codex) by default, or anything else that
implements a small shell adapter. Claude then verifies the result itself against the
project's real gates before reporting back. The agent's own "tests pass" is never
accepted.

## Install

```sh
git clone <this-repo> ~/claude-delegate
# globally:
ln -s ~/claude-delegate ~/.claude/skills/delegate
# or for one project (make sure .claude/ is gitignored there):
ln -s ~/claude-delegate <repo>/.claude/skills/delegate
```

## Configure

```sh
cp ~/claude-delegate/config.example.env <repo>/.claude/delegate.local.env
cp ~/claude-delegate/profiles/example-php-symfony.md <repo>/.claude/delegate.profile.md
$EDITOR <repo>/.claude/delegate.local.env   # set DELEGATE_PROFILE to the copied profile
~/claude-delegate/bin/delegate check
```

The config file only holds paths, server names and flags. **It never holds secrets.**
Model/provider credentials stay in the backend's own config (e.g. `~/.codex/config.toml`),
which this skill does not read, copy or modify. Set `DELEGATE_DISABLE_MCP` to every MCP
server in that config that a headless run must not use (issue trackers, error monitoring,
anything that can write outside the worktree).

| File | Purpose |
|---|---|
| `SKILL.md` | The workflow Claude follows. |
| `bin/delegate` | Dispatcher: `check`, `config`, `new`, `provision`, `run`, `resume`, `stop`, `progress`, `prompt`. |
| `backends/` | One adapter per agent CLI, plus `CONTRACT.md` and `_template.sh`. |
| `provision.d/` | Worktree setup hooks (dependency symlinks, local config links, Composer classmap). |
| `prompts/preamble.md` | Safety rules prepended to every task. |
| `profiles/` | Example project profile: gates to re-run, project rules for the agent. |
| `scripts/check-public.sh` | Leak scan to run before pushing changes to this repo. |

## Swapping the agent CLI

Follow [`backends/CONTRACT.md`](backends/CONTRACT.md): copy `_template.sh` to
`backends/<name>.sh`, implement `backend_check`/`run`/`resume`/`stop`/`progress_filter`,
probe it in a scratch repo, then set `DELEGATE_BACKEND=<name>`.

## Contributing

Run `scripts/check-public.sh` before every push. It fails on anything that looks like a
local path, an internal host or a token.

## License

MIT
