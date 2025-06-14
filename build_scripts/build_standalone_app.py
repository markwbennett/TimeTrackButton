#!/usr/bin/env python3
"""
Build a standalone IACLS Time Tracker app bundle with embedded Python and dependencies
"""

import os
import sys
import shutil
import subprocess
from pathlib import Path

def build_standalone_app():
    """Build a standalone app bundle using PyInstaller"""
    print("🔨 Building standalone app bundle...")
    
    # Check if PyInstaller is installed
    try:
        import PyInstaller
    except ImportError:
        print("📦 Installing PyInstaller...")
        subprocess.run([sys.executable, "-m", "pip", "install", "pyinstaller"], check=True)
    
    # Clean previous builds
    build_dirs = ["build", "dist", "__pycache__"]
    for dir_name in build_dirs:
        if Path(dir_name).exists():
            shutil.rmtree(dir_name)
    
    # Remove existing app bundle
    app_bundle = Path("IACLS Time Tracker.app")
    if app_bundle.exists():
        shutil.rmtree(app_bundle)
    
    # PyInstaller command with explicit PyQt6 inclusion
    cmd = [
        sys.executable, "-m", "PyInstaller",
        "--name=IACLS Time Tracker",
        "--windowed",
        "--onedir",
        "--clean",
        "--noconfirm",
        "--add-data=bells-2-31725.mp3:.",
        "--icon=icon.ico",
        "--osx-bundle-identifier=org.iacls.timetracker",
        "--hidden-import=PyQt6",
        "--hidden-import=PyQt6.QtCore",
        "--hidden-import=PyQt6.QtGui", 
        "--hidden-import=PyQt6.QtWidgets",
        "--hidden-import=PyQt6.QtMultimedia",
        "--hidden-import=pandas",
        "--collect-all=PyQt6",
        "floating_button.py"
    ]
    
    print("🚀 Running PyInstaller...")
    print(f"Command: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print("✅ PyInstaller completed successfully")
    except subprocess.CalledProcessError as e:
        print(f"❌ PyInstaller failed: {e}")
        print(f"stdout: {e.stdout}")
        print(f"stderr: {e.stderr}")
        return False
    
    # Check if app was created
    built_app = Path("dist/IACLS Time Tracker.app")
    if not built_app.exists():
        print("❌ App bundle not found in dist/")
        return False
    
    # Move app to root directory
    shutil.move(str(built_app), str(app_bundle))
    
    # Clean up build artifacts
    for dir_name in build_dirs:
        if Path(dir_name).exists():
            shutil.rmtree(dir_name)
    
    if Path("dist").exists():
        shutil.rmtree("dist")
    
    # Remove spec file
    spec_file = Path("IACLS Time Tracker.spec")
    if spec_file.exists():
        spec_file.unlink()
    
    print(f"✅ Standalone app created: {app_bundle}")
    print("📦 App bundle now includes all Python dependencies")
    
    return True

if __name__ == "__main__":
    if not build_standalone_app():
        sys.exit(1)
    print("🎉 Build complete!") 