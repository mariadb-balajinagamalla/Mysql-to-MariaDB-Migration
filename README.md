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
- Schema-only dump first, then SQLines Data for parallel load, then finalize objects.

## Orchestrator usage
Interactive (recommended):
```bash
./migration
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

## One-step required envs (config/migration.yaml)
Source:
- `SRC_HOST`, `SRC_PORT`, `SRC_USER`, `SRC_PASS`
- `SRC_DB` or `SRC_DBS` (comma-separated)
- `SRC_ADMIN_USER`, `SRC_ADMIN_PASS` (for creating migration user)
- `SRC_ADMIN_LOCAL=1` to use local socket on source host (recommended)

Target:
- `TGT_HOST`, `TGT_PORT`, `TGT_USER`, `TGT_PASS`
- `TGT_ADMIN_USER`, `TGT_ADMIN_PASS`
- `TGT_ADMIN_LOCAL=1` to use socket on target host (recommended)
- `TGT_SSH_HOST`, `TGT_SSH_USER`, `TGT_SSH_OPTS` (required when running from a third host)

## Two-step required envs (config/migration.yaml)
Source:
- `SRC_HOST`, `SRC_PORT`, `SRC_USER`, `SRC_PASS`
- `SRC_DB` (single DB) or `SRC_DBS` (comma-separated, looped one by one)

Target:
- `TGT_HOST`, `TGT_PORT`, `TGT_USER`, `TGT_PASS`
- `TGT_SSH_HOST`, `TGT_SSH_USER`, `TGT_SSH_OPTS` (if running from a third host)

SQLines Data:
- SQLines Data is available for Linux/Windows only. Run two-step from a Linux host (e.g., a third VM).
- `SQLINESDATA_BIN` (path to sqldata/sqlinesdata binary)
- `SQLINESDATA_CMD` and `SQLINESDATA_CMD_FINALIZE` (single DB)
- `SQLINESDATA_CMD_TEMPLATE` and `SQLINESDATA_CMD_FINALIZE_TEMPLATE` (multi-DB; use `{DB}` placeholder)

## Two-step examples
Single DB:
```yaml
SRC_DB: sakila
SQLINESDATA_CMD: "./sqlinesdata -sd=mysql,user/pass@src:3306/sakila -td=mysql,user/pass@tgt:3306/sakila -smap=sakila:sakila -ss=6 -t=sakila.* -constraints=no -indexes=no -triggers=no -views=no -procedures=no"
SQLINESDATA_CMD_FINALIZE: "./sqlinesdata -sd=mysql,user/pass@src:3306/sakila -td=mysql,user/pass@tgt:3306/sakila -smap=sakila:sakila -ss=6 -t=sakila.* -data=no -ddl_tables=no -constraints=yes -indexes=yes -triggers=yes -views=yes -procedures=yes"
```

Multiple DBs (loop):
```yaml
SRC_DBS: "sakila,world"
SQLINESDATA_CMD_TEMPLATE: "./sqlinesdata -sd=mysql,user/pass@src:3306/{DB} -td=mysql,user/pass@tgt:3306/{DB} -smap={DB}:{DB} -ss=6 -t={DB}.* -constraints=no -indexes=no -triggers=no -views=no -procedures=no"
SQLINESDATA_CMD_FINALIZE_TEMPLATE: "./sqlinesdata -sd=mysql,user/pass@src:3306/{DB} -td=mysql,user/pass@tgt:3306/{DB} -smap={DB}:{DB} -ss=6 -t={DB}.* -data=no -ddl_tables=no -constraints=yes -indexes=yes -triggers=yes -views=yes -procedures=yes"
```

## Multi-DB example
```yaml
SRC_DBS: "sakila,world"
```

## Notes
- Use a fresh `--out` directory per run to avoid step skips.
- Orchestrator mode: `python -m orchestrator.migrationctl plan/run --config config/migration.yaml --mode <one_step|two_step> --out artifacts/<dir>`
