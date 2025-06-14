#!/usr/bin/env python3
"""
Build script for creating Windows executable of IACLS Time Tracker
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

def build_windows_exe():
    """Build Windows executable using PyInstaller"""
    
    print("🔨 Building IACLS Time Tracker for Windows...")
    
    # Clean previous builds
    if Path("dist").exists():
        shutil.rmtree("dist")
    if Path("build").exists():
        shutil.rmtree("build")
    
    # PyInstaller command
    cmd = [
        sys.executable, "-m", "PyInstaller",
        "--onefile",
        "--windowed",
        "--name=IACLS_Time_Tracker",
        "--icon=icon.ico",  # Will create this
        "--add-data=bells-2-31725.mp3;.",
        "floating_button_windows.py"
    ]
    
    try:
        # Run PyInstaller
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print("✅ Build successful!")
        
        # Create distribution folder
        dist_folder = Path("dist_windows")
        if dist_folder.exists():
            shutil.rmtree(dist_folder)
        dist_folder.mkdir()
        
        # Copy executable
        exe_path = Path("dist/IACLS_Time_Tracker.exe")
        if exe_path.exists():
            shutil.copy2(exe_path, dist_folder / "IACLS_Time_Tracker.exe")
            print(f"✅ Executable created: {dist_folder / 'IACLS_Time_Tracker.exe'}")
        
        # Copy sound file
        if Path("bells-2-31725.mp3").exists():
            shutil.copy2("bells-2-31725.mp3", dist_folder)
        
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Build failed: {e}")
        print(f"Error output: {e.stderr}")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

def create_icon():
    """Create a simple icon file for Windows"""
    try:
        from PIL import Image, ImageDraw
        
        # Create a simple circular icon
        size = 256
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Draw outer circle (white border)
        draw.ellipse([10, 10, size-10, size-10], fill=(255, 255, 255, 255))
        
        # Draw inner circle (green)
        draw.ellipse([20, 20, size-20, size-20], fill=(76, 175, 80, 255))
        
        # Draw clock symbol
        center = size // 2
        draw.ellipse([center-40, center-40, center+40, center+40], outline=(255, 255, 255, 255), width=6)
        draw.line([center, center, center, center-25], fill=(255, 255, 255, 255), width=4)
        draw.line([center, center, center+15, center], fill=(255, 255, 255, 255), width=3)
        
        # Save as ICO
        img.save("icon.ico", format='ICO', sizes=[(256, 256), (128, 128), (64, 64), (32, 32), (16, 16)])
        print("✅ Icon created: icon.ico")
        return True
        
    except ImportError:
        print("⚠️  PIL not available, skipping icon creation")
        return False
    except Exception as e:
        print(f"⚠️  Icon creation failed: {e}")
        return False

if __name__ == "__main__":
    print("IACLS Time Tracker - Windows Build Script")
    print("=" * 50)
    
    # Check if we're on Windows or have wine
    if sys.platform != "win32":
        print("⚠️  This script is designed for Windows. You may need wine or a Windows VM.")
    
    # Create icon
    create_icon()
    
    # Build executable
    if build_windows_exe():
        print("\n🎉 Windows build complete!")
        print("📁 Files created in: dist_windows/")
    else:
        print("\n❌ Build failed!")
        sys.exit(1) 