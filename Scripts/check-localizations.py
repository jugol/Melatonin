#!/usr/bin/env python3
"""Checks every translation against Resources/en.lproj/Localizable.strings:
same keys, same format specifiers, valid plist syntax."""
import pathlib, re, subprocess, sys

root = pathlib.Path(__file__).resolve().parent.parent / "Resources"
entry = re.compile(r'^"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)";\s*$', re.M)
specifier = re.compile(r"%(?:\d+\$)?(?:lld|@|d)")

def load(path):
    return dict(entry.findall(path.read_text(encoding="utf-8")))

source = load(root / "en.lproj/Localizable.strings")
failed = False
for table in sorted(root.glob("*.lproj/Localizable.strings")):
    language = table.parent.stem
    problems = []
    if subprocess.run(["plutil", "-lint", "-s", str(table)]).returncode != 0:
        problems.append("plutil lint failed")
    strings = load(table)
    problems += [f"missing: {k}" for k in source if k not in strings]
    problems += [f"unknown: {k}" for k in strings if k not in source]
    for key, value in strings.items():
        if sorted(specifier.findall(key)) != sorted(specifier.findall(value)):
            problems.append(f"specifiers differ: {key!r} -> {value!r}")
    print(f"{'✗' if problems else '✓'} {language}: {len(strings)} strings")
    for problem in problems:
        print(f"    {problem}")
    failed |= bool(problems)
sys.exit(1 if failed else 0)
