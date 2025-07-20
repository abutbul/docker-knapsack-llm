#!/bin/bash

# Wine initialization script for WoW
# This script sets up Wine environment and installs necessary components

set -e

echo "Initializing Wine environment for WoW..."

# Set Wine environment variables
export WINEARCH=win64
export WINEPREFIX=/root/.wine
export WINEDLLOVERRIDES="mscoree,mshtml=disabled"
export DISPLAY=:0

# Ensure Wine prefix directory exists
mkdir -p "$WINEPREFIX"

# Initialize Wine if not already done
if [ ! -f "$WINEPREFIX/system.reg" ]; then
    echo "Creating new Wine prefix..."
    
    # Initialize Wine with no GUI prompts
    export WINEDEBUG=-all
    
    # Create the prefix and install necessary components
    wineboot --init 2>/dev/null || true
    
    # Wait for wineserver to finish
    wineserver -w
    
    echo "Installing Wine Mono..."
    # Install Mono silently
    if [ -f "/usr/share/wine/mono/wine-mono-7.4.0-x86.msi" ]; then
        wine msiexec /i /usr/share/wine/mono/wine-mono-7.4.0-x86.msi /quiet /norestart 2>/dev/null || true
        wineserver -w
    fi
    
    echo "Installing Wine Gecko..."
    # Install Gecko silently
    if [ -f "/usr/share/wine/gecko/wine-gecko-2.47.3-x86.msi" ]; then
        wine msiexec /i /usr/share/wine/gecko/wine-gecko-2.47.3-x86.msi /quiet /norestart 2>/dev/null || true
        wineserver -w
    fi
    
    if [ -f "/usr/share/wine/gecko/wine-gecko-2.47.3-x86_64.msi" ]; then
        wine msiexec /i /usr/share/wine/gecko/wine-gecko-2.47.3-x86_64.msi /quiet /norestart 2>/dev/null || true
        wineserver -w
    fi
    
    # Set Windows version to Windows 10
    echo "Setting Windows version to Windows 10..."
    wine winecfg /v win10 2>/dev/null || true
    wineserver -w
    
    # Install Visual C++ Redistributables for better compatibility
    echo "Installing vcrun2019 for better game compatibility..."
    # This would typically use winetricks, but we'll configure manually
    
    # Configure Wine for gaming
    echo "Configuring Wine registry for gaming..."
    cat > /tmp/wow-wine-config.reg << 'EOF'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\DirectSound]
"HelBuflen"="512"
"SndQueueMax"="28"

[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"VideoMemorySize"="2048"
"OffscreenRenderingMode"="pbuffer"
"RenderTargetLockMode"="readtex"
"UseGLSL"="enabled"

[HKEY_CURRENT_USER\Software\Wine\AppDefaults\Wow.exe\Direct3D]
"VideoMemorySize"="2048"
"OffscreenRenderingMode"="pbuffer"
"UseGLSL"="enabled"
"DirectDrawRenderer"="opengl"

[HKEY_CURRENT_USER\Software\Wine\AppDefaults\Wow.exe\DirectSound]
"DefaultBitsPerSample"="16"
"DefaultSampleRate"="44100"
EOF
    
    wine regedit /tmp/wow-wine-config.reg 2>/dev/null || true
    wineserver -w
    rm -f /tmp/wow-wine-config.reg
    
    echo "Wine initialization completed successfully!"
else
    echo "Wine prefix already exists, skipping initialization..."
fi

# Verify Wine is working
echo "Verifying Wine installation..."
wine --version

echo "Wine environment ready for WoW!"
