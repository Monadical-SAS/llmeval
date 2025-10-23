#!/bin/bash
set -euo pipefail

echo "Test 2: Checking deep merge of nested objects..."

# Ensure we're in the correct directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/input" || { echo "ERROR: Failed to cd to input directory"; exit 1; }

python3 << 'EOF'
import json
import sys

with open('merged.json', 'r') as f:
    merged = json.load(f)

errors = []

# server.host should be preserved from base
if merged.get('server', {}).get('host') != 'localhost':
    errors.append(f"server.host should be 'localhost' (preserved), got '{merged.get('server', {}).get('host')}'")

# server.port should be overridden
if merged.get('server', {}).get('port') != 8080:
    errors.append(f"server.port should be 8080 (overridden), got {merged.get('server', {}).get('port')}")

# server.timeout should be preserved from base
if merged.get('server', {}).get('timeout') != 30:
    errors.append(f"server.timeout should be 30 (preserved), got {merged.get('server', {}).get('timeout')}")

# ssl should be merged properly
ssl = merged.get('server', {}).get('ssl', {})
if ssl.get('enabled') is not True:
    errors.append("server.ssl.enabled should be true (overridden)")
if not ssl.get('cert'):
    errors.append("server.ssl.cert should exist (added from override)")

# database.type preserved, pool.max overridden, pool.idle added
if merged.get('database', {}).get('type') != 'postgres':
    errors.append("database.type should be 'postgres' (preserved)")
if merged.get('database', {}).get('pool', {}).get('max') != 20:
    errors.append("database.pool.max should be 20 (overridden)")
if merged.get('database', {}).get('pool', {}).get('min') != 2:
    errors.append("database.pool.min should be 2 (preserved)")
if 'idle' not in merged.get('database', {}).get('pool', {}):
    errors.append("database.pool.idle should exist (added)")

if errors:
    print("ERROR: Deep merge failed:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)

print("✓ Deep merge working correctly")
EOF