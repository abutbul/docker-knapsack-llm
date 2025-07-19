#!/bin/bash
set -e

echo "Starting container setup..."

# Remove stale lock files
rm -f /tmp/.X0-lock /tmp/.X11-unix/X0

# Create required directories and files
mkdir -p /root/.vnc
mkdir -p /tmp/.X11-unix
touch /root/.Xresources
[ -f /root/.Xauthority ] || touch /root/.Xauthority

# Initialize D-Bus
mkdir -p /var/run/dbus
dbus-daemon --system --fork || true

# Set VNC password
VNC_PASSWD=${VNC_PASSWD:-password}
echo "$VNC_PASSWD" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd

# Create xstartup script for LXDE
cat > /root/.vnc/xstartup <<EOF
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Load X resources
xrdb \$HOME/.Xresources

# Set a basic window manager background
xsetroot -solid grey

# Initialize session management properly
export XDG_SESSION_TYPE=x11
export XDG_SESSION_CLASS=user
export XDG_SESSION_DESKTOP=LXDE

# Start D-Bus session if not already running
if [ -z "\$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval \$(dbus-launch --sh-syntax --exit-with-session)
fi

# Start LXDE session - try multiple approaches
if command -v startlxde >/dev/null 2>&1; then
    echo "Starting LXDE with startlxde"
    exec startlxde
elif command -v lxsession >/dev/null 2>&1; then
    echo "Starting LXDE with lxsession"
    exec lxsession -s LXDE -e LXDE
else
    echo "LXDE not found, starting basic X session"
    # Fallback to basic X session
    exec xterm
fi
EOF
chmod +x /root/.vnc/xstartup

echo "Starting TigerVNC server..."
# Don't use Xvfb, let TigerVNC create its own X server
VNC_GEOMETRY=${VNC_GEOMETRY:-1024x768}
VNC_DEPTH=${VNC_DEPTH:-16}

# Start VNC server with more verbose output and better error handling
tigervncserver :0 \
    -geometry $VNC_GEOMETRY \
    -depth $VNC_DEPTH \
    -localhost no \
    -SecurityTypes VncAuth \
    -passwd /root/.vnc/passwd \
    -xstartup /root/.vnc/xstartup \
    -verbose

# Wait a moment for the server to start
sleep 5

echo "TigerVNC server started"

# Verify the VNC server is running
ps aux | grep Xtigervnc || ps aux | grep vnc

echo "Starting API server..."
export DISPLAY=:0
python3 /opt/api.py &
API_PID=$!

echo "All services started. Entering wait loop..."
# Keep the container running - tail the VNC log file
# The log file format is hostname:port.log, so we need to find it dynamically
VNC_LOG_FILE=$(ls /root/.vnc/*.log 2>/dev/null | head -1)
if [ -n "$VNC_LOG_FILE" ]; then
    echo "Following VNC log file: $VNC_LOG_FILE"
    tail -f "$VNC_LOG_FILE"
else
    echo "No VNC log file found, keeping container alive with sleep"
    while true; do
        sleep 30
        # Check if VNC server is still running
        if ! pgrep -f "Xtigervnc.*:0" > /dev/null; then
            echo "VNC server has stopped, exiting..."
            exit 1
        fi
    done
fi
