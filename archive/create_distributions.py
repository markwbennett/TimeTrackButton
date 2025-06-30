#!/usr/bin/env python3
"""
Create distribution packages for IACLS Time Tracker
Generates PDFs from markdown documentation and creates platform-specific packages
"""

import os
import sys
import shutil
import subprocess
import zipfile
from pathlib import Path

def install_dependencies():
    """Install required dependencies for PDF generation"""
    try:
        import markdown
        import pdfkit
        import weasyprint
    except ImportError:
        print("📦 Installing PDF generation dependencies...")
        subprocess.run([sys.executable, "-m", "pip", "install", "markdown", "pdfkit", "weasyprint"], check=True)

def markdown_to_pdf_weasyprint(md_file, pdf_file):
    """Convert markdown to PDF using WeasyPrint"""
    try:
        import markdown
        import weasyprint
        
        # Read markdown
        with open(md_file, 'r', encoding='utf-8') as f:
            md_content = f.read()
        
        # Convert to HTML
        html = markdown.markdown(md_content, extensions=['codehilite', 'fenced_code'])
        
        # Add CSS styling
        styled_html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body {{
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.6;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 20px;
                    color: #333;
                }}
                h1, h2, h3 {{
                    color: #2c3e50;
                    border-bottom: 2px solid #3498db;
                    padding-bottom: 10px;
                }}
                h1 {{ font-size: 2.5em; }}
                h2 {{ font-size: 2em; }}
                h3 {{ font-size: 1.5em; }}
                code {{
                    background-color: #f8f9fa;
                    padding: 2px 4px;
                    border-radius: 3px;
                    font-family: 'Monaco', 'Consolas', monospace;
                }}
                pre {{
                    background-color: #f8f9fa;
                    padding: 15px;
                    border-radius: 5px;
                    border-left: 4px solid #3498db;
                    overflow-x: auto;
                }}
                blockquote {{
                    border-left: 4px solid #3498db;
                    margin: 0;
                    padding-left: 20px;
                    color: #666;
                }}
                ul, ol {{
                    padding-left: 30px;
                }}
                li {{
                    margin-bottom: 5px;
                }}
                strong {{
                    color: #2c3e50;
                }}
                .page-break {{
                    page-break-before: always;
                }}
            </style>
        </head>
        <body>
        {html}
        </body>
        </html>
        """
        
        # Generate PDF
        weasyprint.HTML(string=styled_html).write_pdf(pdf_file)
        return True
        
    except Exception as e:
        print(f"❌ WeasyPrint failed: {e}")
        return False

def markdown_to_pdf_pandoc(md_file, pdf_file):
    """Convert markdown to PDF using Pandoc (fallback)"""
    try:
        cmd = [
            "pandoc",
            str(md_file),
            "-o", str(pdf_file),
            "--pdf-engine=wkhtmltopdf",
            "--variable", "geometry:margin=1in",
            "--variable", "fontsize=11pt"
        ]
        subprocess.run(cmd, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def create_pdf_from_markdown(md_file, pdf_file):
    """Create PDF from markdown using available tools"""
    print(f"📄 Converting {md_file} to PDF...")
    
    # Try WeasyPrint first
    if markdown_to_pdf_weasyprint(md_file, pdf_file):
        print(f"✅ PDF created: {pdf_file}")
        return True
    
    # Try Pandoc as fallback
    if markdown_to_pdf_pandoc(md_file, pdf_file):
        print(f"✅ PDF created: {pdf_file}")
        return True
    
    print(f"❌ Failed to create PDF: {pdf_file}")
    return False

def create_macos_package():
    """Create macOS distribution package"""
    print("🍎 Creating macOS package...")
    
    package_dir = Path("dist_macos")
    if package_dir.exists():
        shutil.rmtree(package_dir)
    package_dir.mkdir()
    
    # Copy app bundle
    app_source = Path("IACLS Time Tracker.app")
    if app_source.exists():
        shutil.copytree(app_source, package_dir / "IACLS Time Tracker.app")
    
    # Copy Easy Installer
    installer_source = Path("Easy_Installer.app")
    if installer_source.exists():
        shutil.copytree(installer_source, package_dir / "Easy_Installer.app")
    
    # Copy installer README
    if Path("Easy_Installer_README.txt").exists():
        shutil.copy2("Easy_Installer_README.txt", package_dir)
    
    # Create documentation
    docs_dir = package_dir / "Documentation"
    docs_dir.mkdir()
    
    # Generate PDF
    create_pdf_from_markdown("docs/macOS_Installation_Guide.md", docs_dir / "macOS_Installation_Guide.pdf")
    
    # Copy markdown as backup
    shutil.copy2("docs/macOS_Installation_Guide.md", docs_dir)
    
    # Copy license and readme
    if Path("LICENSE").exists():
        shutil.copy2("LICENSE", docs_dir)
    if Path("README.md").exists():
        shutil.copy2("README.md", docs_dir)
    
    # Create README for package
    package_readme = package_dir / "README.txt"
    with open(package_readme, 'w') as f:
        f.write("""IACLS Time Tracker - macOS Distribution
=====================================

Contents:
- Easy_Installer.app - One-click installer (installs Homebrew + app)
- IACLS Time Tracker.app - Main GUI application
- Documentation/ - Installation guides and documentation
- Easy_Installer_README.txt - Instructions for the easy installer

Installation Options:

EASIEST (Recommended for beginners):
1. Double-click Easy_Installer.app
2. Follow the prompts
3. Enter your password when asked
4. Launch the app when installation completes

MANUAL:
1. Double-click IACLS Time Tracker.app to launch
2. Choose your data folder on first run

Note: For SketchyBar integration, clone the repository from:
https://github.com/markwbennett/TimeTrackButton

For manual setup, see the documentation folder.

Support: https://github.com/markwbennett/TimeTrackButton
""")
    
    return package_dir

def create_windows_package():
    """Create Windows distribution package"""
    print("🪟 Creating Windows package...")
    
    package_dir = Path("dist_windows_package")
    if package_dir.exists():
        shutil.rmtree(package_dir)
    package_dir.mkdir()
    
    # Copy executable (if it exists)
    exe_source = Path("dist_windows/IACLS_Time_Tracker.exe")
    if exe_source.exists():
        shutil.copy2(exe_source, package_dir)
    else:
        print("⚠️  Windows executable not found. Run build_windows.py first.")
    
    # Copy sound file
    if Path("bells-2-31725.mp3").exists():
        shutil.copy2("bells-2-31725.mp3", package_dir)
    
    # Copy Python source as alternative
    if Path("floating_button_windows.py").exists():
        shutil.copy2("floating_button_windows.py", package_dir)
    
    # Copy requirements
    if Path("requirements_windows.txt").exists():
        shutil.copy2("requirements_windows.txt", package_dir)
    
    # Create documentation
    docs_dir = package_dir / "Documentation"
    docs_dir.mkdir()
    
    # Generate PDF
    create_pdf_from_markdown("docs/Windows_Installation_Guide.md", docs_dir / "Windows_Installation_Guide.pdf")
    
    # Copy markdown as backup
    shutil.copy2("docs/Windows_Installation_Guide.md", docs_dir)
    
    # Copy license and readme
    if Path("LICENSE").exists():
        shutil.copy2("LICENSE", docs_dir)
    if Path("README.md").exists():
        shutil.copy2("README.md", docs_dir)
    
    # Create README for package
    package_readme = package_dir / "README.txt"
    with open(package_readme, 'w') as f:
        f.write("""IACLS Time Tracker - Windows Distribution
========================================

Contents:
- IACLS_Time_Tracker.exe - Main application (if built)
- floating_button_windows.py - Python source code
- bells-2-31725.mp3 - Chime sound file
- requirements_windows.txt - Python dependencies
- Documentation/ - Installation guides and documentation

Quick Start:
1. Read Documentation/Windows_Installation_Guide.pdf
2. Run IACLS_Time_Tracker.exe (recommended)
   OR
   Install Python and run: pip install -r requirements_windows.txt
   Then: python floating_button_windows.py

Security Note:
Windows may show security warnings for unsigned executables.
See documentation for details on handling these warnings.

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
    print("🚀 IACLS Time Tracker - Distribution Creator")
    print("=" * 50)
    
    # Install dependencies
    try:
        install_dependencies()
    except Exception as e:
        print(f"⚠️  Could not install PDF dependencies: {e}")
        print("PDFs may not be generated properly")
    
    # Create docs directory
    Path("docs").mkdir(exist_ok=True)
    
    # Create distribution packages
    packages_created = []
    
    # macOS package
    try:
        macos_package = create_macos_package()
        zip_name = "IACLS_Time_Tracker_macOS.zip"
        create_zip_archive(macos_package, zip_name)
        packages_created.append(zip_name)
    except Exception as e:
        print(f"❌ macOS package creation failed: {e}")
    
    # Windows package
    try:
        windows_package = create_windows_package()
        zip_name = "IACLS_Time_Tracker_Windows.zip"
        create_zip_archive(windows_package, zip_name)
        packages_created.append(zip_name)
    except Exception as e:
        print(f"❌ Windows package creation failed: {e}")
    
    # Summary
    print("\n🎉 Distribution Creation Complete!")
    print("=" * 50)
    
    if packages_created:
        print("📦 Packages created:")
        for package in packages_created:
            print(f"   - {package}")
        
        print("\n📋 Next steps:")
        print("1. Test packages on target platforms")
        print("2. Upload to GitHub releases")
        print("3. Update repository documentation")
        print("4. Make repositories public")
    else:
        print("❌ No packages were created successfully")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main()) 