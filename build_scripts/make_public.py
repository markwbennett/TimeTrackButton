#!/usr/bin/env python3
"""
Make IACLS Time Tracker repositories public
"""

import subprocess
import sys
from pathlib import Path

def run_command(cmd, cwd=None):
    """Run a command and return success status"""
    try:
        result = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ {cmd}")
            if result.stdout.strip():
                print(f"   {result.stdout.strip()}")
            return True
        else:
            print(f"❌ {cmd}")
            if result.stderr.strip():
                print(f"   Error: {result.stderr.strip()}")
            return False
    except Exception as e:
        print(f"❌ {cmd} - Exception: {e}")
        return False

def main():
    """Make repositories public"""
    print("🚀 Making IACLS Time Tracker repositories public")
    print("=" * 50)
    
    # Check if GitHub CLI is installed
    if not run_command("gh --version"):
        print("❌ GitHub CLI (gh) is not installed. Please install it first:")
        print("   brew install gh")
        return 1
    
    # Check if authenticated
    if not run_command("gh auth status"):
        print("❌ Not authenticated with GitHub. Please run:")
        print("   gh auth login")
        return 1
    
    # Create and make main repository public
    print("\n📦 Main Repository (TimeTrackButton)")
    print("-" * 30)
    
    main_repo_path = Path.cwd()
    
    # Check if repository exists on GitHub
    repo_exists = run_command("gh repo view markwbennett/TimeTrackButton", cwd=main_repo_path)
    
    if not repo_exists:
        print("Creating repository on GitHub...")
        if not run_command("gh repo create markwbennett/TimeTrackButton --public --source=. --remote=origin --push", cwd=main_repo_path):
            return 1
    else:
        # Make repository public if it exists
        if not run_command("gh repo edit markwbennett/TimeTrackButton --visibility public --accept-visibility-change-consequences", cwd=main_repo_path):
            return 1
    
    # Create and make homebrew tap repository public
    print("\n🍺 Homebrew Tap Repository")
    print("-" * 30)
    
    tap_repo_path = Path("/Users/markbennett/github/homebrew-iacls")
    
    if tap_repo_path.exists():
        # Check if repository exists on GitHub
        tap_exists = run_command("gh repo view markwbennett/homebrew-iacls", cwd=tap_repo_path)
        
        if not tap_exists:
            print("Creating homebrew tap repository on GitHub...")
            if not run_command("gh repo create markwbennett/homebrew-iacls --public --source=. --remote=origin --push", cwd=tap_repo_path):
                return 1
        else:
            # Make repository public and push if it exists
            if not run_command("gh repo edit markwbennett/homebrew-iacls --visibility public --accept-visibility-change-consequences", cwd=tap_repo_path):
                return 1
            run_command("git push origin main", cwd=tap_repo_path)
    else:
        print("⚠️  Homebrew tap repository not found at expected location")
    
    print("\n🎉 Repositories are now public!")
    print("📋 Repository URLs:")
    print("   Main: https://github.com/markwbennett/TimeTrackButton")
    print("   Tap:  https://github.com/markwbennett/homebrew-iacls")
    
    return 0

if __name__ == "__main__":
    sys.exit(main()) 