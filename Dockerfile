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
    curl \
    imagemagick \
    bc \
    x11-apps)

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

# Install Wine Mono and Gecko to avoid interactive prompts
RUN mkdir -p /tmp/wine-setup && \
    cd /tmp/wine-setup && \
    wget https://dl.winehq.org/wine/wine-mono/7.4.0/wine-mono-7.4.0-x86.msi && \
    wget https://dl.winehq.org/wine/wine-gecko/2.47.3/wine-gecko-2.47.3-x86.msi && \
    wget https://dl.winehq.org/wine/wine-gecko/2.47.3/wine-gecko-2.47.3-x86_64.msi && \
    mkdir -p /usr/share/wine/mono && \
    mkdir -p /usr/share/wine/gecko && \
    cp wine-mono-7.4.0-x86.msi /usr/share/wine/mono/ && \
    cp wine-gecko-2.47.3-x86.msi /usr/share/wine/gecko/ && \
    cp wine-gecko-2.47.3-x86_64.msi /usr/share/wine/gecko/ && \
    rm -rf /tmp/wine-setup

# Install Python libraries and additional filesystem tools
RUN pip3 install flask pyautogui pydirectinput

# Set up directory for Lutris configuration
RUN mkdir -p /root/.config/lutris/games

# Copy Lutris configuration for WoW WotLK
COPY wow-wotlk.yml /root/.config/lutris/games/wow-wotlk.yml


# Copy overlay setup script and wine initialization
COPY setup-overlay.sh /opt/setup-overlay.sh
COPY init-wine.sh /opt/init-wine.sh
COPY health_check.sh /opt/health_check.sh
COPY snapshot-service.sh /opt/snapshot-service.sh
RUN chmod +x /opt/setup-overlay.sh /opt/init-wine.sh /opt/health_check.sh /opt/snapshot-service.sh

# Copy API script and entrypoint
COPY api.py /opt/api.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose API and VNC ports
EXPOSE 5000 5900

# Create a volume mount point
VOLUME /root/Desktop/Client

# Entrypoint script handles startup
ENTRYPOINT ["/entrypoint.sh"]

