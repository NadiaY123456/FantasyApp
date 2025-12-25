#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import re
from datetime import datetime
from pathlib import Path


ERROR_WARNING_PATTERN = re.compile(r"\b(warn(?:ing|ings)?|error(?:s)?)\b", re.IGNORECASE)


def resolve_source_path(repo_root: Path, rel_path: str) -> Path:
    """Return the first matching filesystem path for the given relative entry."""
    rel = Path(rel_path)

    search_roots: list[Path] = []
    seen_roots: set[Path] = set()

    def add_root(root: Path) -> None:
        if root not in seen_roots:
            seen_roots.add(root)
            search_roots.append(root)

    add_root(repo_root)
    add_root(repo_root.parent)
    add_root(repo_root / "MacVRSpatial")
    add_root(repo_root.parent / "MacVRSpatial")

    worktree_root = repo_root.parent
    potential_worktrees_root = worktree_root.parent
    if potential_worktrees_root.name.endswith(".worktrees"):
        canonical_name = potential_worktrees_root.name[: -len(".worktrees")]
        canonical_root = potential_worktrees_root.parent / canonical_name
        if canonical_root.exists():
            add_root(canonical_root)
            add_root(canonical_root / "MacVRSpatial")

    rel_variants: list[Path] = []
    seen_variants: set[Path] = set()

    def add_variant(candidate: Path) -> None:
        if candidate not in seen_variants and str(candidate) != ".":
            seen_variants.add(candidate)
            rel_variants.append(candidate)

    add_variant(rel)

    if rel.parts and rel.parts[0] == "MacVRSpatial":
        add_variant(Path("MacVRSpatial") / rel)
        if len(rel.parts) > 1:
            add_variant(Path(*rel.parts[1:]))

    attempted: list[Path] = []
    for root in search_roots:
        for variant in rel_variants:
            candidate = root / variant
            attempted.append(candidate)
            if candidate.exists():
                return candidate

    attempted_str = "\n - ".join(str(path) for path in attempted)
    raise FileNotFoundError(
        f"Could not locate source file '{rel_path}'. Tried:\n - {attempted_str}"
    )


def sum_comment_characters(text: str) -> int:
    total = 0
    for line in text.splitlines():
        comment_start = line.find("//")
        if comment_start != -1:
            total += len(line) - comment_start
    return total


def filter_comment_lines(text: str) -> str:
    lines = text.splitlines()
    filtered: list[str] = []
    in_block = False

    for line in lines:
        stripped = line.lstrip()
        has_keyword = bool(ERROR_WARNING_PATTERN.search(line))

        if in_block:
            if has_keyword:
                filtered.append(line)
            if "*/" in stripped:
                in_block = False
            continue

        if stripped.startswith("//"):
            if has_keyword:
                filtered.append(line)
            continue

        if stripped.startswith("/*"):
            if has_keyword:
                filtered.append(line)
            if "*/" not in stripped[stripped.find("/*") + 2 :]:
                in_block = True
            continue

        filtered.append(line)

    return "\n".join(filtered)


def describe_binary_file(path: Path) -> str:
    data = path.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    size_bytes = len(data)
    preview = " ".join(f"{byte:02x}" for byte in data[:32])
    lines = [
        "Binary file; contents omitted.",
        f"Size: {size_bytes:,} bytes ({size_bytes / 1024:.2f} KB)",
        f"SHA256: {digest}",
    ]
    if data:
        lines.append(f"First 32 bytes (hex): {preview}")
    else:
        lines.append("File is empty.")
    return "\n".join(lines)


def format_directory_listing(directory: Path) -> str:
    entries: list[str] = []
    directory = directory.resolve()
    sorted_entries = sorted(
        directory.rglob("*"), key=lambda p: p.relative_to(directory).as_posix()
    )

    for entry in sorted_entries:
        rel = entry.relative_to(directory)
        rel_str = rel.as_posix()
        if entry.is_dir():
            entries.append(f"{rel_str}/")
        else:
            size_bytes = entry.stat().st_size
            entries.append(f"{rel_str} ({size_bytes:,} bytes)")

    if not entries:
        return "(directory is empty)"

    lines = ["Directory listing (relative paths):"]
    lines.extend(f"- {item}" for item in entries)
    return "\n".join(lines)


def load_source_content(path: Path) -> str:
    if path.is_dir():
        return format_directory_listing(path)
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return describe_binary_file(path)
    return filter_comment_lines(text)

def concatenate_sources_for(
    source_files: list[str],
    output_filename: str,
    secondary_output_path: Path,
) -> tuple[Path, int, int, int, list[tuple[str, int, int]]]:
    """Generic concatenation routine used by both primary and temp runs."""
    docs_dir = Path(__file__).resolve().parent
    repo_root = docs_dir.parent
    output_path = docs_dir / output_filename

    output_parts: list[str] = []
    per_file_chunks: list[tuple[str, str]] = []

    for index, rel_path in enumerate(source_files):
        source_path = resolve_source_path(repo_root, rel_path)
        contents = load_source_content(source_path)
        header = f"==== {rel_path} ===="
        section = f"{header}\n\n{contents.rstrip()}\n"

        if index > 0:
            output_parts.append("\n")
            chunk_text = "\n" + section
        else:
            chunk_text = section

        output_parts.append(section)
        per_file_chunks.append((rel_path, chunk_text))

    output = "".join(output_parts)
    output_path.write_text(output, encoding="utf-8")
    total_chars = len(output)
    total_bytes = len(output.encode("utf-8"))
    comment_chars = sum_comment_characters(output)
    per_file_stats = [
        (rel_path, len(chunk), len(chunk.encode("utf-8")))
        for rel_path, chunk in per_file_chunks
    ]
    per_file_stats.sort(key=lambda item: item[1])

    try:
        secondary_output_path.parent.mkdir(parents=True, exist_ok=True)
        secondary_output_path.write_text(output, encoding="utf-8")
    except OSError:
        pass
    return output_path, total_chars, comment_chars, total_bytes, per_file_stats


def concatenate_sources(
    source_files: list[str],
    output_filename: str,
    secondary_output_path: Path,
) -> tuple[Path, int, int, int, list[tuple[str, int, int]]]:
    """Convenience wrapper around concatenate_sources_for for the main run."""
    return concatenate_sources_for(source_files, output_filename, secondary_output_path)

def _print_report(path: Path, total_chars: int, comment_chars: int, total_bytes: int,
                  per_file_stats: list[tuple[str, int, int]]) -> None:
    comment_percent = (comment_chars / total_chars * 100) if total_chars else 0.0
    total_kb = total_bytes / 1024
    print(f"Wrote concatenated file to {path}")
    print("Per-file character totals:")
    max_filename_len = max(
        (len(Path(rel_path).name) for rel_path, _, _ in per_file_stats), default=0
    )
    max_dir_len = max(
        (len(str(Path(rel_path).parent)) for rel_path, _, _ in per_file_stats), default=0
    )
    for rel_path, char_count, byte_count in per_file_stats:
        kb = byte_count / 1024
        percent = (char_count / total_chars * 100) if total_chars else 0.0
        filename = Path(rel_path).name
        directory = str(Path(rel_path).parent)
        print(
            f"  {percent:6.2f}%  {kb:7.2f} KB  {filename:<{max_filename_len}}  {directory:<{max_dir_len}}"
        )
    print()
    print(f"Total characters in output: {total_chars:,} ({total_kb:,.2f} KB)")
    print(f"Commented character count: {comment_chars:,} ({comment_percent:,.2f}%)")
