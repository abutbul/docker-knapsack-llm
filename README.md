# WoW WotLK Docker Player

This project sets up Docker containers with LXDE environment, Wine, Lutris, and an API to run multiple instances of World of Warcraft: Wrath of the Lich King with automation capabilities.

## Prerequisites

- Docker installed on your system.

## Build the Docker Image

Run the following command to build the Docker image:

```bash
docker build -t lxde-wine-api .
```

## Run the Docker Container

Start the container with the following command:

```bash
docker run -d --name lxde-wine-container -p 5000:5000 lxde-wine-api
```

- The API will be accessible at `http://localhost:5000`.

## API Endpoints

### 1. Send a Key Press

**Endpoint**: `/send-key`  
**Method**: `POST`  
**Payload**:
```json
{
  "key": "w"
}
```

**Description**: Sends a key press (e.g., `w`, `space`, `1`).

---

### 2. Move the Mouse

**Endpoint**: `/move-mouse`  
**Method**: `POST`  
**Payload**:
```json
{
  "x": 100,
  "y": 200
}
```

**Description**: Moves the mouse to the specified coordinates.

---

## Testing the Setup

Run the provided testing script to verify the container is working as expected:

```bash
python3 test_api.py
```

## Stopping the Container

To stop and remove the container:

```bash
docker stop lxde-wine-container
docker rm lxde-wine-container
```


## Multi-Instance WoW WotLK Setup

This Docker setup now supports running multiple instances of World of Warcraft: Wrath of the Lich King using Lutris.

### Quick Start for WoW

#### 1. Setup Directories
First, create directories for your WoW client instances:
```bash
./manage-clients.sh setup 3  # Creates 3 instance directories
```

#### 2. Start Instances
```bash
./manage-clients.sh start 3  # Starts 3 instances
```

#### 3. Connect via VNC
Each instance will be available on different ports:
- Instance 1: VNC on `localhost:5900`, API on `localhost:5000`
- Instance 2: VNC on `localhost:5901`, API on `localhost:5001`
- Instance 3: VNC on `localhost:5902`, API on `localhost:5002`
- etc.

### Management Commands

#### Start Instances
```bash
./manage-clients.sh start 1    # Start 1 instance
./manage-clients.sh start 3    # Start 3 instances
./manage-clients.sh start 5    # Start 5 instances (maximum)
```

#### Stop All Instances
```bash
./manage-clients.sh stop
```

#### Check Status
```bash
./manage-clients.sh status
```

### Manual Docker Compose Usage

If you prefer to use Docker Compose directly:

#### Start single instance:
```bash
docker-compose up -d wow-client-1
```

#### Start multiple instances:
```bash
docker-compose --profile multi up -d wow-client-1 wow-client-2 wow-client-3
```

#### Stop all:
```bash
docker-compose --profile multi down
```

### WoW-Specific Features

- **Lutris Integration**: Pre-configured Lutris environment for WoW WotLK
- **OpenGL Support**: Optimized for OpenGL rendering
- **Desktop Shortcut**: Each instance has a WoW desktop icon
- **Wine Configuration**: Properly configured Wine environment
- **Multiple Clients**: Run up to 5 WoW clients simultaneously
- **Isolated Storage**: Each instance has its own WoW client directory

### File Structure for WoW Setup

```
docker-player/
├── Dockerfile              # Main container definition
├── docker-compose.yml      # Multi-instance orchestration
├── entrypoint.sh           # Container startup script
├── wow-wotlk.yml          # Lutris configuration for WoW
├── api.py                 # API server
├── manage-clients.sh      # Instance management script
├── wow-client/          # shared WoW client files
└── ...
```