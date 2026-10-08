# Symlink dependency directories (e.g. node_modules) from the main checkout. Run inside
# the worktree. A whole-directory symlink is safe for npm, because .bin/* are relative
# symlinks with no __DIR__ resolution. The links are untracked, so removing the worktree
# later needs `git worktree remove --force`. That removes only the links, not the targets.
set -euo pipefail
: "${DELEGATE_MAIN_REPO:?}"
for dir in ${DELEGATE_LINK_DIRS:-node_modules}; do
    if [ -e "$DELEGATE_MAIN_REPO/$dir" ] && [ ! -e "$dir" ]; then
        mkdir -p "$(dirname "$dir")"
        ln -s "$DELEGATE_MAIN_REPO/$dir" "$dir"
    fi
done
