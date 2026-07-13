#!/usr/bin/env python3

"""
wb.py - Web Search Utility for WSL and Native OS.

This script allows users to perform Google searches from the command line.
It specifically handles the Windows Subsystem for Linux (WSL) by routing 
the request through PowerShell to open the host machine's browser.
"""

import webbrowser
import urllib.parse
import sys
import os
import subprocess
from pathlib import Path

def open_url(url: str) -> None:
    """
    Opens the URL by Checking if we are in WSL or not and running Command in PowerShell if in WSL.
    
    Args:
        url (str): The url to search in the web browser,
    """
    # Check if  running in WSL
    if "microsoft" in os.uname().release.lower():
        # If it's a local file, we need to convert the WSL path to a Windows UNC path
        if url.startswith("file://"):
            # strip 'file://' to get the raw path
            linux_path = url.replace("file://", "")
            # Use wslpath to get the Windows-style path (e.g., \\wsl$\Ubuntu\home\...)
            try:
                win_path = subprocess.check_output(["wslpath", "-w", linux_path], text=True).strip()
                url = win_path
            except subprocess.CalledProcessError:
                pass # Fallback to original URL if wslpath fails

        # Use PowerShell's Start-Process which handles both URLs and Windows paths perfectly
        subprocess.run(["powershell.exe", "-Command", f"Start-Process '{url}'"], 
                       stdout=subprocess.DEVNULL, 
                       stderr=subprocess.DEVNULL)
    else:
        # Standard Linux/Mac/Windows behavior
        webbrowser.open(url)

def main():
    """
    The Main Function.
    """
    if len(sys.argv) < 2:
        print("Usage: wb \"search term\"")
        sys.exit(1)
    
    # Join arguments to handle spaces in filenames or search queries
    input_str = " ".join(sys.argv[1:])
    
    # Check if the input is an existing local file
    local_path = Path(input_str)
    
    if local_path.exists():
        # Get absolute path and convert to file:// URI
        # .as_uri() is the cleanest way to handle special characters
        final_target = local_path.resolve().as_uri()
        print(f"Opening file: {local_path.name}")
    else:
        # Treat as a search query
        query = urllib.parse.quote(input_str)
        final_target = f"https://www.google.com/search?q={query}"
        print(f"Searching for: {input_str}")
    
    open_url(final_target)

if __name__ == "__main__":
    main()