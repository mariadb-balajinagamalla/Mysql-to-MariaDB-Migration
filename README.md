# MySQL to MariaDB Migration

© 2026 MariaDB plc. All rights reserved.

This tool is proprietary software developed and maintained by MariaDB plc. It is provided to customers and partners under approved usage terms.

## Purpose
Private repository to design, execute, and validate end-to-end MySQL to MariaDB migrations in a repeatable and auditable manner.

## Scope
- Schema migration
- Data migration
- User & privilege migration
- Authentication plugin Compatibility
- Validation & rollback planning

## Supported Versions
- MySQL: 8.0
- MariaDB: 11.x (LTS)

## Prerequisites (required)
- MariaDB must be pre-installed on the target and configured per customer requirements.
- Ensure network connectivity from the orchestrator host to both source MySQL and target MariaDB.
- The orchestrator can run on a third host; SSH access to the target is required for validation.
- The tool prompts for required inputs if not provided in config/env.

## Status
In progress

## Migration playbooks
### One-step (dump/restore)
Best for smaller databases and standard maintenance windows.
- Uses `mariadb-dump` (or `mysqldump`) on source and streams to target `mariadb`.
- Supports single DB (`SRC_DB`) or multi-DB (`SRC_DBS="db1,db2"`).
- Strips DEFINER clauses by default to avoid permission errors on target.

### Two-step (schema + parallel data)
Best for larger datasets or tighter windows.
- Schema-only dump first, then parallel load, then finalize objects.
- Assumes SQLines Data is installed and available on `PATH` (`sqldata` or `sqlinesdata`), or set `SQLINESDATA_BIN`.
- Requires existing migration users (`SRC_USER`/`TGT_USER`); preflight fails fast if those logins are not ready.

## Orchestrator usage
Interactive (recommended):
```bash
./migration
```

Orchestrator CLI (non-interactive):
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r orchestrator/requirements.txt
python -m orchestrator.migrationctl plan --config config/migration.yaml --mode one_step --out artifacts/plan
python -m orchestrator.migrationctl run --config config/migration.yaml --mode one_step --out artifacts/run
```

Plan:
```bash
python3 -m orchestrator.migrationctl plan --config config/migration.yaml --mode one_step --out artifacts/plan
```

Run:
```bash
python3 -m orchestrator.migrationctl run --config config/migration.yaml --mode one_step --out artifacts/run
```

Resume:
```bash
python3 -m orchestrator.migrationctl resume --config config/migration.yaml --mode one_step --out artifacts/run
```

Notes:
- `./migration` runs assess → plan → run, and resumes automatically if a previous run failed.
- `./migration` asks for source/target admin credentials at runtime; root is blocked by default unless `ALLOW_ROOT_USERS=1`.
- Saving `config/migration.yaml` is optional and defaults to `No`; if saved, passwords are redacted by default.

## One-step required envs (config/migration.yaml)
Source:
- `SRC_HOST`, `SRC_PORT`, `SRC_USER`, `SRC_PASS`
- `SRC_DB` or `SRC_DBS` (comma-separated)
- `SRC_ADMIN_USER`, `SRC_ADMIN_PASS` (for creating migration user)

Target:
- `TGT_HOST`, `TGT_PORT`, `TGT_USER`, `TGT_PASS`
- `TGT_ADMIN_USER`, `TGT_ADMIN_PASS`
- `TGT_SSH_HOST`, `TGT_SSH_USER`, `TGT_SSH_OPTS` (required when running from a third host)

## Two-step required envs (config/migration.yaml)
Source:
- `SRC_HOST`, `SRC_PORT`, `SRC_USER`, `SRC_PASS`
- `SRC_DB` (single DB) or `SRC_DBS` (comma-separated, looped one by one)
- `SRC_ADMIN_USER`, `SRC_ADMIN_PASS`

Target:
- `TGT_HOST`, `TGT_PORT`, `TGT_USER`, `TGT_PASS`
- `TGT_ADMIN_USER`, `TGT_ADMIN_PASS`
- `TGT_SSH_HOST`, `TGT_SSH_USER`, `TGT_SSH_OPTS` (if running from a third host)

Optional:
- `SQLINESDATA_BIN` (auto-detected: `sqldata` then `sqlinesdata`)


## Multi-DB example
```yaml
SRC_DBS: "sakila,world"
```

## Notes
- Use a fresh `--out` directory per run to avoid step skips.
- Orchestrator mode: `python -m orchestrator.migrationctl plan/run --config config/migration.yaml --mode <one_step|two_step> --out artifacts/<dir>`
- Safety default: migration fails if target DB already exists. Set `ALLOW_TARGET_DB_OVERWRITE=1` only when overwrite is intentional.
