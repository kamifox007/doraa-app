#!/usr/bin/env python3
import sys
import re

def check_file(path):
    text = open(path, encoding='utf-8').read()
    problems = []

    # Check dollar-quote tags
    tags = re.findall(r"\$[A-Za-z0-9_]*\$", text)
    if len(tags) % 2 != 0:
        problems.append(f"Unbalanced dollar-quote tags (found {len(tags)}): {sorted(set(tags))}")

    # Check single quotes: remove doubled '' then count remaining '
    text_no_doubled = text.replace("''", "")
    single_quotes = text_no_doubled.count("'")
    if single_quotes % 2 != 0:
        problems.append(f"Unbalanced single quotes (approx): remaining single quotes = {single_quotes}")

    # Check parentheses
    open_paren = text.count('(')
    close_paren = text.count(')')
    if open_paren != close_paren:
        problems.append(f"Unmatched parentheses: ( = {open_paren}, ) = {close_paren}")

    # Check file ends with semicolon for last statement (basic)
    stripped = text.rstrip()
    if not stripped.endswith(';'):
        problems.append("File does not end with a semicolon (';') — may cause 'end of input' errors when run combined.")

    return problems

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: python validate_sql.py <sql-file> [<sql-file> ...]')
        sys.exit(1)

    any_problems = False
    for path in sys.argv[1:]:
        try:
            problems = check_file(path)
        except Exception as e:
            print(f"ERROR reading {path}: {e}")
            any_problems = True
            continue
        if problems:
            any_problems = True
            print(f"\n{path}:")
            for p in problems:
                print('  -', p)
        else:
            print(f"{path}: OK")

    if any_problems:
        sys.exit(2)
    print('\nAll checked files look syntactically balanced by quick heuristics.')
