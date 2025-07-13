#!/bin/bash

mkdir -p input
cd input

# Create directory structure
mkdir -p src/components
mkdir -p tests/unit
mkdir -p docs
mkdir -p config
mkdir -p scripts

# Create files
echo "# Project README" > README.md
echo "print('Hello World')" > main.py
echo "# Configuration" > config/settings.json
echo "#!/bin/bash" > scripts/build.sh
echo "def test_main(): pass" > tests/unit/test_main.py
echo "import React from 'react';" > src/components/App.jsx
echo ".env" > .gitignore
echo "pytest==7.4.0" > requirements.txt
echo "# Documentation" > docs/guide.md
echo "FROM python:3.10" > Dockerfile

echo "Test environment created successfully!"
