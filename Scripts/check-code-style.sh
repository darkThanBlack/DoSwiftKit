#!/bin/bash
#
# Checks the two rules from CLAUDE.md: the fixed file header, and one-to-two line
# English comments. Prints one violation per line as "RULE<TAB>file:line<TAB>detail",
# exits 1 when anything is reported.
#
# Usage: Scripts/check-code-style.sh

cd "$(dirname "$0")/.." || exit 1

python3 - <<'PY'
import io
import os
import re
import sys

EXCLUDED_DIRS = {'.git', '.build', 'Example', 'Pods', '.swiftpm'}
EXCLUDED_FILES = {'Package.swift'}          # first line must stay `// swift-tools-version:`
LICENSE = '//  LICENSE: SAME AS REPOSITORY'
CONTACT = '//  Contact me: [GitHub](https://github.com/darkThanBlack)'
COPYRIGHT = '//  Copyright © {year} darkThanBlack. All rights reserved.'
CJK = re.compile(r'[㐀-䶿一-鿿]')

violations = []


def report(rule, path, line, detail):
    violations.append((rule, path, line, detail))


def check_header(path, name, lines):
    """R1: the ten-line block, with the file name, author, date and copyright year."""
    if name in EXCLUDED_FILES:
        return 10 if len(lines) >= 10 and 'Created by' in lines[4] else 0

    if len(lines) < 10:
        report('R1', path, 1, 'file shorter than the header block')
        return 0

    head = [line.strip() for line in lines[:10]]
    expected = ['//', f'//  {name}', '//  DoSwift', '//']

    # Anything shaped like a header is consumed whole, so a wrong name does not also
    # surface the header lines as R2 comment blocks.
    if not head[4].startswith('//  Created by'):
        report('R1', path, 1, 'missing file header')
        return 0

    if head[:4] != expected:
        report('R1', path, 1, f'header start should name {name}')
        return 10

    author = head[4]
    match = re.fullmatch(r'//  Created by moonShadow on (\d{4})/(\d{2})/(\d{2})', author)
    if not match:
        report('R1', path, 5, f'author / date line is "{author}"')
    elif head[5] != COPYRIGHT.format(year=match.group(1)):
        report('R1', path, 6, f'copyright year should be {match.group(1)}')
    elif head[6] != '//' or head[7] != LICENSE or head[8] != CONTACT or head[9] != '//':
        report('R1', path, 7, 'license / contact block differs from the template')

    return 10


def check_comments(path, lines, start):
    """R2: a comment block is at most two lines. R3: comments are ASCII English."""
    index = start
    while index < len(lines):
        text = lines[index].strip()
        is_comment = text.startswith('//') and not text.startswith('// MARK:')
        if not is_comment:
            index += 1
            continue

        end = index
        while end < len(lines):
            current = lines[end].strip()
            if not current.startswith('//') or current.startswith('// MARK:'):
                break
            end += 1

        if end - index > 2:
            report('R2', path, index + 1, f'{end - index} lines: {text[:60]}')
        index = end

    for number in range(start, len(lines)):
        text = lines[number].strip()
        if text.startswith('//') and CJK.search(text):
            report('R3', path, number + 1, text[:60])


for root, dirs, files in os.walk('.'):
    dirs[:] = sorted(d for d in dirs if d not in EXCLUDED_DIRS)
    for name in sorted(files):
        if not name.endswith('.swift'):
            continue
        path = os.path.normpath(os.path.join(root, name))
        lines = io.open(path, encoding='utf-8').read().split('\n')
        start = check_header(path, name, lines)
        check_comments(path, lines, start)

for rule, path, line, detail in violations:
    print(f'{rule}\t{path}:{line}\t{detail}')

print(f'-- {len(violations)} violation(s)', file=sys.stderr)
sys.exit(1 if violations else 0)
PY
