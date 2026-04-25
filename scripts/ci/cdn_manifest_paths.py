#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def _normalize_path(value: str) -> str:
    return value.replace("\\", "/").strip().strip("/")


def _read_paths(data: dict, mode: str) -> list[str]:
    if mode == "sync":
        raw_paths = data.get("cdn_roots", [])
    elif mode == "export-prune":
        raw_paths = data.get("export_prune_paths", [])
    else:
        raise ValueError(f"Unsupported mode: {mode}")

    if not isinstance(raw_paths, list):
        raise TypeError(f"{mode} paths must be a list")
    return raw_paths


def main() -> int:
    manifest_path = Path("config/cdn_asset_manifest.json")
    if not manifest_path.exists():
        print("Missing config/cdn_asset_manifest.json", file=sys.stderr)
        return 1

    mode = "sync"
    if len(sys.argv) > 1:
        mode = sys.argv[1].strip().lower()

    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    try:
        raw_paths = _read_paths(data, mode)
    except (ValueError, TypeError) as exc:
        print(str(exc), file=sys.stderr)
        return 1

    seen: set[str] = set()
    for item in raw_paths:
        if not isinstance(item, str):
            continue
        normalized = _normalize_path(item)
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        print(normalized)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
