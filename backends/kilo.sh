# Kilo Code CLI adapter (https://kilo.ai). See kilo.md. Implements backends/CONTRACT.md.

DELEGATE_KILO_AGENT=${DELEGATE_KILO_AGENT:-agents/tdd-subtask}

backend_check() {
    command -v kilo >/dev/null || { echo "kilo not on PATH" >&2; return 1; }
    kilo --version
    if [ -n "$DELEGATE_DISABLE_MCP" ]; then
        echo "warning: kilo has no per-invocation MCP disable; deny these servers in the" \
             "agent's permissions instead: $DELEGATE_DISABLE_MCP" >&2
    fi
}

backend_run() {
    # shellcheck disable=SC2086
    exec kilo run --dir "$1" --agent "$DELEGATE_KILO_AGENT" --auto --format json \
        $DELEGATE_EXTRA_ARGS "$(cat "$2")" </dev/null
}

backend_resume() {
    # shellcheck disable=SC2086
    exec kilo run --dir "$1" --continue --agent "$DELEGATE_KILO_AGENT" --auto --format json \
        $DELEGATE_EXTRA_ARGS "$(cat "$2")" </dev/null
}

backend_stop() {
    local pidfile=$2 pid
    [ -f "$pidfile" ] || { echo "no pid file $pidfile" >&2; return 1; }
    pid=$(cat "$pidfile")
    kill "$pid" 2>/dev/null && echo "stopped kilo pid $pid" || echo "pid $pid not running"
    rm -f "$pidfile"
}

backend_progress_filter() {
    # Event schema not mapped yet: print each event's type, pass non-JSON lines through.
    jq --unbuffered -R -r 'try (fromjson | (.type // "event") | tostring) catch .'
}
