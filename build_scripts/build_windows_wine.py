#!/usr/bin/env python3
"""
Build Windows executable using Wine on macOS
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

def run_wine_command(cmd, cwd=None):
    """Run a command in Wine environment"""
    try:
        # Set Wine environment
        env = os.environ.copy()
        env['WINEARCH'] = 'win64'
        env['WINEPREFIX'] = str(Path.home() / '.wine_timetracker')
        
        result = subprocess.run(cmd, shell=True, cwd=cwd, env=env, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ {cmd}")
            return True, result.stdout
        else:
            print(f"❌ {cmd}")
            print(f"Error: {result.stderr}")
            return False, result.stderr
    except Exception as e:
        print(f"❌ Exception running {cmd}: {e}")
        return False, str(e)

def setup_wine_environment():
    """Set up Wine environment for Python and PyInstaller"""
    print("🍷 Setting up Wine environment...")
    
    wine_prefix = Path.home() / '.wine_timetracker'
    
    # Initialize Wine prefix
    print("Initializing Wine prefix...")
    success, output = run_wine_command("winecfg")
    if not success:
        print("❌ Failed to initialize Wine")
        return False
    
    # Download and install Python in Wine
    print("Installing Python in Wine...")
    python_installer = "python-3.11.9-amd64.exe"
    python_url = f"https://www.python.org/ftp/python/3.11.9/{python_installer}"
    
    # Download Python installer
    if not Path(python_installer).exists():
        print(f"Downloading {python_installer}...")
        success, _ = run_wine_command(f"curl -L -o {python_installer} {python_url}")
        if not success:
            print("❌ Failed to download Python installer")
            return False
    
    # Install Python silently
    print("Installing Python...")
    success, _ = run_wine_command(f"wine {python_installer} /quiet InstallAllUsers=1 PrependPath=1")
    if not success:
        print("❌ Failed to install Python in Wine")
        return False
    
    # Install required packages
    print("Installing Python packages...")
    packages = ["PyQt6", "pandas", "pyinstaller", "pillow"]
    for package in packages:
        print(f"Installing {package}...")
        success, _ = run_wine_command(f"wine python -m pip install {package}")
        if not success:
            print(f"⚠️  Failed to install {package}, continuing...")
    
    return True

def build_windows_exe_wine():
    """Build Windows executable using Wine"""
    print("🔨 Building Windows executable with Wine...")
    
    # Clean previous builds
    if Path("dist").exists():
        shutil.rmtree("dist")
    if Path("build").exists():
        shutil.rmtree("build")
    
    # Create icon if it doesn't exist
    if not Path("icon.ico").exists():
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
            
        except Exception as e:
            print(f"⚠️  Icon creation failed: {e}")
    
    # Build with PyInstaller in Wine
    pyinstaller_cmd = (
        "wine python -m PyInstaller "
        "--onefile "
        "--windowed "
        "--name=IACLS_Time_Tracker "
        "--icon=icon.ico "
        "--add-data=\"bells-2-31725.mp3;.\" "
        "floating_button_windows.py"
    )
    
    success, output = run_wine_command(pyinstaller_cmd)
    if not success:
        print("❌ PyInstaller build failed")
        return False
    
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
    else:
        print("❌ Executable not found after build")
        return False
    
    # Copy sound file
    if Path("bells-2-31725.mp3").exists():
        shutil.copy2("bells-2-31725.mp3", dist_folder)
    
    return True

def main():
    """Main build process"""
    print("🚀 IACLS Time Tracker - Windows Build with Wine")
    print("=" * 50)
    
    # Check if Wine is installed
    try:
        result = subprocess.run(["wine", "--version"], capture_output=True, text=True)
        if result.returncode != 0:
            print("❌ Wine is not installed. Please install it first:")
            print("   brew install --cask wine-stable")
            return 1
        print(f"✅ Wine version: {result.stdout.strip()}")
    except FileNotFoundError:
        print("❌ Wine is not installed. Please install it first:")
        print("   brew install --cask wine-stable")
        return 1
    
    # Check if Wine environment is set up
    wine_prefix = Path.home() / '.wine_timetracker'
    python_exe = wine_prefix / "drive_c/Program Files/Python311/python.exe"
    
    if not python_exe.exists():
        print("🔧 Setting up Wine environment (this may take a while)...")
        if not setup_wine_environment():
            print("❌ Failed to set up Wine environment")
            return 1
    else:
        print("✅ Wine environment already set up")
    
    # Build executable
    if build_windows_exe_wine():
        print("\n🎉 Windows build complete!")
        print("📁 Files created in: dist_windows/")
        
        # Now recreate the Windows package with the executable
        print("\n📦 Recreating Windows distribution package...")
        try:
            subprocess.run([sys.executable, "create_distributions.py"], check=True)
            print("✅ Distribution packages updated")
        except subprocess.CalledProcessError as e:
            print(f"⚠️  Failed to update distribution packages: {e}")
        
        return 0
    else:
        print("\n❌ Build failed!")
        return 1

if __name__ == "__main__":
    sys.exit(main()) 