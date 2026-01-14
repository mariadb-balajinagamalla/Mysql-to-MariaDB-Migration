from __future__ import annotations

import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List

from .report import Gate, GateStatus, WarningItem, Report


@dataclass
class AssessmentResult:
    source: Dict[str, Any]
    target: Dict[str, Any]
    gates: List[Gate]
    warnings: List[WarningItem]
    inventory: Dict[str, Any]


def _read_tsv(path: Path) -> List[List[str]]:
    if not path.exists():
        return []
    rows: List[List[str]] = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = line.strip()
        if not line:
            continue
        rows.append(line.split("\t"))
    return rows


def _run_precheck(repo_root: Path, cfg: Dict[str, Any], outdir: Path, log) -> Path:
    precheck_out = outdir / "precheck"
    precheck_out.mkdir(parents=True, exist_ok=True)

    client = cfg.get("client", {}) or {}
    env_cfg = cfg.get("env", {}) or {}

    env = {
        "MYSQL_BIN": str(client.get("mysql_bin", "mysql")),
        "HOST": str(client.get("host", "127.0.0.1")),
        "PORT": str(client.get("port", 3306)),
        "USER": str(client.get("user", "root")),
        "OUTDIR": str(precheck_out),
        "CHECKS_DIR": str(repo_root / "sql" / "checks"),
    }

    # Pass through env vars like MYSQL_PWD (do not log secrets)
    for k, v in env_cfg.items():
        env[str(k)] = str(v)

    script = repo_root / "scripts" / "00_precheck.sh"
    if not script.exists():
        raise RuntimeError(f"Missing precheck script: {script}")

    log(f"RUN precheck -> {script}")
    p = subprocess.run(
        ["bash", str(script)],
        cwd=str(repo_root),
        capture_output=True,
        text=True,
        env=env,
    )

    # Log stdout/stderr (should not contain password)
    if p.stdout:
        for ln in p.stdout.splitlines():
            log(ln)
    if p.stderr:
        for ln in p.stderr.splitlines():
            log(ln)

    if p.returncode != 0:
        raise RuntimeError(f"precheck failed rc={p.returncode} (see artifacts/precheck/precheck.err)")

    return precheck_out


def run_assessment_checks(cfg: Dict[str, Any], report: Report, repo_root: Path, outdir: Path) -> AssessmentResult:
    gates: List[Gate] = []
    warnings: List[WarningItem] = []
    inventory: Dict[str, Any] = {}

    pre = _run_precheck(repo_root, cfg, outdir, report.log)

    # Load TSVs
    mysql_version = _read_tsv(pre / "mysql_version.tsv")          # expected: 1 row: version, comment?
    innodb = _read_tsv(pre / "innodb_settings.tsv")               # expected: 1 row: file_per_table, fast_shutdown
    auth = _read_tsv(pre / "auth_plugins.tsv")
    json_cols = _read_tsv(pre / "json_columns.tsv")
    enc = _read_tsv(pre / "compression_encryption.tsv")
    engines = _read_tsv(pre / "engines_summary.tsv")
    sizes = _read_tsv(pre / "schema_sizes.tsv")

    schema_charsets = _read_tsv(pre / "schema_charsets.tsv")
    tcoll = _read_tsv(pre / "mysql8_collations.tsv")
    ccoll = _read_tsv(pre / "mysql8_column_collations.tsv")
    sql_mode = _read_tsv(pre / "sql_mode.tsv")
    definers = _read_tsv(pre / "definers_inventory.tsv")
    partitions = _read_tsv(pre / "partitioned_tables.tsv")
    plugins = _read_tsv(pre / "active_plugins.tsv")

    # Source/target
    version = mysql_version[0][0].strip() if mysql_version and mysql_version[0] else ""
    source = {
        "type": "mysql",
        "version": version,
        "host": (cfg.get("client", {}) or {}).get("host", ""),
        "port": (cfg.get("client", {}) or {}).get("port", ""),
    }
    target = cfg.get("target", {"type": "mariadb", "version": "LTS"})

    # Gates
    allowed = {"5.7", "8.0", "8.4"}
    major_minor = ".".join(version.split(".")[:2]) if version else ""
    gates.append(
        Gate(
            "mysql_version_supported",
            GateStatus.PASS if major_minor in allowed else GateStatus.FAIL,
            {"version": version, "allowed": sorted(list(allowed))},
        )
    )

    innodb_file_per_table = ""
    innodb_fast_shutdown = ""
    if innodb and len(innodb[0]) >= 2:
        innodb_file_per_table = innodb[0][0].strip()
        innodb_fast_shutdown = innodb[0][1].strip()

    gates.append(
        Gate(
            "innodb_file_per_table_is_1",
            GateStatus.PASS if innodb_file_per_table == "1" else GateStatus.FAIL,
            {"value": innodb_file_per_table},
        )
    )

    # Warnings/Inventory
    if innodb_fast_shutdown and innodb_fast_shutdown != "0":
        warnings.append(
            WarningItem(
                "innodb_fast_shutdown_not_0",
                "MEDIUM",
                {"value": innodb_fast_shutdown, "required_before_shutdown": 0},
            )
        )

    auth_lines = ["\t".join(r) for r in auth if r]
    if auth_lines:
        warnings.append(WarningItem("mysql_sha_or_caching_auth_users", "HIGH", {"count": len(auth_lines), "rows_sample": auth_lines[:200]}))
    inventory["auth_plugin_users"] = {"count": len(auth_lines)}

    json_lines = ["\t".join(r) for r in json_cols if r]
    if json_lines:
        warnings.append(WarningItem("json_columns_present", "MEDIUM", {"count": len(json_lines), "rows_sample": json_lines[:200]}))
    inventory["json_columns"] = {"count": len(json_lines)}

    enc_lines = ["\t".join(r) for r in enc if r]
    inventory["encryption_or_compression"] = {"count": len(enc_lines)}
    if enc_lines:
        warnings.append(WarningItem("encryption_or_compression_detected", "HIGH", {"count": len(enc_lines), "rows_sample": enc_lines[:200]}))

    inventory["engines"] = {"rows": ["\t".join(r) for r in engines[:200]]}
    inventory["schema_sizes_mb"] = {"rows": ["\t".join(r) for r in sizes[:200]]}
    inventory["schema_charsets"] = {"rows": ["\t".join(r) for r in schema_charsets[:200]]}

    tcoll_lines = ["\t".join(r) for r in tcoll if r]
    if tcoll_lines:
        warnings.append(WarningItem("mysql8_table_collations_present", "MEDIUM", {"count": len(tcoll_lines), "rows_sample": tcoll_lines[:200]}))
    inventory["mysql8_table_collations"] = {"count": len(tcoll_lines)}

    ccoll_lines = ["\t".join(r) for r in ccoll if r]
    if ccoll_lines:
        warnings.append(WarningItem("mysql8_column_collations_present", "MEDIUM", {"count": len(ccoll_lines), "rows_sample": ccoll_lines[:200]}))
    inventory["mysql8_column_collations"] = {"count": len(ccoll_lines)}

    sql_mode_val = sql_mode[0][0] if sql_mode and sql_mode[0] else ""
    if sql_mode_val:
        warnings.append(WarningItem("sql_mode_review_recommended", "MEDIUM", {"value": sql_mode_val}))
    inventory["sql_mode"] = {"value": sql_mode_val}

    definers_lines = ["\t".join(r) for r in definers if r]
    if definers_lines:
        warnings.append(WarningItem("definer_objects_present", "MEDIUM", {"count": len(definers_lines), "rows_sample": definers_lines[:200]}))
    inventory["definers"] = {"count": len(definers_lines)}

    partition_lines = ["\t".join(r) for r in partitions if r]
    if partition_lines:
        warnings.append(WarningItem("partitioned_tables_present", "MEDIUM", {"count": len(partition_lines), "rows_sample": partition_lines[:200]}))
    inventory["partitioned_tables"] = {"count": len(partition_lines)}

    plugin_lines = ["\t".join(r) for r in plugins if r]
    if plugin_lines:
        warnings.append(WarningItem("active_plugins_review_recommended", "LOW", {"count": len(plugin_lines), "rows_sample": plugin_lines[:200]}))
    inventory["active_plugins"] = {"rows": plugin_lines[:200]}

    return AssessmentResult(source=source, target=target, gates=gates, warnings=warnings, inventory=inventory)
