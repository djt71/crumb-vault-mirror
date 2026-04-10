#!/usr/bin/env python3
"""MOC Core Placement Script

Scans Sources/books/ for source-index notes and inserts one-liners into the
corresponding MOC's <!-- CORE:START --> section.

Placement priority:
  1. Source-index notes (preferred — one MOC entry per source)
  2. Digest notes (fallback — only if no source-index exists for the source_id)
  Chapter digests are always skipped.

Does NOT modify: last_reviewed, notes_at_review (preserved for manual baseline reset).
Only modifies: MOC Core section content, MOC updated field.
Optionally backfills note topics fields where tags map to MOCs not yet listed.

No external dependencies — parses frontmatter with regex (format is machine-generated
by pipeline.py, so structure is predictable).

Usage:
    python3 batch-moc-placement.py [--dry-run] [--backfill] [--path SOURCES_DIR]
"""

import argparse
import re
import sys
from datetime import date
from pathlib import Path

VAULT_ROOT = Path(__file__).resolve().parents[2]  # _system/scripts/ -> vault root
DEFAULT_SOURCES = VAULT_ROOT / "Sources" / "books"
DOMAINS_DIR = VAULT_ROOT / "Domains"

# Must match pipeline.py KB_TO_TOPIC — single source of truth is pipeline.py
# but we duplicate here to support backfill of notes generated before mapping existed.
KB_TO_TOPIC = {
    "kb/business": "moc-business",
    "kb/history": "moc-history",
    "kb/philosophy": "moc-philosophy",
    "kb/writing": "moc-writing",
    "kb/religion": "moc-religion",
    "kb/fiction": "moc-fiction",
    "kb/biography": "moc-biography",
    "kb/politics": "moc-politics",
    "kb/psychology": "moc-psychology",
    "kb/poetry": "moc-poetry",
    "kb/gardening": "moc-gardening",
    "kb/networking/dns": "moc-networking",
    "kb/networking": "moc-networking",
    "kb/security": "moc-crumb-operations",
    "kb/software-dev": "moc-crumb-architecture",
    "kb/customer-engagement": "moc-business",
    "kb/training-delivery": "moc-business",
}


# ---------------------------------------------------------------------------
# Lightweight frontmatter parser (no PyYAML dependency)
# ---------------------------------------------------------------------------

def parse_frontmatter(filepath: Path) -> tuple[dict | None, str]:
    """Extract key fields from YAML frontmatter using regex.

    Returns (parsed_dict, full_file_content). The dict contains only the
    fields this script needs: scope, topics, tags, source.title, source.author.
    """
    content = filepath.read_text(encoding="utf-8")
    fm_match = re.match(r"^---\n(.+?)\n---", content, re.DOTALL)
    if not fm_match:
        return None, content

    fm_text = fm_match.group(1)
    # Normalize: ensure trailing newline so list-item regexes
    # match the last entry (frontmatter regex strips trailing \n).
    if not fm_text.endswith("\n"):
        fm_text += "\n"
    result = {}

    # type: <value>
    m = re.search(r"^type:\s*(.+)$", fm_text, re.MULTILINE)
    if m:
        result["type"] = m.group(1).strip().strip("'\"")

    # scope: <value>
    m = re.search(r"^scope:\s*(.+)$", fm_text, re.MULTILINE)
    if m:
        result["scope"] = m.group(1).strip().strip("'\"")

    # tags: list of - kb/xxx (handles both indented and non-indented)
    tags = re.findall(r"^\s*- (kb/.+)$", fm_text, re.MULTILINE)
    result["tags"] = tags

    # topics: list of - moc-xxx (handles both indented and non-indented)
    topics_match = re.search(r"^topics:\n((?:\s*- .+\n)*)", fm_text, re.MULTILINE)
    if topics_match:
        result["topics"] = [
            line.strip().lstrip("- ").strip("'\"")
            for line in topics_match.group(1).strip().split("\n")
            if line.strip()
        ]
    else:
        result["topics"] = []

    # source.source_id, source.title, source.author (nested under source:)
    source = {}
    m = re.search(r"^\s+source_id:\s*(.+)$", fm_text, re.MULTILINE)
    if m:
        source["source_id"] = m.group(1).strip().strip("'\"")
    m = re.search(r"^\s+title:\s*(.+)$", fm_text, re.MULTILINE)
    if m:
        source["title"] = m.group(1).strip().strip("'\"")
    m = re.search(r"^\s+author:\s*(.+)$", fm_text, re.MULTILINE)
    if m:
        source["author"] = m.group(1).strip().strip("'\"")
    result["source"] = source

    return result, content


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def find_moc_path(topic_slug: str) -> Path | None:
    """Find MOC file by slug across all Domains/*/."""
    for domain_dir in DOMAINS_DIR.iterdir():
        if domain_dir.is_dir():
            candidate = domain_dir / f"{topic_slug}.md"
            if candidate.exists():
                return candidate
    return None


def extract_surname(author: str) -> str:
    """Extract surname from full author name. Last word heuristic."""
    if not author:
        return "Unknown"
    parts = author.strip().split()
    return parts[-1]


def get_core_links(moc_content: str) -> set[str]:
    """Extract existing wikilink targets from MOC Core section."""
    core_match = re.search(
        r"<!-- CORE:START -->(.+?)<!-- CORE:END -->", moc_content, re.DOTALL
    )
    if not core_match:
        return set()
    return set(re.findall(r"\[\[([^\]|]+)", core_match.group(1)))


def build_one_liner(stem: str, author: str, title: str, tags: list[str]) -> str:
    """Build minimal MOC one-liner from frontmatter fields.

    Format: - [[stem|Surname: Title]] — tag-label, tag-label
    Temporary — will be replaced by index-note links and synthesis rewrite.
    """
    surname = extract_surname(author)
    display = f"{surname}: {title}"
    tag_labels = ", ".join(
        t.replace("kb/", "") for t in tags if t.startswith("kb/")
    )
    return f"- [[{stem}|{display}]] — {tag_labels}"


def insert_one_liner(moc_path: Path, one_liner: str, today: str, dry_run: bool) -> bool:
    """Insert one-liner before <!-- CORE:END --> and bump updated field."""
    content = moc_path.read_text(encoding="utf-8")

    core_end = "<!-- CORE:END -->"
    if core_end not in content:
        return False

    content = content.replace(core_end, f"{one_liner}\n{core_end}")

    # Bump updated in frontmatter (don't touch last_reviewed or notes_at_review)
    content = re.sub(
        r"^(updated:)\s*.+$",
        f"\\1 {today}",
        content,
        count=1,
        flags=re.MULTILINE,
    )

    if not dry_run:
        moc_path.write_text(content, encoding="utf-8")
    return True


def backfill_topics(
    note_path: Path, fm: dict, content: str, today: str, dry_run: bool
) -> list[str]:
    """Add missing topic mappings to a note's frontmatter.

    Returns list of newly added topic slugs.
    """
    tags = fm.get("tags", [])
    existing_topics = set(fm.get("topics", []))
    added = []

    for tag in tags:
        if tag in KB_TO_TOPIC:
            topic = KB_TO_TOPIC[tag]
            if topic not in existing_topics:
                if find_moc_path(topic):
                    added.append(topic)
                    existing_topics.add(topic)

    if not added:
        return []

    # Rebuild topics list (preserve existing order, append new)
    new_topics = list(fm.get("topics", [])) + added

    # Update frontmatter in file content
    fm_match = re.match(r"^---\n(.+?)\n---", content, re.DOTALL)
    if not fm_match:
        return []

    fm_text = fm_match.group(1)
    post_fm = content[fm_match.end():]

    # Normalize: ensure fm_text ends with newline so list-item regexes
    # match the last entry (the frontmatter regex strips the trailing \n).
    if not fm_text.endswith("\n"):
        fm_text += "\n"

    # Replace or add topics field
    topics_yaml = "topics:\n" + "".join(f"- {t}\n" for t in new_topics)
    if re.search(r"^topics:", fm_text, re.MULTILINE):
        fm_text = re.sub(
            r"^topics:\n(?:- .+\n)*",
            topics_yaml,
            fm_text,
            flags=re.MULTILINE,
        )
    else:
        fm_text = fm_text.rstrip("\n") + "\n" + topics_yaml

    # Bump updated
    fm_text = re.sub(
        r"^(updated:)\s*.+$",
        f"\\1 '{today}'",
        fm_text,
        count=1,
        flags=re.MULTILINE,
    )

    # Reconstruct: ensure exactly one \n before closing ---
    new_content = f"---\n{fm_text.rstrip(chr(10))}\n---{post_fm}"
    if not dry_run:
        note_path.write_text(new_content, encoding="utf-8")

    return added


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Place knowledge notes into MOC Core sections"
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Show actions without writing files",
    )
    parser.add_argument(
        "--backfill", action="store_true",
        help="Also add missing topic mappings to notes (for pre-expansion notes)",
    )
    parser.add_argument(
        "--path", type=Path, default=DEFAULT_SOURCES,
        help=f"Source directory to scan (default: {DEFAULT_SOURCES})",
    )
    args = parser.parse_args()

    if not args.path.is_dir():
        print(f"Error: {args.path} is not a directory", file=sys.stderr)
        sys.exit(1)

    today = date.today().isoformat()
    mode_label = "[DRY RUN] " if args.dry_run else ""

    notes = sorted(args.path.glob("*.md"))
    print(f"{mode_label}Scanning {len(notes)} files in {args.path}")

    placed = 0
    skipped_scope = 0
    skipped_dup = 0
    skipped_no_topics = 0
    skipped_has_index = 0
    backfilled = 0
    moc_touched: set[str] = set()
    errors: list[str] = []

    # Pre-scan: identify which source_ids have source-index notes.
    # When a source-index exists, we place THAT note instead of individual digests.
    source_ids_with_index: set[str] = set()
    for note_path in notes:
        if note_path.stem.endswith("-index"):
            fm_check, _ = parse_frontmatter(note_path)
            if fm_check:
                # Extract source_id from source-index note
                sid = fm_check.get("source", {}).get("source_id")
                if sid:
                    source_ids_with_index.add(sid)

    if source_ids_with_index:
        print(f"  {len(source_ids_with_index)} sources have index notes (preferred for placement)")

    for note_path in notes:
        fm, content = parse_frontmatter(note_path)
        if not fm:
            errors.append(f"{note_path.name}: failed to parse frontmatter")
            continue

        # Filter: skip chapter digests (linked from source-index notes).
        # Use filename suffix rather than scope field — pipeline bug sets scope: whole
        # on chapter digests too (pipeline.py TEMPLATES["chapter-digest"]["scope"]).
        if note_path.stem.endswith("-chapter-digest"):
            skipped_scope += 1
            continue

        # Extract source_id for index-preference check
        source_id = fm.get("source", {}).get("source_id")
        is_index_note = note_path.stem.endswith("-index")

        # Skip individual digests when a source-index exists for this source_id.
        # The source-index note will be placed instead.
        if not is_index_note and source_id and source_id in source_ids_with_index:
            skipped_has_index += 1
            continue

        # Backfill topics if requested (applies to all note types)
        if args.backfill:
            added = backfill_topics(note_path, fm, content, today, args.dry_run)
            if added:
                backfilled += len(added)
                print(f"  {mode_label}BACKFILL {note_path.name}: +{', '.join(added)}")
                # Re-read after backfill to get updated topics
                if not args.dry_run:
                    fm, content = parse_frontmatter(note_path)
                else:
                    # In dry-run, simulate the backfill result
                    fm["topics"] = list(fm.get("topics", [])) + added

        topics = fm.get("topics", [])
        if not topics:
            skipped_no_topics += 1
            continue

        # Build one-liner from frontmatter
        source = fm.get("source", {})
        author = source.get("author", "Unknown")
        title = source.get("title", note_path.stem)
        tags = fm.get("tags", [])
        stem = note_path.stem
        one_liner = build_one_liner(stem, author, title, tags)

        # Place into each target MOC
        for topic in topics:
            moc_path = find_moc_path(topic)
            if not moc_path:
                errors.append(f"{note_path.name}: MOC not found for topic '{topic}'")
                continue

            # Dedup: check if already in Core
            moc_content = moc_path.read_text(encoding="utf-8")
            existing_links = get_core_links(moc_content)
            if stem in existing_links:
                skipped_dup += 1
                continue

            if insert_one_liner(moc_path, one_liner, today, args.dry_run):
                placed += 1
                moc_touched.add(topic)
                print(f"  {mode_label}PLACE {stem} → {topic}")
            else:
                errors.append(
                    f"{note_path.name}: CORE:END marker missing in {moc_path.name}"
                )

    # Summary
    print(f"\n{mode_label}=== Placement Summary ===")
    print(f"  Notes scanned:       {len(notes)}")
    print(f"  Placed:              {placed} entries across {len(moc_touched)} MOCs")
    if backfilled:
        print(f"  Backfilled topics:   {backfilled}")
    print(f"  Skipped (chapter):   {skipped_scope}")
    print(f"  Skipped (has index): {skipped_has_index}")
    print(f"  Skipped (duplicate): {skipped_dup}")
    print(f"  Skipped (no topics): {skipped_no_topics}")
    if moc_touched:
        print(f"  MOCs modified:       {', '.join(sorted(moc_touched))}")
    if errors:
        print(f"\n  ERRORS ({len(errors)}):")
        for e in errors:
            print(f"    - {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
