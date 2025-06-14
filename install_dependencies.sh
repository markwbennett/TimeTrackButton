#!/bin/bash

echo "IACLS Time Tracker - Dependency Installer"
echo "========================================="

# Check if Python 3 is installed
PYTHON_CMD=""
for cmd in python3 python3.11 python3.10 python3.9 python; do
    if command -v "$cmd" >/dev/null 2>&1; then
        if "$cmd" -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)" 2>/dev/null; then
            PYTHON_CMD="$cmd"
            echo "Found Python: $cmd"
            break
        fi
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "❌ Python 3.8+ is required but not found."
    echo "Please install Python 3 from https://python.org or using Homebrew:"
    echo "  brew install python3"
    exit 1
fi

# Check if pip is available
if ! "$PYTHON_CMD" -m pip --version >/dev/null 2>&1; then
    echo "❌ pip is not available. Please install pip first."
    exit 1
fi

echo "Installing required packages..."

# Install packages
if "$PYTHON_CMD" -m pip install PyQt6 pandas; then
    echo "✅ Dependencies installed successfully!"
    echo ""
    echo "You can now run the IACLS Time Tracker app by double-clicking 'IACLS Time Tracker.app'"
else
    echo "❌ Failed to install dependencies."
    echo "You may need to run with sudo or use a virtual environment."
    exit 1
fi 