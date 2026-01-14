from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Optional
from datetime import datetime, timezone

@dataclass
class StateStore:
    path: Path

    def __post_init__(self) -> None:
        if not self.path.exists():
            self._write({
                "version": 1,
                "created_at": datetime.now(timezone.utc).isoformat(),
                "steps": {}
            })

    def _read(self) -> Dict[str, Any]:
        return json.loads(self.path.read_text(encoding="utf-8"))

    def _write(self, data: Dict[str, Any]) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")

    def is_done(self, step_id: str) -> bool:
        data = self._read()
        st = data["steps"].get(step_id, {})
        return st.get("status") == "DONE"

    def mark_done(self, step_id: str, meta: Optional[Dict[str, Any]] = None) -> None:
        data = self._read()
        data["steps"][step_id] = {
            "status": "DONE",
            "updated_at": datetime.now(timezone.utc).isoformat(),
            "meta": meta or {}
        }
        self._write(data)

    def mark_failed(self, step_id: str, meta: Optional[Dict[str, Any]] = None) -> None:
        data = self._read()
        data["steps"][step_id] = {
            "status": "FAILED",
            "updated_at": datetime.now(timezone.utc).isoformat(),
            "meta": meta or {}
        }
        self._write(data)
