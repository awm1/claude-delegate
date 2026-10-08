# Provision vendor/ for a Composer project with classmap autoloading. Run inside the worktree.
#
# A single `ln -s $MAIN/vendor vendor` is broken: vendor/bin shims and tools such as
# paratest resolve __DIR__ through the symlink to the MAIN checkout. They load its
# autoloader next to the worktree's own autoloader, and because both declare the same
# ComposerAutoloaderInit<hash> class, PHP fails with "Cannot redeclare class".
# Package directories are therefore symlinked (cheap, read-only), and anything that is
# rewritten by dump-autoload or does its own __DIR__ path climbing is copied for real.
set -euo pipefail
: "${DELEGATE_MAIN_REPO:?}"
MAIN=$DELEGATE_MAIN_REPO
REAL=" ${DELEGATE_REAL_COPY_VENDOR:-composer bin} "

[ -d "$MAIN/vendor" ] || { echo "no $MAIN/vendor; run composer install there first" >&2; exit 1; }
[ ! -e vendor ] || { echo "vendor/ already exists, skipping" >&2; exit 0; }

mkdir vendor
for entry in "$MAIN"/vendor/*/; do
    name=$(basename "$entry")
    if [[ "$REAL" == *" $name "* ]]; then
        cp -r "$entry" "vendor/$name"
    else
        ln -s "$entry" "vendor/$name"
    fi
done
cp "$MAIN/vendor/autoload.php" vendor/autoload.php
composer dump-autoload -q
