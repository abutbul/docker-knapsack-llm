# Volume Cleanup Guide

All manage-clients scripts now include sophisticated volume cleanup features that are **optional** and **separate** from the basic stop functionality.

## Cleanup Commands Available

### 1. `clean-volumes [N]` - Selective Volume Cleanup
- **Purpose**: Clean volumes for specific instances or all instances
- **Safety**: Always asks for confirmation before removing all volumes
- **Usage**:
  ```bash
  # Clean volumes for instance 3 only
  ./manage-clients.sh clean-volumes 3
  ./manage-clients-dynamic.sh clean-volumes 3
  
  # Clean ALL volumes (with confirmation prompt)
  ./manage-clients.sh clean-volumes
  ./manage-clients-dynamic.sh clean-volumes
  ```
- **What it does**:
  - For specific instance: Removes data, lutris, and wine volumes for that instance
  - For all instances: Stops all containers and removes all volumes
  - Always checks if containers are running first (prevents data loss)

### 2. `clean-stopped` - Clean Only Stopped Containers
- **Purpose**: Clean volumes only for containers that are stopped or don't exist
- **Safety**: Never touches running containers
- **Usage**:
  ```bash
  ./manage-clients.sh clean-stopped
  ./manage-clients-dynamic.sh clean-stopped
  ./manage-clients-swarm.sh clean-stopped
  ```
- **What it does**:
  - Identifies stopped containers automatically
  - Removes containers and their associated volumes
  - Leaves running containers untouched

### 3. `clean-all` - Nuclear Option
- **Purpose**: Complete cleanup of everything related to WoW clients
- **Safety**: Always asks for confirmation (destructive operation)
- **Usage**:
  ```bash
  ./manage-clients.sh clean-all
  ./manage-clients-dynamic.sh clean-all
  ./manage-clients-swarm.sh clean-all
  ```
- **What it does**:
  - Stops all containers
  - Removes all containers
  - Removes all volumes
  - Removes networks
  - Runs `docker system prune -f`

## Volume Naming Patterns

### Standard Version (`manage-clients.sh`)
```
{project-dir}_wow-client-{N}-data
{project-dir}_wow-client-{N}-lutris  
{project-dir}_wow-client-{N}-wine
```

### Dynamic Version (`manage-clients-dynamic.sh`)
```
wow-clients-client-{N}-data
wow-clients-client-{N}-lutris
wow-clients-client-{N}-wine
```

### Swarm Version (`manage-clients-swarm.sh`)
- Uses Docker Swarm managed volumes
- Automatic container lifecycle management
- Cleanup focuses on unused Docker resources

## Safety Features

1. **Running Container Protection**: Scripts check if containers are running before cleaning volumes
2. **Confirmation Prompts**: Destructive operations always ask for user confirmation
3. **Granular Control**: You can clean specific instances without affecting others
4. **Separate from Stop**: Volume cleanup is completely optional and separate from stopping containers

## Examples

### Clean up after testing
```bash
# Stop all instances
./manage-clients-dynamic.sh stop

# Clean volumes for stopped containers only
./manage-clients-dynamic.sh clean-stopped
```

### Clean specific instance that's having issues
```bash
# Stop and clean instance 5 specifically
./manage-clients-dynamic.sh scale 4  # This stops instance 5
./manage-clients-dynamic.sh clean-volumes 5
./manage-clients-dynamic.sh scale 5  # Restart with fresh volumes
```

### Complete reset (nuclear option)
```bash
# WARNING: This removes everything!
./manage-clients-dynamic.sh clean-all
```

### Clean only unused volumes (safest)
```bash
# This only removes volumes not attached to any container
./manage-clients-swarm.sh clean-volumes
```

## Best Practices

1. **Use `clean-stopped` regularly**: This is the safest way to clean up after testing
2. **Backup important data**: Before using `clean-all`, backup any important game saves
3. **Use specific instance cleanup**: When troubleshooting, clean specific instances rather than everything
4. **Check status first**: Always run `status` command to see what's running before cleanup

## Integration with Stop Command

The `stop` command **ONLY** stops containers - it **NEVER** removes volumes automatically. This ensures:
- No accidental data loss
- Game saves and configurations persist
- You have explicit control over when data is removed
- Containers can be restarted with existing data intact

To completely remove an instance:
```bash
# Method 1: Stop then clean
./manage-clients.sh stop
./manage-clients.sh clean-volumes

# Method 2: Scale down then clean specific instance
./manage-clients-dynamic.sh scale 5  # If you had 6, this stops instance 6
./manage-clients-dynamic.sh clean-volumes 6
```
