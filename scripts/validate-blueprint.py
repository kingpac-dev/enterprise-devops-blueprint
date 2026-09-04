#!/usr/bin/env python3
# ==============================================================================
# Enterprise DevOps Blueprint — Static Blueprint Validator
# Implements: AGENTS.md (Section 19: Validation Policy)
# ==============================================================================

import os
import sys
import re
import json
import yaml

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, ".."))

errors = []
warnings = []

print("=== Starting Comprehensive Enterprise DevOps Blueprint Verification ===")

# 1. JSON Syntax Check
print("\n--- 1. Validating JSON Files ---")
json_count = 0
for root, dirs, files in os.walk(REPO_ROOT):
    if any(ignore in root for ignore in ["node_modules", ".git", "dist", "bin", "obj", "tmp"]):
        continue
    for file in files:
        if file.endswith(".json"):
            json_count += 1
            path = os.path.join(root, file)
            try:
                with open(path, "r", encoding="utf-8") as f:
                    json.load(f)
            except Exception as e:
                errors.append(f"JSON Error in {os.path.relpath(path, REPO_ROOT)}: {e}")

print(f"Validated {json_count} JSON files. Errors: {len([e for e in errors if 'JSON' in e])}")

# 2. YAML Syntax Check
print("\n--- 2. Validating YAML Files ---")
yaml_count = 0
for root, dirs, files in os.walk(REPO_ROOT):
    if any(ignore in root for ignore in ["node_modules", ".git", "dist", "bin", "obj", "tmp"]):
        continue
    for file in files:
        if file.endswith((".yml", ".yaml")):
            yaml_count += 1
            path = os.path.join(root, file)
            try:
                with open(path, "r", encoding="utf-8") as f:
                    list(yaml.safe_load_all(f))
            except Exception as e:
                errors.append(f"YAML Error in {os.path.relpath(path, REPO_ROOT)}: {e}")

print(f"Validated {yaml_count} YAML files. Errors: {len([e for e in errors if 'YAML' in e])}")

# 3. Markdown Relative Link Validation
print("\n--- 3. Validating Markdown Links ---")
md_count = 0
link_count = 0
broken_links = 0
link_pattern = re.compile(r'\[([^\]]+)\]\(([^)]+)\)')

for root, dirs, files in os.walk(REPO_ROOT):
    if any(ignore in root for ignore in ["node_modules", ".git", "dist", "implementation_plan", "tmp"]):
        continue
    for file in files:
        if file.endswith(".md"):
            md_count += 1
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            for match in link_pattern.finditer(content):
                label, url = match.groups()
                if url.startswith(("http://", "https://", "mailto:", "#")):
                    continue
                target_file = url.split("#")[0]
                if not target_file:
                    continue
                target_path = os.path.normpath(os.path.join(root, target_file))
                link_count += 1
                if not os.path.exists(target_path):
                    rel_src = os.path.relpath(path, REPO_ROOT)
                    broken_links += 1
                    warnings.append(f"Broken link in {rel_src}: '{url}' -> '{target_path}'")

print(f"Validated {md_count} Markdown files, {link_count} relative links. Broken links: {broken_links}")

# 4. Secret Scanner (Checking for accidental real keys)
print("\n--- 4. Checking for Accidental Secrets ---")
secret_patterns = [
    re.compile(r'BEGIN (RSA|EC|OPENSSH|PGP) PRIVATE KEY'),
    re.compile(r'ghp_[A-Za-z0-9_]{36}'),
    re.compile(r'AKIA[0-9A-Z]{16}'),
]
for root, dirs, files in os.walk(REPO_ROOT):
    if any(ignore in root for ignore in ["node_modules", ".git", "dist", "tmp"]):
        continue
    for file in files:
        if file.endswith((".md", ".yml", ".yaml", ".json", ".sh", ".cs", ".ts", ".go", ".html")):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            for sp in secret_patterns:
                if sp.search(content):
                    errors.append(f"Potential secret leak in {os.path.relpath(path, REPO_ROOT)}")

print(f"Secret check complete. Errors: {len([e for e in errors if 'secret' in e])}")

print("\n======================================================================")
print(f"Validation Summary: {len(errors)} Errors, {len(warnings)} Warnings")
if errors:
    print("ERRORS:")
    for e in errors:
        print(" -", e)
if warnings:
    print("WARNINGS:")
    for w in warnings[:20]:
        print(" -", w)
print("======================================================================")

if len(errors) > 0:
    sys.exit(1)
sys.exit(0)
