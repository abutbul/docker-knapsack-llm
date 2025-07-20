# WoW Docker Client - Dynamic Orchestration

This project provides multiple approaches for dynamically orchestrating World of Warcraft client containers without hardcoded limits or services.

## 🚀 Quick Start (Recommended Approach)

Use the **Dynamic Docker Management** approach for the best balance of simplicity and scalability:

```bash
# Set up shared client directory
./manage-clients-dynamic.sh setup

# Copy your WoW client files to ./wow-client/

# Start 10 instances
./manage-clients-dynamic.sh start 10

# Scale to 20 instances
./manage-clients-dynamic.sh scale 20

# Check status
./manage-clients-dynamic.sh status

# Stop all instances
./manage-clients-dynamic.sh stop
```

## 📋 Available Approaches

### 1. Dynamic Docker Management (Recommended)
**File:** `manage-clients-dynamic.sh`

**Pros:**
- ✅ No hardcoded limits
- ✅ True dynamic scaling
- ✅ Individual container control
- ✅ Persistent volumes per instance
- ✅ Simple to understand and modify
- ✅ Production-ready

**Cons:**
- ⚠️ Manual port management
- ⚠️ No built-in service discovery

**Use case:** Most production deployments, development, testing

```bash
# Environment variables
export MAX_INSTANCES=100  # Override default limit
export VNC_PASSWD=mypassword
export VNC_GEOMETRY=1920x1080

# Commands
./manage-clients-dynamic.sh setup
./manage-clients-dynamic.sh start 15
./manage-clients-dynamic.sh scale 25
./manage-clients-dynamic.sh status
./manage-clients-dynamic.sh stop
./manage-clients-dynamic.sh clean
```

### 2. Docker Swarm Mode (Enterprise)
**File:** `manage-clients-swarm.sh`

**Pros:**
- ✅ True container orchestration
- ✅ Automatic load balancing
- ✅ Service discovery
- ✅ Health checks and auto-restart
- ✅ Rolling updates
- ✅ Multi-node support
- ✅ Production-grade scaling

**Cons:**
- ⚠️ More complex setup
- ⚠️ Requires Swarm mode
- ⚠️ Different volume management

**Use case:** Large-scale production deployments, multi-node clusters

```bash
# Initialize swarm (one-time)
./manage-clients-swarm.sh init

# Deploy with 20 instances
./manage-clients-swarm.sh deploy 20

# Scale to 50 instances
./manage-clients-swarm.sh scale 50

# Check status
./manage-clients-swarm.sh status

# Stop all
./manage-clients-swarm.sh stop
```

### 3. Generated Docker Compose (Hybrid)
**Files:** `generate-compose.sh`, updated `manage-clients.sh`

**Pros:**
- ✅ Familiar docker-compose workflow
- ✅ No hardcoded limits
- ✅ Full docker-compose features
- ✅ Easy to customize

**Cons:**
- ⚠️ Generates large compose files
- ⚠️ Less efficient than direct Docker

**Use case:** Teams familiar with docker-compose, customization needs

```bash
# Generate compose file for 30 instances
./generate-compose.sh 30 docker-compose.yml

# Use with standard docker-compose
docker-compose up -d

# Or use the updated management script
./manage-clients.sh setup
./manage-clients.sh start 30
```

## 🔧 Configuration

### Environment Variables

All approaches support these environment variables:

```bash
# Maximum instances (Dynamic approach only)
export MAX_INSTANCES=100

# VNC Configuration
export VNC_PASSWD=password
export VNC_GEOMETRY=1280x800
export VNC_DEPTH=24

# Snapshot service
export SNAPSHOT_INTERVAL_MS=500
```

### Port Allocation

**Dynamic Docker Management:**
- Instance N: VNC=`5900+(N-1)`, API=`5000+(N-1)`
- Instance 1: VNC=5900, API=5000
- Instance 10: VNC=5909, API=5009
- Instance 50: VNC=5949, API=5049

**Docker Swarm:**
- Automatic port allocation within ranges
- VNC: 5900-5950
- API: 5000-5050

## 📁 Directory Structure

```
wow-client/              # Shared read-only client files
├── Wow.exe
├── Data/
├── Interface/
└── ...

# Generated volumes (per instance):
wow-clients-client-N-data/    # Writable game data
wow-clients-client-N-lutris/  # Lutris configuration
wow-clients-client-N-wine/    # Wine environment
```

## 🚦 Migration from Old System

To migrate from the hardcoded docker-compose.yml:

1. **Backup existing data:**
   ```bash
   # Stop current instances
   docker-compose --profile multi down
   
   # Backup volumes if needed
   docker run --rm -v wow-client-1-data:/data -v $(pwd):/backup alpine \
     tar czf /backup/wow-client-1-backup.tar.gz -C /data .
   ```

2. **Switch to dynamic approach:**
   ```bash
   # Use the new dynamic script
   ./manage-clients-dynamic.sh start 5
   ```

3. **Clean up old resources (optional):**
   ```bash
   # Remove old compose-defined volumes/networks
   docker-compose --profile multi down -v
   ```

## 🔍 Monitoring and Debugging

### Check Resource Usage
```bash
# All running containers
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# Filter WoW containers only
docker stats $(docker ps --filter "name=wow-clients-client" --format "{{.Names}}")
```

### View Logs
```bash
# Dynamic approach
docker logs wow-clients-client-1

# Swarm approach
docker service logs wow-clients_wow-client
```

### Health Checks
```bash
# Check API endpoints
for i in {1..5}; do
  curl -s "http://localhost:$((4999+i))/snapshot-info" | jq '.service_healthy'
done
```

## 🛠️ Troubleshooting

### Common Issues

1. **Port conflicts:**
   ```bash
   # Check what's using ports
   netstat -tulpn | grep :5900
   
   # Use different base ports
   export BASE_VNC_PORT=6900
   export BASE_API_PORT=6000
   ```

2. **Volume issues:**
   ```bash
   # Clean up unused volumes
   docker volume prune
   
   # List volumes
   docker volume ls | grep wow-client
   ```

3. **Performance issues:**
   ```bash
   # Limit resources per container
   docker run --memory=2g --cpus=1.5 ...
   ```

### Recovery

If containers get stuck:
```bash
# Force remove all instances
docker ps -a --filter "name=wow-clients-client" -q | xargs docker rm -f

# Clean up networks
docker network prune
```

## 🔮 Future Enhancements

- **Kubernetes support** with Helm charts
- **Load balancer integration** (nginx/traefik)
- **Monitoring stack** (Prometheus/Grafana)
- **Auto-scaling** based on metrics
- **Multi-node cluster** support
- **Backup/restore** automation

## 📖 Best Practices

1. **Use the Dynamic Docker approach** for most use cases
2. **Set resource limits** to prevent resource exhaustion
3. **Monitor disk usage** - each instance uses ~500MB-2GB
4. **Use SSD storage** for better performance
5. **Regular cleanup** of unused volumes and images
6. **Backup critical data** before scaling operations

## 🤝 Contributing

To add new orchestration approaches:

1. Create new management script: `manage-clients-{approach}.sh`
2. Follow existing patterns for argument handling
3. Add documentation to this README
4. Test with multiple instance counts
5. Ensure proper cleanup functionality
