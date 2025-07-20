# WoW WotLK Docker Player

A containerized World of Warcraft: Wrath of the Lich King client environment with Lutris, Wine, and automation API support. This project enables running single or multiple WoW instances in isolated Docker containers with shared client files and individual configurations.

## 📋 Table of Contents

- [🚀 Quick Start](#-quick-start)
- [📚 Documentation](#-documentation)
- [🎮 Key Features](#-key-features)
- [📋 Prerequisites](#-prerequisites)
- [🎯 Usage Methods](#-usage-methods)
- [🌐 API Endpoints](#-api-endpoints)
- [📊 Resource Usage](#-resource-usage)
- [🔧 Troubleshooting](#-troubleshooting)
- [🚀 Advanced Usage](#-advanced-usage)

## 📚 Documentation

- **[Volume Cleanup Guide](VOLUME-CLEANUP-GUIDE.md)** - Comprehensive guide for managing container volumes and data cleanup
- **[Dynamic Orchestration Guide](README-dynamic.md)** - Advanced scaling and orchestration methods for large deployments
- **[Development Notes](initprompt.md)** - Initial design considerations and requirements

### Management Scripts Available:
- `manage-clients-dynamic.sh` - **Recommended**: Direct Docker container management with unlimited scaling
- `manage-clients.sh` - Docker Compose based management (legacy)
- `manage-clients-swarm.sh` - Docker Swarm orchestration for enterprise deployments

## 🚀 Quick Start

```bash
# 1. Setup shared client directory
./manage-clients-dynamic.sh setup

# 2. Copy your licensed WoW client files to ./wow-client/
cp -r /path/to/your/wow/client/* ./wow-client/

# 3. Start 3 instances
./manage-clients-dynamic.sh start 3

# 4. Connect via VNC: localhost:5900, localhost:5901, localhost:5902
# 5. Access APIs: localhost:5000, localhost:5001, localhost:5002
```

**Need help with volumes or cleanup?** → [Volume Cleanup Guide](VOLUME-CLEANUP-GUIDE.md)  
**Want advanced scaling?** → [Dynamic Orchestration Guide](README-dynamic.md)

## 🎮 Key Features

- **Shared Client Files**: Single copy of WoW client shared across all instances using overlay filesystem
- **Individual Configs**: Each instance has isolated settings, saves, and add-ons
- **Wine Pre-configured**: Automated Wine setup with Mono/Gecko to avoid installation prompts
- **Lutris Integration**: Pre-configured Lutris environment optimized for WoW WotLK
- **VNC Access**: Full desktop environment accessible via VNC for each instance
- **Automation API**: REST API for sending keystrokes and mouse actions to instances
- **Multi-Instance Support**: Run unlimited concurrent WoW instances efficiently (default limit: 50, configurable)

## 📋 Prerequisites

- Docker and Docker Compose installed
- Your own licensed WoW: Wrath of the Lich King client files
- VNC client for desktop access (optional: TigerVNC, RealVNC, or browser-based)

> **Note**: This repository does not include any game client files. You must provide your own licensed copy of World of Warcraft: Wrath of the Lich King. Tested with ChromieCraft client.

## 🔧 Container Architecture

### Service Separation Design
The system is designed with clear separation of concerns:

- **Desktop Snapshot Service** (`snapshot-service.sh`): Runs independently, continuously captures screenshots
- **Flask API Server** (`api.py`): Serves files and metadata, handles automation endpoints  
- **Container Orchestration** (`entrypoint.sh`): Manages service startup and dependencies

### Entrypoint Flow
The container startup follows this sequence:

1. **Environment Setup**: Initialize LXDE desktop environment and D-Bus
2. **Overlay Filesystem**: Create shared read-only client files with writable overlays
3. **Wine Initialization**: Bootstrap Wine with Mono/Gecko to avoid interactive prompts
4. **Snapshot Service**: Start background desktop capture service
5. **VNC Server**: Start TigerVNC server for desktop access
6. **API Server**: Launch Flask API for automation
7. **Lutris Ready**: Desktop with WoW shortcut available

### File Sharing Architecture
```
Host Machine:
└── ./wow-client/              # Single shared client (read-only)
    ├── Wow.exe
    ├── Data/
    ├── Interface/
    └── ...

Container Instances:
├── Instance 1: /root/Desktop/Client/
├── Instance 2: /root/Desktop/Client/     
└── Instance 3: /root/Desktop/Client/     
    ├── Wow.exe → symlink to shared
    ├── Data/ → symlink to shared
    ├── WTF/ → individual copy (writable)
    ├── Logs/ → individual copy (writable)
    └── Interface/AddOns/ → individual copy (writable)
```

## 🎯 Usage Methods

> **Recommendation**: Use the **Dynamic Management** approach (`manage-clients-dynamic.sh`) for all deployments unless you specifically need Docker Compose workflows. See [Dynamic Orchestration Guide](README-dynamic.md) for comparison of all available methods.

### Method 1: Single Player Setup

Perfect for individual players who want to run WoW in a containerized environment.

#### Setup Steps:

1. **Clone and prepare**:
   ```bash
   git clone <this-repo>
   cd docker-player
   ```

2. **Add your WoW client**:
   ```bash
   mkdir wow-client
   # Copy your licensed WoW client files to ./wow-client/
   # Ensure Wow.exe is in ./wow-client/Wow.exe
   ```

3. **Start single instance**:
   ```bash
   ./manage-clients-dynamic.sh setup
   ./manage-clients-dynamic.sh start 1
   ```

4. **Connect via VNC**:
   - Address: `localhost:5900`
   - Password: `password`
   - Double-click the WoW desktop icon to launch

5. **API Access** (optional):
   ```bash
   curl -X POST http://localhost:5000/send-key -H "Content-Type: application/json" -d '{"key": "w"}'
   ```

#### Single Player Benefits:
- Isolated gaming environment
- No impact on host system
- Easy backup/restore of game state
- Automation capabilities via API

---

### Method 2: Multi-Instance Deployment

Ideal for larger deployments, multiple accounts, or testing scenarios.

#### Architecture Benefits:
- **Storage Efficient**: One 17GB client serves unlimited instances (~264KB per instance)
- **Isolated Environments**: Each instance has separate configs, saves, add-ons
- **Scalable**: Easy horizontal scaling across multiple containers
- **Centralized Management**: Single command controls all instances

#### Setup Steps:

1. **Prepare shared client**:
   ```bash
   ./manage-clients-dynamic.sh setup
   # Copy your WoW client to ./wow-client/ (shared by all instances)
   ```

2. **Start multiple instances**:
   ```bash
   ./manage-clients-dynamic.sh start 10  # Start 10 instances
   ```

3. **Access instances**:
   ```
   Instance 1: VNC localhost:5900, API localhost:5000
   Instance 2: VNC localhost:5901, API localhost:5001  
   Instance 10: VNC localhost:5909, API localhost:5009
   ```

#### Management Commands:

**Status Monitoring**:
```bash
./manage-clients-dynamic.sh status
# Shows running state, ports, and resource usage for all instances
```

**Scaling Operations**:
```bash
./manage-clients-dynamic.sh start 10    # Start 10 instances
./manage-clients-dynamic.sh scale 25    # Scale to exactly 25 instances
./manage-clients-dynamic.sh stop        # Stop all instances
```

**Volume Management** (see [Volume Cleanup Guide](VOLUME-CLEANUP-GUIDE.md)):
```bash
./manage-clients-dynamic.sh clean-volumes 5    # Clean specific instance
./manage-clients-dynamic.sh clean-stopped      # Clean stopped containers
./manage-clients-dynamic.sh clean-all          # Nuclear option (with confirmation)
```

**Configuration**:
```bash
# Override default limits
export MAX_INSTANCES=100
./manage-clients-dynamic.sh start 50
```

#### Multi-Instance Benefits:
- **Cost Effective**: Share single client installation
- **Easy Deployment**: Consistent environment across instances  
- **Individual Isolation**: Separate game saves, configs, add-ons
- **Centralized Updates**: Update client once, affects all instances
- **Automation Friendly**: API access to each instance independently

## 🔧 Configuration Files

### Core Components:
- `Dockerfile`: Container definition with Wine, Lutris, and dependencies
- `docker-compose.yml`: Multi-instance orchestration with volume management
- `entrypoint.sh`: Startup sequence and environment initialization
- `setup-overlay.sh`: Overlay filesystem creation for shared client files
- `init-wine.sh`: Wine environment bootstrap with Mono/Gecko
- `wow-wotlk.yml`: Lutris configuration optimized for WoW WotLK
- `snapshot-service.sh`: Independent desktop screenshot service
- `manage-clients-dynamic.sh`: Primary instance management and control script (recommended)
- `manage-clients.sh`: Alternative docker-compose based management script

### Environment Variables

Configure snapshot service behavior:

- `SNAPSHOT_PATH`: Location for screenshot file (default: `/tmp/desktop_snapshot.png`)
- `SNAPSHOT_INTERVAL_MS`: Capture frequency in milliseconds (default: `500`)
- `DISPLAY`: X11 display to capture (default: `:0`)

Standard container settings:
- `VNC_PASSWD`: VNC access password
- `VNC_GEOMETRY`: Desktop resolution (e.g., `1280x800`)
- `VNC_DEPTH`: Color depth (16 or 24)
- `INSTANCE_ID`: Container identifier for logging

## 🌐 API Endpoints

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

## 🌐 API Endpoints

Each instance runs an independent API server for automation and monitoring:

### 1. Send Key Press

**Endpoint**: `/send-key`  
**Method**: `POST`  
**Payload**:
```json
{
  "key": "w"
}
```
**Description**: Sends a key press to the game (e.g., `w`, `space`, `1`, `ctrl+1`).

### 2. Move Mouse

**Endpoint**: `/move-mouse`  
**Method**: `POST`  
**Payload**:
```json
{
  "x": 100,
  "y": 200
}
```
**Description**: Moves the mouse to specified coordinates within the game window.

### 3. Desktop Snapshot

**Endpoint**: `/desktop-snapshot`  
**Method**: `GET`  
**Response**: PNG image file with metadata headers  
**Description**: Returns the latest desktop screenshot with metadata in HTTP headers.

**Response Headers**:
- `X-Snapshot-Size`: File size in bytes
- `X-Snapshot-Age-Seconds`: Age of snapshot in seconds
- `X-Snapshot-Created-Time`: Human-readable creation time
- `X-Snapshot-Interval-Ms`: Configured capture interval
- `X-Snapshot-Is-Fresh`: Whether snapshot is considered fresh

### 4. Snapshot Service Health Check

**Endpoint**: `/snapshot-info`  
**Method**: `GET`  
**Response**:
```json
{
  "service_healthy": true,
  "snapshot_available": true,
  "file_size_bytes": 1234567,
  "age_seconds": 0.3,
  "configured_interval_ms": 500,
  "file_was_updated_during_check": true,
  "is_fresh": true,
  "snapshot_path": "/tmp/desktop_snapshot.png",
  "check_details": {
    "initial_age_seconds": 0.8,
    "waited_seconds": 0.6,
    "final_age_seconds": 0.3
  }
}
```
**Description**: Validates that the snapshot service is actively generating fresh images. This endpoint waits for a new image to be generated to confirm service health.

### API Usage Examples:
```bash
# Control instance 1
curl -X POST http://localhost:5000/send-key -H "Content-Type: application/json" -d '{"key": "w"}'

# Get desktop screenshot from instance 2 (check headers for metadata)
curl -i http://localhost:5001/desktop-snapshot -o instance2_screenshot.png

# Check snapshot service health for instance 3  
curl http://localhost:5002/snapshot-info

# Move mouse in instance 1
curl -X POST http://localhost:5000/move-mouse -H "Content-Type: application/json" -d '{"x": 500, "y": 300}'
```

### Desktop Snapshot Features:
- **Independent Service**: Snapshot capture runs separately from API server
- **Configurable Frequency**: Environment variable `SNAPSHOT_INTERVAL_MS` (default: 500ms)
- **Metadata Rich**: Image served with comprehensive metadata in HTTP headers
- **Health Monitoring**: Service health endpoint validates active image generation
- **Atomic Updates**: Screenshots written atomically to prevent corruption
- **Low Performance Impact**: Uses optimized `xwd` + ImageMagick for fast capture
- **Always Fresh**: API serves latest image without caching
- **Per-Instance**: Each container has independent screenshot service

## 🧪 Testing and Validation

Test your setup with the provided scripts:

```bash
# Test API connectivity and screenshot service
python3 test_api.py

# Test VNC connectivity  
python3 test_vnc.py

# Check desktop snapshot service health
./health_check.sh
```

The test script will:
- ✓ Test key press and mouse movement APIs
- ✓ Verify desktop snapshot service is running  
- ✓ Download a test screenshot to verify image capture
- ✓ Test multiple instances if available

## 📊 Resource Usage

### Storage Efficiency:
- **Traditional Setup**: 17GB × 50 instances = 850GB
- **This Setup**: 17GB + (264KB × 50 instances) = ~17GB total
- **Space Savings**: ~833GB (98% reduction for large deployments)

### Memory Usage:
- Base container: ~200MB
- Per WoW instance: ~1-2GB (depending on game settings)
- Total for 10 instances: ~10-20GB
- Total for 50 instances: ~50-100GB

### Scalability:
- **Default Limit**: 50 instances (configurable with `MAX_INSTANCES`)
- **Port Range**: VNC 5900-5949, API 5000-5049 (for 50 instances)
- **Recommended**: Use SSD storage for optimal performance

## 🔧 Troubleshooting

### Common Issues:

1. **Wine Mono Installation Prompts**:
   - Fixed automatically by `init-wine.sh` during container startup
   - No user interaction required

2. **Client Files Not Found**:
   ```bash
   # Verify client structure
   ls -la wow-client/
   # Should contain Wow.exe, Data/, Interface/, etc.
   ```

3. **VNC Connection Issues**:
   ```bash
   # Check container status
   ./manage-clients-dynamic.sh status
   
   # View container logs
   docker logs wow-clients-client-1
   ```

4. **Desktop Snapshot Issues**:
   ```bash
   # Check snapshot service health
   docker exec wow-clients-client-1 /opt/health_check.sh
   
   # Manual screenshot test
   curl http://localhost:5000/snapshot-info
   curl http://localhost:5000/desktop-snapshot -o test.png
   ```

5. **Port Conflicts**:
   - Ensure ports 5900-5904 and 5000-5004 are available
   - Modify `docker-compose.yml` to use different ports if needed

## 📁 File Structure

```
docker-player/
├── Dockerfile              # Container definition with Wine/Lutris setup
├── docker-compose.yml      # Multi-instance orchestration
├── entrypoint.sh           # Container startup flow  
├── setup-overlay.sh        # Overlay filesystem creation
├── init-wine.sh           # Wine environment bootstrap
├── wow-wotlk.yml          # Lutris configuration for WoW
├── api.py                 # Flask API server with screenshot service
├── manage-clients-dynamic.sh # Primary instance management (recommended)
├── manage-clients.sh      # Alternative docker-compose management script
├── test_api.py           # API testing script
├── test_vnc.py           # VNC connectivity test
├── health_check.sh       # Desktop snapshot service monitor
├── wow-client/           # Your WoW client files (shared, read-only)
│   ├── Wow.exe
│   ├── Data/
│   ├── Interface/
│   └── ...
└── .gitignore           # Excludes wow-client/ from git
```

## 🚀 Advanced Usage

### Custom Wine Configuration:
Modify `init-wine.sh` to add custom Wine settings or install additional Windows components.

### Lutris Customization:
Edit `wow-wotlk.yml` to adjust game-specific settings like graphics, audio, or performance options.

### Scaling Beyond Default Limits:
See the [Dynamic Orchestration Guide](README-dynamic.md) for advanced scaling methods and configuration options. The dynamic script supports scaling to hundreds of instances with proper resource allocation.

### Integration with Orchestration:
This setup can be integrated with Kubernetes or Docker Swarm for larger deployments.

## 📜 License and Legal

This repository provides infrastructure only. Users must:
- Provide their own licensed World of Warcraft client
- Comply with Blizzard Entertainment's Terms of Service
- Use only for personal, non-commercial purposes

**Tested Client**: ChromieCraft (3.3.5a) - community server with custom client
**Compatibility**: Should work with any WoW 3.3.5a (WotLK) client

---

## 🤝 Contributing

Contributions welcome! Areas for improvement:
- Additional Wine/Lutris optimizations
- Support for other WoW expansions  
- Enhanced monitoring and logging
- Performance optimizations

## 📞 Support

For issues:
1. Check the troubleshooting section above
2. Review container logs: `docker logs wow-client-X`
3. Verify client file structure and permissions
4. Test with single instance before multi-instance deployment