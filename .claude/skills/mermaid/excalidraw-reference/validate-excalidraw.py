#!/usr/bin/env python3
"""
Validate an Excalidraw JSON file for structural correctness.

Checks:
  - Valid JSON with correct top-level structure
  - No duplicate element IDs
  - No duplicate seed values
  - Bidirectional bindings (shape ↔ text, shape ↔ arrow)
  - Arrow/line angle is 0 (no rotation)
  - Arrow/line first point is [0, 0]
  - Arrow width/height matches points bounding box
  - Text elements have originalText matching text
  - Text color contrast inside colored containers
  - frameId references point to frame elements
  - groupIds have at least two members (warns on singletons)

Usage:
  python3 validate-excalidraw.py <file.excalidraw>

Exit codes:
  0 = valid
  1 = errors found
  2 = file not found or not valid JSON
"""

import json
import sys
from pathlib import Path


def _relative_luminance(hex_color: str) -> float:
    """Compute relative luminance per WCAG 2.1 from a hex color string."""
    hex_color = hex_color.lstrip("#")
    if len(hex_color) != 6:
        return 0.0
    r, g, b = (int(hex_color[i:i+2], 16) / 255 for i in (0, 2, 4))
    def linearize(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)


def validate(filepath: str) -> tuple[list[str], list[str]]:
    """Validate an Excalidraw file. Returns (errors, warnings)."""
    errors = []
    warnings = []

    path = Path(filepath)
    if not path.exists():
        return [f"File not found: {filepath}"], []

    try:
        with open(path) as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        return [f"Invalid JSON: {e}"], []

    # Top-level structure checks
    if data.get("type") != "excalidraw":
        errors.append(
            f"Top-level 'type' must be 'excalidraw', "
            f"got: {data.get('type')!r}"
        )

    if not isinstance(data.get("elements"), list):
        errors.append("Top-level 'elements' must be a list")
        return errors, warnings  # Can't continue without elements list

    if "appState" not in data:
        errors.append("Top-level 'appState' is missing")
    elif "viewBackgroundColor" not in (data.get("appState") or {}):
        errors.append(
            "appState.viewBackgroundColor is missing"
        )

    elements = data.get("elements", [])
    if not elements:
        errors.append("No elements found in file")
        return errors, warnings

    # Build lookup
    by_id = {}
    ids = []
    seeds = []

    for el in elements:
        el_id = el.get("id", "")
        ids.append(el_id)
        seeds.append(el.get("seed"))
        by_id[el_id] = el

    # Check duplicate IDs
    seen_ids = set()
    for eid in ids:
        if eid in seen_ids:
            errors.append(f"Duplicate element ID: {eid}")
        seen_ids.add(eid)

    # Check duplicate seeds
    seen_seeds = set()
    for seed in seeds:
        if seed is not None and seed in seen_seeds:
            errors.append(f"Duplicate seed value: {seed}")
        seen_seeds.add(seed)

    # Precompute group membership counts
    group_counts: dict[str, int] = {}
    for el in elements:
        for gid in el.get("groupIds") or []:
            group_counts[gid] = group_counts.get(gid, 0) + 1

    for el in elements:
        el_id = el.get("id", "?")
        el_type = el.get("type", "?")

        # Check text originalText matches text
        if el_type == "text":
            text = el.get("text", "")
            original = el.get("originalText", "")
            if text != original:
                errors.append(
                    f"[{el_id}] text != originalText: "
                    f"{text!r} vs {original!r}"
                )

        # Check arrow/line angle is 0
        if el_type in ("arrow", "line"):
            angle = el.get("angle", 0)
            if angle != 0:
                errors.append(
                    f"[{el_id}] {el_type} has angle={angle} — "
                    f"must be 0 (define direction via points, "
                    f"not rotation)"
                )

        # Check arrow/line has non-empty points and first point is [0, 0]
        if el_type in ("arrow", "line"):
            points = el.get("points", [])
            if not points or not isinstance(points, list):
                errors.append(
                    f"[{el_id}] {el_type} must have a non-empty "
                    f"points array"
                )
            elif points[0] != [0, 0]:
                errors.append(
                    f"[{el_id}] first point must be [0, 0], "
                    f"got {points[0]}"
                )

        # Check arrow width/height vs points bounding box
        if el_type in ("arrow", "line"):
            points = el.get("points", [])
            if len(points) >= 2:
                xs = [p[0] for p in points]
                ys = [p[1] for p in points]
                expected_w = max(xs) - min(xs)
                expected_h = max(ys) - min(ys)
                actual_w = el.get("width", 0)
                actual_h = el.get("height", 0)
                if actual_w < 0 or actual_h < 0:
                    errors.append(
                        f"[{el_id}] width/height must be "
                        f"non-negative, got w={actual_w} h={actual_h}"
                    )
                if abs(abs(actual_w) - expected_w) > 1:
                    errors.append(
                        f"[{el_id}] width {actual_w} != points bbox "
                        f"width {expected_w}"
                    )
                if abs(abs(actual_h) - expected_h) > 1:
                    errors.append(
                        f"[{el_id}] height {actual_h} != points bbox "
                        f"height {expected_h}"
                    )

        # Check bidirectional bindings: arrow → shape
        if el_type in ("arrow", "line"):
            for binding_key in ("startBinding", "endBinding"):
                binding = el.get(binding_key)
                if binding and binding.get("elementId"):
                    target_id = binding["elementId"]
                    target = by_id.get(target_id)
                    if target is None:
                        errors.append(
                            f"[{el_id}] {binding_key} references "
                            f"non-existent element: {target_id}"
                        )
                    else:
                        bound = target.get("boundElements") or []
                        bound_ids = [b.get("id") for b in bound]
                        if el_id not in bound_ids:
                            errors.append(
                                f"[{el_id}] bound to [{target_id}] via "
                                f"{binding_key}, but [{target_id}] "
                                f"doesn't list [{el_id}] in boundElements"
                            )

        # Check bidirectional bindings: text → container
        if el_type == "text":
            container_id = el.get("containerId")
            if container_id:
                container = by_id.get(container_id)
                if container is None:
                    errors.append(
                        f"[{el_id}] containerId references "
                        f"non-existent element: {container_id}"
                    )
                else:
                    bound = container.get("boundElements") or []
                    bound_ids = [b.get("id") for b in bound]
                    if el_id not in bound_ids:
                        errors.append(
                            f"[{el_id}] contained in [{container_id}], "
                            f"but [{container_id}] doesn't list [{el_id}] "
                            f"in boundElements"
                        )

        # Check text color contrast inside containers
        if el_type == "text":
            container_id = el.get("containerId")
            if container_id:
                container = by_id.get(container_id)
                if container is not None:
                    bg = (container.get("backgroundColor") or "").lower()
                    if bg and bg != "transparent":
                        text_color = (
                            el.get("strokeColor") or ""
                        ).lower()
                        # Determine dark mode via luminance threshold
                        view_bg = (
                            (data.get("appState") or {})
                            .get("viewBackgroundColor", "#ffffff")
                            or "#ffffff"
                        ).lower()
                        if view_bg == "transparent":
                            # Can't determine theme — skip check
                            pass
                        else:
                            dark_mode = _relative_luminance(view_bg) < 0.2
                            if dark_mode:
                                ok_colors = {"#c9d1d9", "#ffffff"}
                            else:
                                ok_colors = {"#1e1e1e"}
                            if text_color not in ok_colors:
                                mode = "dark" if dark_mode else "light"
                                errors.append(
                                    f"[{el_id}] text inside colored "
                                    f"container [{container_id}] uses "
                                    f"strokeColor {text_color!r} — "
                                    f"expected {ok_colors} for "
                                    f"{mode} mode"
                                )

        # Check boundElements references exist
        bound = el.get("boundElements") or []
        for b in bound:
            ref_id = b.get("id")
            if ref_id and ref_id not in by_id:
                errors.append(
                    f"[{el_id}] boundElements references "
                    f"non-existent element: {ref_id}"
                )

        # Check frameId references a frame element
        frame_id = el.get("frameId")
        if frame_id:
            frame = by_id.get(frame_id)
            if frame is None:
                errors.append(
                    f"[{el_id}] frameId references "
                    f"non-existent element: {frame_id}"
                )
            elif frame.get("type") != "frame":
                errors.append(
                    f"[{el_id}] frameId references [{frame_id}] "
                    f"which is type '{frame.get('type')}', "
                    f"not 'frame'"
                )

        # Check groupIds — warn on singleton groups
        for gid in el.get("groupIds") or []:
            if gid in group_counts and group_counts[gid] < 2:
                warnings.append(
                    f"[{el_id}] groupId '{gid}' has only "
                    f"one member — possibly orphaned"
                )

    return errors, warnings


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <file.excalidraw>")
        sys.exit(2)

    errors, warnings = validate(sys.argv[1])

    if warnings:
        print(f"WARNINGS ({len(warnings)}):")
        for w in warnings:
            print(f"  - {w}")

    if not errors:
        print("VALID - no errors found")
        sys.exit(0)
    else:
        print(f"ERRORS ({len(errors)}):")
        for e in errors:
            print(f"  - {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
