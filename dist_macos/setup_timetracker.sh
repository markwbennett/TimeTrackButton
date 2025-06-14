#!/bin/bash

echo "🕐 IACLS Time Tracker Setup"
echo "=========================="
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Python packages
check_packages() {
    local python_cmd="$1"
    "$python_cmd" -c "import PyQt6, pandas, sqlite3" 2>/dev/null
}

# Check for Python 3
echo "🔍 Checking Python installation..."
PYTHON_CMD=""
for cmd in python3 python3.12 python3.11 python3.10 python3.9 python; do
    if command_exists "$cmd"; then
        if "$cmd" -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)" 2>/dev/null; then
            PYTHON_CMD="$cmd"
            echo "✅ Found Python: $cmd ($("$cmd" --version))"
            break
        fi
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "❌ Python 3.8+ not found."
    echo ""
    echo "Please install Python 3:"
    echo "  Option 1 - Using Homebrew (recommended):"
    echo "    brew install python3"
    echo ""
    echo "  Option 2 - Download from python.org:"
    echo "    https://www.python.org/downloads/"
    echo ""
    exit 1
fi

# Check for pip
echo ""
echo "🔍 Checking pip..."
if ! "$PYTHON_CMD" -m pip --version >/dev/null 2>&1; then
    echo "❌ pip not found. Installing pip..."
    if ! "$PYTHON_CMD" -m ensurepip --upgrade; then
        echo "❌ Failed to install pip. Please install pip manually."
        exit 1
    fi
fi
echo "✅ pip is available"

# Check for required packages
echo ""
echo "🔍 Checking required packages..."
if check_packages "$PYTHON_CMD"; then
    echo "✅ All packages already installed!"
else
    echo "📦 Installing required packages..."
    echo "   This may take a few minutes..."
    
    if "$PYTHON_CMD" -m pip install --user PyQt6 pandas; then
        echo "✅ Packages installed successfully!"
    else
        echo "❌ Failed to install packages."
        echo ""
        echo "Try installing manually:"
        echo "  $PYTHON_CMD -m pip install --user PyQt6 pandas"
        echo ""
        echo "Or with sudo (if needed):"
        echo "  sudo $PYTHON_CMD -m pip install PyQt6 pandas"
        exit 1
    fi
fi

# Final verification
echo ""
echo "🧪 Testing installation..."
if check_packages "$PYTHON_CMD"; then
    echo "✅ All packages working correctly!"
    echo ""
    echo "🎉 Setup complete!"
    echo ""
    echo "You can now:"
    echo "  • Double-click 'IACLS Time Tracker.app' to launch the floating button"
    echo "  • Use the SketchyBar integration (if configured)"
    echo "  • Run 'python3 floating_button.py' directly"
    echo ""
    echo "The app will sync state between all interfaces automatically."
else
    echo "❌ Package verification failed."
    echo "Please check the installation and try again."
    exit 1
fi 