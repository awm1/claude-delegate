# Template for a new backend adapter. Copy to backends/<name>.sh, implement every
# function, then set DELEGATE_BACKEND=<name>. Contract: backends/CONTRACT.md.

_todo() { echo "backend '$DELEGATE_BACKEND': $1 not implemented" >&2; return 1; }

# Print version info and verify the CLI is installed and authenticated. Non-zero = unusable.
backend_check() { _todo backend_check; }

# $1 = absolute worktree path, $2 = prompt file.
# Run headlessly and non-interactively, sandboxed to $1, with every MCP server in
# $DELEGATE_DISABLE_MCP disabled, stdin from /dev/null, events (ideally JSONL) on stdout.
# Use `exec` so the recorded pid is the agent process. Stay in the foreground.
backend_run() { _todo backend_run; }

# Same as backend_run, but continue the most recent session in $1 with the follow-up in $2.
backend_resume() { _todo backend_resume; }

# $1 = worktree, $2 = pid file written by bin/delegate. Kill the running agent.
backend_stop() { _todo backend_stop; }

# Filter: event stream on stdin -> one human-readable line per interesting event.
# Must not fail on non-JSON lines.
backend_progress_filter() { cat; }
