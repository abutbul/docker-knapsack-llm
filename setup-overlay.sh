#!/bin/bash

# Overlay filesystem setup script for WoW client
# This script sets up a copy-on-write overlay so that the read-only client files
# from /mnt/wow-client appear in /root/Desktop/Client with writable overlay

set -e

echo "Setting up overlay filesystem for WoW client..."

# Check if the read-only client files exist
if [ ! -d "/mnt/wow-client" ]; then
    echo "ERROR: Read-only client directory /mnt/wow-client not found!"
    echo "Make sure the wow-client directory is properly mounted."
    exit 1
fi

# Check if Wow.exe exists in the read-only mount
if [ ! -f "/mnt/wow-client/Wow.exe" ]; then
    echo "WARNING: Wow.exe not found in /mnt/wow-client/"
    echo "Please ensure your WoW client files are in the ./wow-client directory"
    echo "The overlay will still be created, but WoW may not launch properly"
fi

# Create the client directory if it doesn't exist
mkdir -p /root/Desktop/Client

# If Client directory is empty or doesn't have game files, set up the overlay
if [ ! -f "/root/Desktop/Client/Wow.exe" ]; then
    echo "Setting up client file overlay using bind mounts and symlinks..."
    
    # Create bind mounts for read-only files and symlinks for writable files
    # First, copy structure but use symlinks for executable and data files
    
    # Copy directory structure relative to the wow-client directory
    cd /mnt/wow-client
    find . -type d -exec mkdir -p "/root/Desktop/Client/{}" \; 2>/dev/null || true
    
    # Create symlinks for read-only files (executables, data files)
    find . -type f \( -name "*.exe" -o -name "*.dll" -o -name "*.MPQ" -o -name "*.mpq" \) \
        -exec ln -sf "/mnt/wow-client/{}" "/root/Desktop/Client/{}" \; 2>/dev/null || true
    
    # Copy (not symlink) writable files and directories
    # These are files that the game might modify
    find . -type f \( -name "*.wtf" -o -name "*.lua" -o -name "*.txt" -o -name "*.cfg" -o -name "*.log" \) \
        -exec cp "/mnt/wow-client/{}" "/root/Desktop/Client/{}" \; 2>/dev/null || true
    
    cd /
    
    # Handle special directories that need to be writable
    for dir in "WTF" "Logs" "Interface/AddOns" "Screenshots"; do
        if [ -d "/mnt/wow-client/$dir" ]; then
            rm -rf "/root/Desktop/Client/$dir" 2>/dev/null || true
            cp -r "/mnt/wow-client/$dir" "/root/Desktop/Client/$dir" 2>/dev/null || true
        fi
    done
    
    echo "Client overlay setup using symlinks and selective copying completed!"
else
    echo "Client files already present in /root/Desktop/Client"
fi

echo "Overlay filesystem setup complete!"
echo "Read-only client files: /mnt/wow-client"
echo "Writable overlay: /root/Desktop/Client"
echo "Symlinked read-only files, copied writable configs"

# Verify the setup
if [ -f "/root/Desktop/Client/Wow.exe" ]; then
    echo "SUCCESS: Wow.exe found in client directory"
    ls -la /root/Desktop/Client/Wow.exe
else
    echo "WARNING: Wow.exe not found in client directory"
fi

# List some files to verify the overlay is working
echo "Files in client directory:"
ls -la /root/Desktop/Client/ | head -10

# Show disk usage
echo "Disk usage comparison:"
echo "Original client size: $(du -sh /mnt/wow-client 2>/dev/null | cut -f1)"
echo "Overlay client size: $(du -sh /root/Desktop/Client 2>/dev/null | cut -f1)"
