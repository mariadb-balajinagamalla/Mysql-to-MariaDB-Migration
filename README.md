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

# Supported Versions
- MySQL: 8.0
- MariaDB: 11.x (LTS)

## Tools
- mariadb-dump / mysqlpump
- SQLines
- mydumper
- Custom validation scripts

## Prerequisites (required)
- Set `MARIADB_ES_TOKEN` in the environment to download MariaDB Enterprise RPMs.
- Ensure network connectivity from the orchestrator host to both source MySQL and target MariaDB.

## Status
In progress

## Workflow (quick onboarding)
1. Run precheck to assess source MySQL and gather blockers.
2. Prepare MySQL and take backups (system + application schemas).
3. Optionally generate fix SQL for auth plugins/JSON columns.
4. Stop MySQL and swap packages to MariaDB (offline cutover).
5. Start MariaDB, run upgrade, restore system DB, and validate.

Notes:
- Orchestrator mode: `python -m orchestrator.migrationctl assess/run --config config/*.yaml --out artifacts`
- Manual mode: run scripts in `scripts/` in numeric order.
