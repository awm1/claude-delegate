#!/usr/bin/env bash
# Fail if the repo contains anything that looks like a local tie or a secret.
# Extra private patterns (company names, hosts, usernames) come from
# $CHECK_PUBLIC_PATTERNS_FILE, one extended regex per line. Keep that file outside the repo.
set -uo pipefail
cd "$(dirname "$0")/.."

patterns=(
    '/home/[a-z]' '/Users/[A-Za-z]'
    'glpat-[A-Za-z0-9_-]{10,}' 'sk-[A-Za-z0-9]{16,}' 'ghp_[A-Za-z0-9]{20,}'
    'Bearer [A-Za-z0-9._-]{20,}' 'BEGIN [A-Z ]*PRIVATE KEY'
    '(token|secret|password)[[:space:]]*=[[:space:]]*"[^"<$]{8,}"'
)
if [ -n "${CHECK_PUBLIC_PATTERNS_FILE:-}" ] && [ -f "$CHECK_PUBLIC_PATTERNS_FILE" ]; then
    while IFS= read -r p; do [ -n "$p" ] && patterns+=("$p"); done < "$CHECK_PUBLIC_PATTERNS_FILE"
fi

status=0
for p in "${patterns[@]}"; do
    if git grep --untracked -nIiE -e "$p" -- ':!scripts/check-public.sh'; then
        status=1
    fi
done
if command -v gitleaks >/dev/null; then
    gitleaks detect --no-banner --source . || status=1
fi
[ $status -eq 0 ] && echo "check-public: clean" || echo "check-public: FOUND MATCHES" >&2
exit $status
