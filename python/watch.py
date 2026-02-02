#!/usr/bin/env python3
import os
import sys
import time
import subprocess
from pathlib import Path

def clear_screen():
    """Clear the terminal screen"""
    os.system('clear' if os.name != 'nt' else 'cls')

def run_script(filepath):
    """Run the Python script and display output"""
    clear_screen()
    print(f"🔄 Running {filepath}...")
    print("=" * 50)
    try:
        result = subprocess.run(
            [sys.executable, filepath],
            capture_output=False,
            text=True
        )
        print("=" * 50)
        print(f"✓ Finished (Exit code: {result.returncode})")
    except Exception as e:
        print(f"❌ Error running script: {e}")
    print("\n👀 Watching for changes... (Press Ctrl+C to stop)")

def watch_file(filepath):
    """Watch a file for changes and run it when modified"""
    filepath = Path(filepath)
    
    if not filepath.exists():
        print(f"❌ Error: File '{filepath}' not found!")
        return
    
    print(f"👀 Watching {filepath} for changes...")
    print("Press Ctrl+C to stop\n")
    
    # Get initial modification time
    last_mtime = filepath.stat().st_mtime
    
    # Run the script initially
    run_script(filepath)
    
    try:
        while True:
            time.sleep(0.5)  # Check every 500ms
            current_mtime = filepath.stat().st_mtime
            
            if current_mtime != last_mtime:
                last_mtime = current_mtime
                time.sleep(0.1)  # Small delay to ensure file is fully written
                run_script(filepath)
    
    except KeyboardInterrupt:
        print("\n\n👋 Stopped watching. Goodbye!")
    except Exception as e:
        print(f"\n❌ Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python watch.py <filename>")
        print("Example: python watch.py main.py")
        sys.exit(1)
    
    watch_file(sys.argv[1])
