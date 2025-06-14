#!/usr/bin/env python3
"""
Create a release package containing just the IACLS Time Tracker app
"""

import os
import shutil
import zipfile
from pathlib import Path

def create_app_release():
    """Create a ZIP file containing just the app bundle"""
    print("📦 Creating app-only release package...")
    
    app_source = Path("IACLS Time Tracker.app")
    if not app_source.exists():
        print("❌ IACLS Time Tracker.app not found")
        return False
    
    # Create temporary directory
    temp_dir = Path("temp_app_release")
    if temp_dir.exists():
        shutil.rmtree(temp_dir)
    temp_dir.mkdir()
    
    # Copy app bundle
    shutil.copytree(app_source, temp_dir / "IACLS Time Tracker.app")
    
    # Create ZIP file
    zip_name = "IACLS_Time_Tracker_App.zip"
    with zipfile.ZipFile(zip_name, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(temp_dir):
            for file in files:
                file_path = Path(root) / file
                # Calculate relative path from temp_dir
                arcname = file_path.relative_to(temp_dir)
                zipf.write(file_path, arcname)
    
    # Clean up
    shutil.rmtree(temp_dir)
    
    print(f"✅ Created: {zip_name}")
    return True

if __name__ == "__main__":
    create_app_release() 