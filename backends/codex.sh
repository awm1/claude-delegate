# Codex CLI adapter (https://github.com/openai/codex). See codex.md for the reasons
# behind each flag. Sourced by bin/delegate; implements backends/CONTRACT.md.

DELEGATE_CODEX_APPROVAL_ARGS=${DELEGATE_CODEX_APPROVAL_ARGS:---approve-for-me}

_codex_global_args() {
    # Global flags. They must precede the `resume` subcommand.
    local wt=$1 s
    # shellcheck disable=SC2206
    CODEX_ARGS=($DELEGATE_CODEX_APPROVAL_ARGS --json -C "$wt")
    for s in $DELEGATE_DISABLE_MCP; do
        # Bare dotted key: quoting the server name replaces the whole table.
        CODEX_ARGS+=(-c "mcp_servers.$s.enabled=false")
    done
    # shellcheck disable=SC2206
    CODEX_ARGS+=($DELEGATE_EXTRA_ARGS)
}

backend_check() {
    command -v codex >/dev/null || { echo "codex not on PATH" >&2; return 1; }
    codex --version
    codex doctor --summary
}

backend_run() {
    _codex_global_args "$1"
    # </dev/null is mandatory: codex exec always reads stdin and blocks forever on an
    # open pipe that never sends EOF.
    exec codex exec "${CODEX_ARGS[@]}" "$(cat "$2")" </dev/null
}

backend_resume() {
    _codex_global_args "$1"
    exec codex exec "${CODEX_ARGS[@]}" resume --last "$(cat "$2")" </dev/null
}

backend_stop() {
    local pidfile=$2 pid
    [ -f "$pidfile" ] || { echo "no pid file $pidfile" >&2; return 1; }
    pid=$(cat "$pidfile")
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid"
        echo "stopped codex pid $pid"
    else
        echo "pid $pid not running"
    fi
    rm -f "$pidfile"
}

backend_progress_filter() {
    jq --unbuffered -R -r '
      try fromjson catch empty
      | select(.type != null)
      | .type as $t
      | if $t == "turn.started" then "turn started"
        elif $t == "turn.completed" then "turn completed (" + ((.usage.output_tokens // 0)|tostring) + " output tokens)"
        elif $t == "turn.failed" then "turn FAILED: " + ((.error.message // .error // "unknown")|tostring)
        elif $t == "item.started" and .item.type == "command_execution" then "running: " + .item.command
        elif $t == "item.completed" then
          (.item.type) as $it
          | if $it == "agent_message" then "agent: " + ((.item.text // "") | gsub("\n";" ") | .[0:300])
            elif $it == "error" then "error: " + (.item.message // "")
            elif $it == "command_execution" then "cmd exit " + ((.item.exit_code // "?")|tostring) + ": " + .item.command + " :: " + ((.item.aggregated_output // "") | gsub("\n";" ") | .[0:200])
            else "[" + $it + "]"
            end
        else empty
        end
    '
}
