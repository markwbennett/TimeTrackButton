#!/usr/bin/env python3
"""
Create x86_64 distribution packages for IACLS Time Tracker (Intel Macs)
"""

import os
import sys
import shutil
import subprocess
import zipfile
from pathlib import Path

def create_macos_x86_package():
    """Create macOS x86_64 distribution package"""
    print("🍎 Creating macOS x86_64 package...")
    
    package_dir = Path("dist_macos_x86")
    if package_dir.exists():
        shutil.rmtree(package_dir)
    package_dir.mkdir()
    
    # Copy x86_64 app bundle
    app_source = Path("cpp_app/TimeTracker_x86_64.app")
    if app_source.exists():
        shutil.copytree(app_source, package_dir / "IACLS Time Tracker x86_64.app")
        print("✅ Copied x86_64 app bundle")
    else:
        print("❌ x86_64 app bundle not found at cpp_app/TimeTracker_x86_64.app")
        return None
    
    # Create documentation
    docs_dir = package_dir / "Documentation"
    docs_dir.mkdir()
    
    # Copy documentation files
    if Path("docs/macOS_Installation_Guide.md").exists():
        shutil.copy2("docs/macOS_Installation_Guide.md", docs_dir)
    if Path("LICENSE").exists():
        shutil.copy2("LICENSE", docs_dir)
    if Path("README.md").exists():
        shutil.copy2("README.md", docs_dir)
    
    # Create README for x86_64 package
    package_readme = package_dir / "README.txt"
    with open(package_readme, 'w') as f:
        f.write("""IACLS Time Tracker - macOS x86_64 Distribution (Intel Macs)
===========================================================

Contents:
- IACLS Time Tracker x86_64.app - Main application for Intel Macs
- Documentation/ - Installation guides and documentation

IMPORTANT: This version is for Intel Macs only!
For Apple Silicon (M1/M2/M3) Macs, use the ARM64 version instead.

Installation:
1. Double-click "IACLS Time Tracker x86_64.app" to launch
2. Choose your data folder on first run
3. The app will create a floating button on your desktop

Architecture: x86_64 (Intel)
Minimum macOS: 10.15 (Catalina)

Note: You may need to allow the app in System Preferences > Security & Privacy
if you see a security warning on first launch.

For SketchyBar integration, clone the repository from:
https://github.com/markwbennett/TimeTrackButton

Support: https://github.com/markwbennett/TimeTrackButton
""")
    
    return package_dir

def create_zip_archive(source_dir, zip_name):
    """Create ZIP archive of a directory"""
    print(f"📦 Creating {zip_name}...")
    
    with zipfile.ZipFile(zip_name, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(source_dir):
            for file in files:
                file_path = Path(root) / file
                arc_path = file_path.relative_to(source_dir)
                zipf.write(file_path, arc_path)
    
    print(f"✅ Created: {zip_name}")

def main():
    """Main distribution creation process"""
    print("🚀 IACLS Time Tracker - x86_64 Distribution Creator")
    print("=" * 60)
    
    # Create x86_64 macOS package
    try:
        macos_package = create_macos_x86_package()
        if macos_package:
            zip_name = "IACLS_Time_Tracker_macOS_x86_64.zip"
            create_zip_archive(macos_package, zip_name)
            print(f"\n🎉 x86_64 Distribution Created: {zip_name}")
            print("📋 This package is for Intel Macs only.")
            return 0
        else:
            print("❌ Failed to create x86_64 package")
            return 1
    except Exception as e:
        print(f"❌ x86_64 package creation failed: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main()) 