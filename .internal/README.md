# .internal/ - Repository Infrastructure

This folder contains development, maintenance, and infrastructure files that are NOT part of the core plugin functionality.

## Contents

| Directory | Purpose | Original Location |
|-----------|---------|-------------------|
| `repo-keeper/` | Repository maintenance scripts, schemas, workflows | `docs/repo-keeper/` |
| `audits/` | Consistency audits and reports | `docs/audits/` |
| `archive/` | Historical documentation | `docs/archive/` |
| `plans/` | Implementation plans | `docs/plans/` |
| `legacy-templates/` | Deprecated v1.x templates | `templates/legacy/` |
| `tests/` | Manual test procedures and validation | `tests/` |
| `scripts/` | Utility scripts | `scripts/` + `create-issue.sh` |
| `bin/` | Binary utilities (jq) | `bin/` |
| `hooks/` | Custom Claude Code hooks | `.claude/hooks/` |
| `node_modules/` | npm dependencies for schema validation | `node_modules/` |

## For Plugin Users

You do NOT need anything in this folder to use the plugin.

Core plugin files are:
- `/.claude-plugin/` - Plugin manifest
- `/commands/` - Slash commands
- `/skills/` - Plugin skills
- `/data/` - Configuration data
- `/templates/master/` - Master templates
- `/agents/` - Agent definitions

## For Contributors

Run maintenance scripts from the repo root:
```bash
./.internal/repo-keeper/scripts/run-all-checks.sh
```

See `.internal/repo-keeper/README.md` for full documentation.
