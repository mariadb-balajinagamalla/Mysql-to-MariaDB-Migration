from __future__ import annotations

import json
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Any, Dict, List, Optional
from datetime import datetime, timezone

class GateStatus(str, Enum):
    PASS = "PASS"
    FAIL = "FAIL"

class StepStatus(str, Enum):
    DONE = "DONE"
    FAILED = "FAILED"
    SKIPPED = "SKIPPED"

@dataclass
class Gate:
    name: str
    status: GateStatus
    details: Dict[str, Any] = field(default_factory=dict)

@dataclass
class WarningItem:
    name: str
    severity: str  # LOW/MEDIUM/HIGH
    details: Dict[str, Any] = field(default_factory=dict)

@dataclass
class Report:
    report_path: Path
    log_path: Path
    _data: Dict[str, Any] = field(default_factory=dict)

    def start_run(self, mode: str, config_path: str) -> None:
        self._data = {
            "schema_version": 1,
            "run_id": datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ"),
            "mode": mode,
            "config_path": config_path,
            "started_at": datetime.now(timezone.utc).isoformat(),
            "finished_at": None,
            "success": None,
            "message": None,
            "source": {},
            "target": {},
            "gates": [],
            "warnings": [],
            "inventory": {},
            "plan": {},
            "steps": []
        }
        self.report_path.parent.mkdir(parents=True, exist_ok=True)
        self.log_path.parent.mkdir(parents=True, exist_ok=True)
        self.log(f"START mode={mode} config={config_path}")
        self._flush()

    def log(self, msg: str) -> None:
        ts = datetime.now(timezone.utc).isoformat()
        line = f"{ts} {msg}\n"
        with self.log_path.open("a", encoding="utf-8") as f:
            f.write(line)

    def _flush(self) -> None:
        self.report_path.write_text(json.dumps(self._data, indent=2, sort_keys=False), encoding="utf-8")

    def finish_run(self, success: bool, message: str) -> None:
        self._data["finished_at"] = datetime.now(timezone.utc).isoformat()
        self._data["success"] = success
        self._data["message"] = message
        self.log(f"FINISH success={success} message={message}")
        self._flush()

    def set_source(self, source: Dict[str, Any]) -> None:
        self._data["source"] = source
        self._flush()

    def set_target(self, target: Dict[str, Any]) -> None:
        self._data["target"] = target
        self._flush()

    def set_gates(self, gates: List[Gate]) -> None:
        self._data["gates"] = [{"name": g.name, "status": g.status.value, "details": g.details} for g in gates]
        self._flush()

    def set_warnings(self, warnings: List[WarningItem]) -> None:
        self._data["warnings"] = [{"name": w.name, "severity": w.severity, "details": w.details} for w in warnings]
        self._flush()

    def set_inventory(self, inventory: Dict[str, Any]) -> None:
        self._data["inventory"] = inventory
        self._flush()

    def set_plan(self, plan: Dict[str, Any]) -> None:
        self._data["plan"] = plan
        self._flush()

    def add_step(self, step_id: str, name: str, status: StepStatus, details: Optional[Dict[str, Any]] = None) -> None:
        self._data["steps"].append({
            "id": step_id,
            "name": name,
            "status": status.value,
            "details": details or {}
        })
        self._flush()
