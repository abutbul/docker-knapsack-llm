FROM debian:bullseye-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99

# Install minimal dependencies
RUN apt-get update && \
    (apt-get install -y --no-install-recommends \
    lxde-core \
    lxsession \
    lxde-common \
    openbox \
    xterm \
    tigervnc-standalone-server \
    x11-xserver-utils \
    x11-utils \
    dbus-x11 \
    dbus \
    wine \
    python3 \
    python3-pip \
    python3-tk \
    python3-dev \
    procps \
    || apt-get install -y --fix-missing --no-install-recommends \
    lxde-core \
    lxsession \
    lxde-common \
    openbox \
    xterm \
    tigervnc-standalone-server \
    x11-xserver-utils \
    x11-utils \
    dbus-x11 \
    dbus \
    wine \
    python3 \
    python3-pip \
    python3-tk \
    python3-dev \
    procps) \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Python libraries
RUN pip3 install flask pyautogui pydirectinput

# Copy API script and entrypoint
COPY api.py /opt/api.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose API and VNC ports
EXPOSE 5000 5900

# Entrypoint script handles startup
ENTRYPOINT ["/entrypoint.sh"]

