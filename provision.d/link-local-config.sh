# Symlink gitignored per-checkout files (local parameters, .env.local, ...) from the main
# checkout into the worktree. Run inside the worktree.
set -euo pipefail
: "${DELEGATE_MAIN_REPO:?}"
for f in ${DELEGATE_LINK_FILES:-}; do
    if [ -e "$DELEGATE_MAIN_REPO/$f" ] && [ ! -e "$f" ]; then
        mkdir -p "$(dirname "$f")"
        ln -s "$DELEGATE_MAIN_REPO/$f" "$f"
    fi
done
