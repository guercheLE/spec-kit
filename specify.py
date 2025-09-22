#!/usr/bin/env python3
"""
Specify CLI Wrapper - Works from any directory using absolute paths
"""
import os
import sys
import subprocess
from pathlib import Path

def main():
    # Get the absolute path to this script's directory
    _script_dir = Path(__file__).parent.absolute()
    _project_root = _script_dir
    
    # Get the current working directory
    current_cwd = Path.cwd()
    
    # Build the command to run from the project directory
    script_path = _project_root / "src" / "specify_cli" / "__init__.py"
    
    # Use uv to run the script from the project directory
    cmd = [
        "uv", "run", "python", str(script_path)
    ] + sys.argv[1:]  # Pass all command line arguments
    
    # Change to project directory and run the command
    try:
        os.chdir(_project_root)
        result = subprocess.run(cmd, cwd=_project_root)
        sys.exit(result.returncode)
    finally:
        # Restore original working directory
        os.chdir(current_cwd)

if __name__ == "__main__":
    main()
