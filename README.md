# WoW WotLK Docker Player

A containerized World of Warcraft: Wrath of the Lich King client environment with Lutris, Wine, and automation API support. This project enables running single or multiple WoW instances in isolated Docker containers with shared client files and individual configurations.

## 🎮 Key Features

- **Shared Client Files**: Single copy of WoW client shared across all instances using overlay filesystem
- **Individual Configs**: Each instance has isolated settings, saves, and add-ons
- **Wine Pre-configured**: Automated Wine setup with Mono/Gecko to avoid installation prompts
- **Lutris Integration**: Pre-configured Lutris environment optimized for WoW WotLK
- **VNC Access**: Full desktop environment accessible via VNC for each instance
- **Automation API**: REST API for sending keystrokes and mouse actions to instances
- **Multi-Instance Support**: Run up to 5 concurrent WoW instances efficiently

## 📋 Prerequisites

- Docker and Docker Compose installed
- Your own licensed WoW: Wrath of the Lich King client files
- VNC client for desktop access (optional: TigerVNC, RealVNC, or browser-based)

> **Note**: This repository does not include any game client files. You must provide your own licensed copy of World of Warcraft: Wrath of the Lich King. Tested with ChromieCraft client.

## 🔧 Container Architecture

### Entrypoint Flow
The container startup follows this sequence:

1. **Environment Setup**: Initialize LXDE desktop environment and D-Bus
2. **Overlay Filesystem**: Create shared read-only client files with writable overlays
3. **Wine Initialization**: Bootstrap Wine with Mono/Gecko to avoid interactive prompts
4. **VNC Server**: Start TigerVNC server for desktop access
5. **API Server**: Launch Flask API for automation
6. **Lutris Ready**: Desktop with WoW shortcut available

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
   ./manage-clients.sh setup 1
   ./manage-clients.sh start 1
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
   ./manage-clients.sh setup 5  # Prepare for up to 5 instances
   # Copy your WoW client to ./wow-client/ (shared by all instances)
   ```

2. **Start multiple instances**:
   ```bash
   ./manage-clients.sh start 3  # Start 3 instances
   ```

3. **Access instances**:
   ```
   Instance 1: VNC localhost:5900, API localhost:5000
   Instance 2: VNC localhost:5901, API localhost:5001  
   Instance 3: VNC localhost:5902, API localhost:5002
   ```

#### Management Commands:

**Status Monitoring**:
```bash
./manage-clients.sh status
# Shows running state, ports, and resource usage for all instances
```

**Scaling Operations**:
```bash
./manage-clients.sh start 1     # Single instance
./manage-clients.sh start 5     # Maximum instances
./manage-clients.sh stop        # Stop all instances
```

**Advanced Docker Compose**:
```bash
# Manual control for specific instances
docker-compose up -d wow-client-1 wow-client-3
docker-compose --profile multi up -d  # All instances
docker-compose logs wow-client-2       # Logs for specific instance
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
- `manage-clients.sh`: Instance management and control script

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

Each instance runs an independent API server for automation:

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

### API Usage Examples:
```bash
# Control instance 1
curl -X POST http://localhost:5000/send-key -H "Content-Type: application/json" -d '{"key": "w"}'

# Control instance 2  
curl -X POST http://localhost:5001/send-key -H "Content-Type: application/json" -d '{"key": "s"}'

# Move mouse in instance 3
curl -X POST http://localhost:5002/move-mouse -H "Content-Type: application/json" -d '{"x": 500, "y": 300}'
```

## 🧪 Testing and Validation

Test your setup with the provided scripts:

```bash
# Test API connectivity
python3 test_api.py

# Test VNC connectivity  
python3 test_vnc.py
```

## 📊 Resource Usage

### Storage Efficiency:
- **Traditional Setup**: 17GB × 5 instances = 85GB
- **This Setup**: 17GB + (264KB × 5 instances) = ~17GB total
- **Space Savings**: ~68GB (80% reduction)

### Memory Usage:
- Base container: ~200MB
- Per WoW instance: ~1-2GB (depending on game settings)
- Total for 5 instances: ~5-10GB

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
   ./manage-clients.sh status
   
   # View container logs
   docker logs wow-client-1
   ```

4. **Port Conflicts**:
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
├── api.py                 # Flask API server
├── manage-clients.sh      # Instance management script
├── test_api.py           # API testing script
├── test_vnc.py           # VNC connectivity test
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

### Scaling Beyond 5 Instances:
Modify `docker-compose.yml` and `manage-clients.sh` to support more instances if needed.

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