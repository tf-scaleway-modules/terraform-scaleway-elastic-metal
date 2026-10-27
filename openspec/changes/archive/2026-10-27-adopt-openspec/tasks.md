# Tasks

## 1. Tooling
- [x] 1.1 First adoption: there is no Agent OS content to remove
- [x] 1.2 Install the `openspec-*` skills in `.claude/skills/` and `.opencode/skills/`
- [x] 1.3 Pin `node` and `openspec` in `mise.toml`; add `spec-validate` and `spec-setup` tasks and `scripts/openspec-setup.sh`
- [x] 1.4 Add `.gitlab/specs.yml` (`validate:specs`) and `OPENSPEC_VERSION` in `.gitlab/global.yml`

## 2. Configuration and docs
- [x] 2.1 Fill `openspec/config.yaml` `context`, `rules` and `operations` for this module (git-cliff CHANGELOG, no `tests/` yet)
- [x] 2.2 Fill `AGENTS.md` and add `CLAUDE.md`
- [x] 2.3 Add the OpenSpec workflow to the README "Contributing" section

## 3. Baseline specs
- [x] 3.1 Write delta specs for `module-contract`, `ssh-keys`, `servers`, `flexible-ips` from the current code
- [x] 3.2 `openspec validate --all --strict` passes (same command as the `validate:specs` CI job)
- [x] 3.3 Archive the change and replace the `TBD` purposes in the main specs
- [x] 3.4 `pre-commit run` passes on the changed files
