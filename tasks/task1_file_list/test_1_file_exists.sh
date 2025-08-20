#!/bin/bash

# Test 1: Check if files.json exists
set -e

echo "Test 1: Checking if files.json exists..."

files_json_path="input/files.json"

if [ ! -f "$files_json_path" ]; then
    echo "ERROR: files.json not found at $files_json_path!"
    echo "The task requires creating a files.json file in the input directory."
    exit 1
fi

echo "SUCCESS: files.json exists!"
echo "File found at: $files_json_path"

# Check file is not empty
if [ ! -s "$files_json_path" ]; then
    echo "ERROR: files.json exists but is empty!"
    exit 1
fi

echo "✓ File exists and is not empty"