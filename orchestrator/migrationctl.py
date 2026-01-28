from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Optional, Dict, Any, List

import typer
import yaml

from .state import StateStore
from .report import Report, GateStatus, StepStatus
from .runner import run_step
from .checks import run_assessment_checks, AssessmentResult

app = typer.Typer(add_completion=False, help="MySQL -> MariaDB migration orchestrator\n© 2026 MariaDB plc ")

DEFAULT_OUTDIR = "artifacts"
DEFAULT_STATE = "state.json"
DEFAULT_REPORT = "report.json"
DEFAULT_LOG = "run.log"

def _load_yaml(path: Path) -> Dict[str, Any]:
    if not path.exists():
        raise typer.BadParameter(f"Config file not found: {path}")
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}

def _ensure_outdir(outdir: Path) -> None:
    outdir.mkdir(parents=True, exist_ok=True)

def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]

def _load_step_map(repo_root: Path) -> Dict[str, Any]:
    step_map_path = repo_root / "orchestrator" / "step_map.yaml"
    if not step_map_path.exists():
        raise typer.BadParameter(f"Missing step map: {step_map_path}")
    return _load_yaml(step_map_path)

def _resolve_mode(cfg: Dict[str, Any], cli_mode: Optional[str]) -> str:
    if cli_mode:
        return cli_mode.strip().lower()
    return (cfg.get("mode") or "offline").lower()

def _validate_mode(step_map: Dict[str, Any], mode: str) -> None:
    modes = step_map.get("modes", {}) or {}
    if mode not in modes:
        available = ", ".join(sorted(modes.keys()))
        raise typer.BadParameter(f"Unknown mode/playbook: {mode}. Available: {available}")

def _require_env(env: Dict[str, str], keys: List[str], mode_value: str) -> None:
    missing = [k for k in keys if not env.get(k)]
    if missing:
        raise typer.BadParameter(
            f"Missing required env vars for mode '{mode_value}': {', '.join(missing)}"
        )

@app.command()
def assess(
    config: Path = typer.Option(..., "--config", "-c", help="Source DB config YAML (read-only)."),
    out: Path = typer.Option(DEFAULT_OUTDIR, "--out", "-o", help="Output directory for artifacts."),
    non_interactive: bool = typer.Option(True, "--non-interactive", help="Never prompt; CI-safe."),
):
    """Run read-only assessment: safety gates + warnings + inventory."""
    repo_root = _repo_root()
    _ensure_outdir(out)

    # Initialize state + report
    state_path = out / DEFAULT_STATE
    report_path = out / DEFAULT_REPORT
    log_path = out / DEFAULT_LOG

    state = StateStore(state_path)
    report = Report(report_path, log_path)

    cfg = _load_yaml(config)
    report.start_run(mode="assessment", config_path=str(config))

    # Perform assessment checks (read-only)
    result: AssessmentResult = run_assessment_checks(cfg, report, repo_root, out)

    # Persist summary
    report.set_source(result.source)
    report.set_target(result.target)
    report.set_gates(result.gates)
    report.set_warnings(result.warnings)
    report.set_inventory(result.inventory)

    # Gate decision
    if any(g.status == GateStatus.FAIL for g in result.gates):
        report.finish_run(success=False, message="Assessment failed: one or more hard gates failed.")
        typer.echo("ASSESSMENT: FAIL (see artifacts/report.json and run.log)")
        raise typer.Exit(code=2)

    report.finish_run(success=True, message="Assessment passed. Ready to plan/run.")
    typer.echo("ASSESSMENT: PASS (see artifacts/report.json and run.log)")


@app.command()
def plan(
    config: Path = typer.Option(..., "--config", "-c", help="Migration config YAML."),
    out: Path = typer.Option(DEFAULT_OUTDIR, "--out", "-o", help="Output directory for artifacts."),
    mode: Optional[str] = typer.Option(
        None,
        "--mode",
        "--playbook",
        "-m",
        help="Execution mode/playbook (e.g., offline, local, one_step, two_step, near_zero).",
    ),
):
    """Generate a plan from config + step map (no execution)."""
    repo_root = _repo_root()
    _ensure_outdir(out)

    report = Report(out / DEFAULT_REPORT, out / DEFAULT_LOG)
    report.start_run(mode="plan", config_path=str(config))

    cfg = _load_yaml(config)
    step_map = _load_step_map(repo_root)

    mode_value = _resolve_mode(cfg, mode)
    _validate_mode(step_map, mode_value)
    phases = step_map.get("modes", {}).get(mode_value, [])
    steps: List[Dict[str, Any]] = []
    for ph in phases:
        steps.extend(step_map.get("phases", {}).get(ph, []))

    env = cfg.get("env", {}) or {}
    env = {str(k): str(v) for k, v in env.items()}
    # Allow environment variables to override/extend config envs.
    env = {**env, **os.environ}
    if mode_value in ("one_step", "two_step"):
        _require_env(
            env,
            ["SRC_HOST", "SRC_USER", "SRC_PASS", "SRC_DB", "TGT_HOST", "TGT_USER", "TGT_PASS"],
            mode_value,
        )
        if mode_value == "one_step" and env.get("SKIP_INSTALL_MARIADB") not in ("1", "true", "TRUE", "True"):
            _require_env(env, ["MARIADB_ES_TOKEN"], mode_value)
        if mode_value == "one_step":
            if not (env.get("SRC_ADMIN_USER") and env.get("SRC_ADMIN_PASS")):
                report.log("WARN: SRC_ADMIN_USER/PASS not set; using SRC_USER/PASS as admin.")
            if not (env.get("TGT_ADMIN_USER") and env.get("TGT_ADMIN_PASS")):
                report.log("WARN: TGT_ADMIN_USER/PASS not set; using TGT_USER/PASS as admin.")
        if env.get("ALLOW_ROOT_USERS") not in ("1", "true", "TRUE", "True"):
            if env.get("SRC_USER") == "root" or env.get("TGT_USER") == "root":
                raise typer.BadParameter("SRC_USER/TGT_USER must not be root. Set ALLOW_ROOT_USERS=1 to override.")
    if mode_value == "two_step":
        if not (env.get("SQLINESDATA_CMD") or env.get("SQLINESDATA_BIN")):
            raise typer.BadParameter(
                "Missing SQLines configuration for mode 'two_step': "
                "set SQLINESDATA_CMD or SQLINESDATA_BIN + SQLINESDATA_ARGS"
            )
        if not (env.get("SQLINESDATA_CMD_FINALIZE") or env.get("SQLINESDATA_ARGS_FINALIZE")):
            raise typer.BadParameter(
                "Missing finalize configuration for mode 'two_step': "
                "set SQLINESDATA_CMD_FINALIZE or SQLINESDATA_ARGS_FINALIZE"
            )
    if mode_value == "near_zero":
        _require_env(
            env,
            ["NEAR_ZERO_REPLICATION_CMD", "NEAR_ZERO_CDC_CMD", "NEAR_ZERO_CUTOVER_CMD"],
            mode_value,
        )

    report.set_plan({"mode": mode_value, "phases": phases, "steps": steps})
    report.finish_run(success=True, message="Plan generated (no execution).")
    typer.echo("PLAN: generated in artifacts/report.json")


@app.command()
def run(
    config: Path = typer.Option(..., "--config", "-c", help="Migration config YAML."),
    out: Path = typer.Option(DEFAULT_OUTDIR, "--out", "-o", help="Output directory for artifacts."),
    non_interactive: bool = typer.Option(True, "--non-interactive", help="Never prompt; CI-safe."),
    mode: Optional[str] = typer.Option(
        None,
        "--mode",
        "--playbook",
        "-m",
        help="Execution mode/playbook (e.g., offline, local, one_step, two_step, near_zero).",
    ),
):
    """Execute migration steps (offline mode) with resume-safe state tracking."""
    repo_root = _repo_root()
    _ensure_outdir(out)

    state = StateStore(out / DEFAULT_STATE)
    report = Report(out / DEFAULT_REPORT, out / DEFAULT_LOG)
    report.start_run(mode="run", config_path=str(config))

    cfg = _load_yaml(config)
    step_map = _load_step_map(repo_root)

    mode_value = _resolve_mode(cfg, mode)
    _validate_mode(step_map, mode_value)
    phases = step_map.get("modes", {}).get(mode_value, [])
    steps: List[Dict[str, Any]] = []
    for ph in phases:
        steps.extend(step_map.get("phases", {}).get(ph, []))

    report.set_plan({"mode": mode_value, "phases": phases, "steps": steps})
    
   #executor = cfg.get("executor", {}) or {}

    # Execute steps sequentially
    env = cfg.get("env", {}) or {}
    env = {str(k): str(v) for k, v in env.items()}
    # Allow environment variables to override/extend config envs.
    env = {**env, **os.environ}

    if mode_value in ("one_step", "two_step"):
        _require_env(
            env,
            ["SRC_HOST", "SRC_USER", "SRC_PASS", "SRC_DB", "TGT_HOST", "TGT_USER", "TGT_PASS"],
            mode_value,
        )
        if mode_value == "one_step" and env.get("SKIP_INSTALL_MARIADB") not in ("1", "true", "TRUE", "True"):
            _require_env(env, ["MARIADB_ES_TOKEN"], mode_value)
        if mode_value == "one_step":
            if not (env.get("SRC_ADMIN_USER") and env.get("SRC_ADMIN_PASS")):
                report.log("WARN: SRC_ADMIN_USER/PASS not set; using SRC_USER/PASS as admin.")
            if not (env.get("TGT_ADMIN_USER") and env.get("TGT_ADMIN_PASS")):
                report.log("WARN: TGT_ADMIN_USER/PASS not set; using TGT_USER/PASS as admin.")
        if env.get("ALLOW_ROOT_USERS") not in ("1", "true", "TRUE", "True"):
            if env.get("SRC_USER") == "root" or env.get("TGT_USER") == "root":
                raise typer.BadParameter("SRC_USER/TGT_USER must not be root. Set ALLOW_ROOT_USERS=1 to override.")
    if mode_value == "two_step":
        if not (env.get("SQLINESDATA_CMD") or env.get("SQLINESDATA_BIN")):
            raise typer.BadParameter(
                "Missing SQLines configuration for mode 'two_step': "
                "set SQLINESDATA_CMD or SQLINESDATA_BIN + SQLINESDATA_ARGS"
            )
        if not (env.get("SQLINESDATA_CMD_FINALIZE") or env.get("SQLINESDATA_ARGS_FINALIZE")):
            raise typer.BadParameter(
                "Missing finalize configuration for mode 'two_step': "
                "set SQLINESDATA_CMD_FINALIZE or SQLINESDATA_ARGS_FINALIZE"
            )
    if mode_value == "near_zero":
        _require_env(
            env,
            ["NEAR_ZERO_REPLICATION_CMD", "NEAR_ZERO_CDC_CMD", "NEAR_ZERO_CUTOVER_CMD"],
            mode_value,
        )

    failures = []
    for s in steps:
        step_id = s["id"]
        name = s.get("name", step_id)
        script = s.get("script")
        args = s.get("args", []) or []

        # Skip completed
        if state.is_done(step_id):
            report.log(f"SKIP {step_id} ({name}) - already DONE")
            report.add_step(step_id, name, StepStatus.SKIPPED, details={"reason": "already_done"})
            continue

        report.log(f"RUN  {step_id} ({name}) -> {script}")
        ok, meta = run_step(repo_root, script, args=args, extra_env=env, log=report.log)
        if ok:
            state.mark_done(step_id, meta=meta)
            report.add_step(step_id, name, StepStatus.DONE, details=meta)
        else:
            state.mark_failed(step_id, meta=meta)
            report.add_step(step_id, name, StepStatus.FAILED, details=meta)
            failures.append(step_id)
            break  # fail-fast

    if failures:
        report.finish_run(success=False, message=f"Run failed at step: {failures[0]}")
        typer.echo(f"RUN: FAIL at {failures[0]} (see artifacts/run.log)")
        raise typer.Exit(code=3)

    report.finish_run(success=True, message="Run completed successfully.")
    typer.echo("RUN: PASS")


@app.command()
def resume(
    out: Path = typer.Option(DEFAULT_OUTDIR, "--out", "-o", help="Output directory containing state.json."),
    config: Optional[Path] = typer.Option(None, "--config", "-c", help="Migration config YAML. If omitted, uses path stored in report.json if present."),
    non_interactive: bool = typer.Option(True, "--non-interactive", help="Never prompt; CI-safe."),
    mode: Optional[str] = typer.Option(
        None,
        "--mode",
        "--playbook",
        "-m",
        help="Execution mode/playbook override.",
    ),
):
    """Resume a previously failed run using the state.json checkpoint."""
    report_path = out / DEFAULT_REPORT
    if config is None:
        if report_path.exists():
            data = json.loads(report_path.read_text(encoding="utf-8"))
            cfg_path = data.get("config_path")
            if cfg_path:
                config = Path(cfg_path)
    if config is None:
        raise typer.BadParameter("Config path not provided and not found in report.json")

    # Just call run() (it will skip DONE steps)
    run(config=config, out=out, non_interactive=non_interactive, mode=mode)


def main():
    app()


if __name__ == "__main__":
    main()
