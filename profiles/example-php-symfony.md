# Delegate profile: example PHP/Symfony project

A profile tells the orchestrator which gates to re-run (step 5 of SKILL.md) and adds
project-specific rules to every prompt. Copy this file next to your local config, e.g.
`<repo>/.claude/delegate.profile.md`, and point `DELEGATE_PROFILE` at it. Only the
`## Prompt additions` section is sent to the agent. The orchestrator reads the rest.

## Provisioning

`DELEGATE_PROVISION_HOOKS="link-local-config php-composer-classmap"`, with
`DELEGATE_LINK_FILES` set to the gitignored config file(s), e.g. `config/parameters.yml`.

## Gates

Run inside the worktree after reading the diff yourself:

- Unit tests: `vendor/bin/phpunit -c phpunit.xml.dist <paths>`. Prefer a config that does
  not rebuild a database in its bootstrap.
- Coding standard: `vendor/bin/phpcs --standard=<ruleset.xml> <changed files>`.
- API contract tests (Dredd, Schemathesis, ...): only when an endpoint changed. When
  they need a shared database, defer them to CI.
- `composer dump-autoload` was run if new classes were added.
- Migrations are idempotent: read them yourself.

## Prompt additions

- Run unit tests with `vendor/bin/phpunit -c phpunit.xml.dist <path>`. Write plain
  `TestCase` unit tests only; leave kernel/database tests to CI.
- After creating a PHP class, run `composer dump-autoload`.
- Use `#[DataProvider('method')]` attributes, not `@dataProvider` annotations.
