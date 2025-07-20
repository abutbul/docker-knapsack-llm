FROM debian:bullseye-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:0

# Install minimal dependencies
RUN dpkg --add-architecture i386
RUN apt-get update && \
    (apt-get install -y \
    lxde-core \
    lxsession \
    lxde-common \
    wine32 \
    libglu1-mesa:i386 \
    libgl1-mesa-glx:i386 \
    libgl1-mesa-dri \
    mesa-utils:i386 \
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
    wget \
    gnupg \
    software-properties-common \
    curl)

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Lutris and required dependencies
RUN wget -O - https://download.opensuse.org/repositories/home:/strycore/Debian_11/Release.key | apt-key add - && \
    echo "deb http://download.opensuse.org/repositories/home:/strycore/Debian_11/ ./" > /etc/apt/sources.list.d/lutris.list && \
    apt-get update && \
    apt-get install -y lutris && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Wine versions required for Lutris
RUN wget -nc https://dl.winehq.org/wine-builds/winehq.key && \
    apt-key add winehq.key && \
    echo "deb https://dl.winehq.org/wine-builds/debian/ bullseye main" > /etc/apt/sources.list.d/winehq.list && \
    apt-get update && \
    apt-get install -y --install-recommends winehq-staging && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

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

