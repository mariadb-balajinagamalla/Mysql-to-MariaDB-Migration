# migrationctl (orchestrator scaffold)

© 2026 MariaDB plc. All rights reserved.

This tool is proprietary software developed and maintained by MariaDB plc. It is provided to customers and partners under approved usage terms.

This is a production-oriented *orchestration layer* for your existing shell scripts.
It provides:

- Non-interactive CLI suitable for CI
- State/checkpoint file for resume/re-run
- Structured JSON report + human log
- Safety gates + warnings (assessment)
- Thin execution wrapper over ./scripts/*.sh

## Quick start (local)
From your repo root (where `scripts/` exists):

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r orchestrator/requirements.txt

# run assessment (read-only)
python -m orchestrator.migrationctl assess --config config/source.yaml --out artifacts

# run (will call shell scripts configured in step map)
python -m orchestrator.migrationctl run --config config/migration.yaml --out artifacts --non-interactive
```

## Notes
- Edit `orchestrator/step_map.yaml` to map phases to your existing shell scripts.
- The orchestrator assumes scripts are executable and runnable from repo root.
