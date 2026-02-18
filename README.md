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

## Prerequisites (user privileges)
The tool expects valid privileges to already exist for the entered users.

Admin users (`SRC_ADMIN_USER` / `TGT_ADMIN_USER`):
- Must be able to connect from the orchestrator host.
- Must be able to create/grant migration users.
- Must be able to check/create/drop target database objects as needed by workflow.
- In practice, this usually means admin-level privileges, including grant capability.

Migration users (`SRC_USER` / `TGT_USER`):
- Must be able to connect from the orchestrator host.
- Must have enough source read privileges and target write/object privileges for selected DBs.
- If using one-step with `create_migration_user`, the script attempts to create/grant these users via admin credentials.

Quick verification (run from orchestrator host):

```bash
MYSQL_PWD='***' mysql --protocol=TCP -h<SRC_HOST> -P<SRC_PORT> -u<SRC_ADMIN_USER> -e "SELECT 1;"
MYSQL_PWD='***' mysql --protocol=TCP -h<TGT_HOST> -P<TGT_PORT> -u<TGT_ADMIN_USER> -e "SELECT 1;"
MYSQL_PWD='***' mysql --protocol=TCP -h<SRC_HOST> -P<SRC_PORT> -u<SRC_USER> -e "SELECT 1;"
MYSQL_PWD='***' mysql --protocol=TCP -h<TGT_HOST> -P<TGT_PORT> -u<TGT_USER> -e "SELECT 1;"
```

Optional grant inspection:

```sql
SHOW GRANTS FOR 'admin'@'<orchestrator_ip_or_%>';
SHOW GRANTS FOR 'migrate'@'<orchestrator_ip_or_%>';
```

## Prerequisites (two_step data load)
If you hit foreign key / unique constraint ordering errors during `two_step_parallel_data`, run the following on the **target MariaDB** before starting `two_step`:

```sql
SET GLOBAL FOREIGN_KEY_CHECKS=0;
SET GLOBAL UNIQUE_CHECKS=0;
```

After `two_step_finalize_objects` completes, re-enable both:

```sql
SET GLOBAL FOREIGN_KEY_CHECKS=1;
SET GLOBAL UNIQUE_CHECKS=1;
```

Notes:
- Run these statements using an account with sufficient privileges to set global variables.
- This is a manual DBA pre/post step; the scripts do not toggle these globals automatically.

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

### Binlog (seed + replication)
Best for low-downtime cutover.
- Seeds target from a consistent dump snapshot with embedded binlog coordinates.
- Starts MariaDB replication from MySQL binlog using `REPL_USER`/`REPL_PASS`.
- Verifies replication thread health and lag after start.

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

## Binlog required envs (config/migration.yaml)
Source:
- `SRC_HOST`, `SRC_PORT`, `SRC_USER`, `SRC_PASS`
- `SRC_DB` (single DB) or `SRC_DBS` (comma-separated)
- `SRC_ADMIN_USER`, `SRC_ADMIN_PASS`

Target:
- `TGT_HOST`, `TGT_PORT`, `TGT_USER`, `TGT_PASS`
- `TGT_ADMIN_USER`, `TGT_ADMIN_PASS`

Replication:
- `REPL_USER`, `REPL_PASS`
- Optional: `SRC_BINLOG_FILE`, `SRC_BINLOG_POS` (auto-captured during seed if not set)
- Optional: `BINLOG_COORD_FILE` (default: `artifacts/binlog_coords.env`)
- Optional: `BINLOG_MAX_LAG_SECS` (default: `30`)


## Multi-DB example
```yaml
SRC_DBS: "sakila,world"
```

## Notes
- Use a fresh `--out` directory per run to avoid step skips.
- Orchestrator mode: `python -m orchestrator.migrationctl plan/run --config config/migration.yaml --mode <one_step|two_step|binlog> --out artifacts/<dir>`
- Safety default: migration fails if target DB already exists. Set `ALLOW_TARGET_DB_OVERWRITE=1` only when overwrite is intentional.
