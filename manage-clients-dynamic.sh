#!/bin/bash

# WoW Client Manager Script - Dynamic Version
# Usage: ./manage-clients.sh [start|stop|status|setup|scale] [number_of_instances]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
MAX_INSTANCES=${MAX_INSTANCES:-50}  # Default max, can be overridden
BASE_VNC_PORT=5900
BASE_API_PORT=5000
PROJECT_NAME="wow-clients"

function show_usage() {
    echo "Usage: $0 [start|stop|status|setup|scale|clean-volumes|clean-stopped|clean-all] [number_of_instances]"
    echo ""
    echo "Commands:"
    echo "  start <N>         - Start N instances of WoW clients (1-$MAX_INSTANCES)"
    echo "  stop              - Stop all running WoW client instances"
    echo "  status            - Show status of all instances"
    echo "  setup             - Create shared wow-client directory"
    echo "  scale <N>         - Scale to exactly N instances (start/stop as needed)"
    echo "  clean-volumes [N] - Clean volumes for specific instance(s) or all if no number given"
    echo "  clean-stopped     - Clean volumes only for stopped/non-existent containers"
    echo "  clean-all         - Clean all containers, volumes, and networks (DESTRUCTIVE)"
    echo ""
    echo "Examples:"
    echo "  $0 setup           # Create shared client directory"
    echo "  $0 start 1         # Start only 1 instance"
    echo "  $0 start 10        # Start 10 instances"
    echo "  $0 scale 5         # Scale to exactly 5 instances"
    echo "  $0 stop            # Stop all instances"
    echo "  $0 status          # Show running instances"
    echo "  $0 clean-volumes 3 # Clean volumes for instance 3 only"
    echo "  $0 clean-volumes   # Clean ALL volumes (WARNING: removes all data)"
    echo "  $0 clean-stopped   # Clean volumes for stopped containers only"
    echo "  $0 clean-all       # Nuclear option - clean everything"
    echo ""
    echo "Port mapping (dynamic):"
    echo "  Instance N: VNC=localhost:$((BASE_VNC_PORT + N - 1)), API=localhost:$((BASE_API_PORT + N - 1))"
    echo ""
    echo "Environment variables:"
    echo "  MAX_INSTANCES=$MAX_INSTANCES (override with export MAX_INSTANCES=100)"
    echo ""
    echo "Shared Client Files:"
    echo "  All instances share read-only client files from ./wow-client"
    echo "  Each instance has separate writable configs and saves"
}

function setup_directories() {
    echo "Setting up shared WoW client directory..."
    
    # Create the single shared client directory
    if [ ! -d "wow-client" ]; then
        mkdir -p "wow-client"
        echo "Created directory: wow-client"
        echo ""
        echo "Please copy your WoW client files to the 'wow-client' directory."
        echo "This single directory will be shared (read-only) across all instances."
        echo "Each instance will have its own writable overlay for saves and configs."
    else
        echo "Directory already exists: wow-client"
    fi
    
    echo ""
    echo "Setup complete! Now you can:"
    echo "1. Copy your WoW client files to the wow-client directory"
    echo "2. Run: $0 start <number_of_instances>"
    echo ""
    echo "Benefits of this approach:"
    echo "- Single copy of client files (saves disk space)"
    echo "- Each instance has isolated saves and configurations"
    echo "- Easy updates: just update the wow-client directory"
    echo "- Dynamic scaling from 1 to $MAX_INSTANCES instances"
}

function validate_instance_count() {
    local num_instances=$1
    
    if [[ ! "$num_instances" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: Number of instances must be a positive integer"
        exit 1
    fi
    
    if [ "$num_instances" -gt "$MAX_INSTANCES" ]; then
        echo "Error: Number of instances ($num_instances) exceeds maximum allowed ($MAX_INSTANCES)"
        echo "Set MAX_INSTANCES environment variable to increase limit"
        exit 1
    fi
}

function build_image() {
    echo "Building Docker image..."
    docker build -t wow-client:latest .
}

function start_instances() {
    local num_instances=$1
    
    validate_instance_count "$num_instances"
    
    echo "Starting $num_instances WoW client instance(s)..."
    
    # Build the image first
    build_image
    
    # Start instances using docker run with dynamic parameters
    for i in $(seq 1 $num_instances); do
        local container_name="${PROJECT_NAME}-client-$i"
        local vnc_port=$((BASE_VNC_PORT + i - 1))
        local api_port=$((BASE_API_PORT + i - 1))
        
        # Check if container already exists and is running
        if [ -n "$(docker ps -q -f name="^${container_name}$" 2>/dev/null)" ]; then
            echo "  Instance $i: Already running on VNC=$vnc_port, API=$api_port"
            continue
        fi
        
        # Remove existing stopped container if it exists
        docker rm "$container_name" >/dev/null 2>&1 || true
        
        # Create volume names
        local data_volume="${PROJECT_NAME}-client-$i-data"
        local lutris_volume="${PROJECT_NAME}-client-$i-lutris"
        local wine_volume="${PROJECT_NAME}-client-$i-wine"
        
        echo "  Starting Instance $i: VNC=$vnc_port, API=$api_port"
        
        # Start the container
        docker run -d \
            --name "$container_name" \
            --network "${PROJECT_NAME}_wow-network" \
            -p "$vnc_port:5900" \
            -p "$api_port:5000" \
            -v "$(pwd)/wow-client:/mnt/wow-client:ro" \
            -v "$data_volume:/root/Desktop/Client" \
            -v "$lutris_volume:/root/.local/share/lutris" \
            -v "$wine_volume:/root/.wine" \
            --tmpfs /tmp \
            -e "INSTANCE_ID=$i" \
            -e "VNC_PASSWD=${VNC_PASSWD:-password}" \
            -e "VNC_GEOMETRY=${VNC_GEOMETRY:-1280x800}" \
            -e "VNC_DEPTH=${VNC_DEPTH:-24}" \
            -e "SNAPSHOT_PATH=/tmp/desktop_snapshot.png" \
            -e "SNAPSHOT_INTERVAL_MS=${SNAPSHOT_INTERVAL_MS:-500}" \
            --restart unless-stopped \
            wow-client:latest
    done
    
    # Create network if it doesn't exist
    docker network create "${PROJECT_NAME}_wow-network" >/dev/null 2>&1 || true
    
    echo ""
    echo "Instances started! Access them via:"
    for i in $(seq 1 $num_instances); do
        local vnc_port=$((BASE_VNC_PORT + i - 1))
        local api_port=$((BASE_API_PORT + i - 1))
        echo "  Instance $i: VNC=localhost:$vnc_port, API=localhost:$api_port"
    done
}

function stop_instances() {
    echo "Stopping all WoW client instances..."
    
    # Find all containers with our naming pattern
    local containers=$(docker ps -q -f name="${PROJECT_NAME}-client-")
    
    if [ -z "$containers" ]; then
        echo "No running instances found."
        return
    fi
    
    # Stop all containers
    echo "$containers" | xargs docker stop
    
    echo "All instances stopped."
}

function scale_instances() {
    local target_instances=$1
    
    validate_instance_count "$target_instances"
    
    echo "Scaling to $target_instances instances..."
    
    # Get currently running instances
    local running_containers=$(docker ps -q -f name="${PROJECT_NAME}-client-")
    local current_count=$(echo "$running_containers" | grep -c . || echo 0)
    
    echo "Current instances: $current_count, Target: $target_instances"
    
    if [ "$current_count" -eq "$target_instances" ]; then
        echo "Already at target scale of $target_instances instances."
        return
    elif [ "$current_count" -lt "$target_instances" ]; then
        # Need to start more instances
        local start_from=$((current_count + 1))
        echo "Starting additional instances from $start_from to $target_instances..."
        
        # Build image if needed
        build_image
        
        for i in $(seq $start_from $target_instances); do
            local container_name="${PROJECT_NAME}-client-$i"
            local vnc_port=$((BASE_VNC_PORT + i - 1))
            local api_port=$((BASE_API_PORT + i - 1))
            
            # Remove existing stopped container if it exists
            docker rm "$container_name" >/dev/null 2>&1 || true
            
            # Create volume names
            local data_volume="${PROJECT_NAME}-client-$i-data"
            local lutris_volume="${PROJECT_NAME}-client-$i-lutris"
            local wine_volume="${PROJECT_NAME}-client-$i-wine"
            
            echo "  Starting Instance $i: VNC=$vnc_port, API=$api_port"
            
            # Ensure network exists
            docker network create "${PROJECT_NAME}_wow-network" >/dev/null 2>&1 || true
            
            # Start the container
            docker run -d \
                --name "$container_name" \
                --network "${PROJECT_NAME}_wow-network" \
                -p "$vnc_port:5900" \
                -p "$api_port:5000" \
                -v "$(pwd)/wow-client:/mnt/wow-client:ro" \
                -v "$data_volume:/root/Desktop/Client" \
                -v "$lutris_volume:/root/.local/share/lutris" \
                -v "$wine_volume:/root/.wine" \
                --tmpfs /tmp \
                -e "INSTANCE_ID=$i" \
                -e "VNC_PASSWD=${VNC_PASSWD:-password}" \
                -e "VNC_GEOMETRY=${VNC_GEOMETRY:-1280x800}" \
                -e "VNC_DEPTH=${VNC_DEPTH:-24}" \
                -e "SNAPSHOT_PATH=/tmp/desktop_snapshot.png" \
                -e "SNAPSHOT_INTERVAL_MS=${SNAPSHOT_INTERVAL_MS:-500}" \
                --restart unless-stopped \
                wow-client:latest
        done
    else
        # Need to stop some instances
        echo "Stopping excess instances (keeping first $target_instances)..."
        
        for i in $(seq $((target_instances + 1)) $current_count); do
            local container_name="${PROJECT_NAME}-client-$i"
            echo "  Stopping Instance $i"
            docker stop "$container_name" 2>/dev/null || true
            docker rm "$container_name" 2>/dev/null || true
        done
    fi
    
    echo "Scaling complete!"
}

function show_status() {
    echo "WoW Client Instance Status:"
    echo "=========================="
    
    # Get list of all containers (running and stopped) with our naming pattern
    local all_containers=$(docker ps -a -f name="${PROJECT_NAME}-client-" --format "{{.Names}}" | sort -V)
    
    if [ -z "$all_containers" ]; then
        echo "No instances found."
        return
    fi
    
    for container_name in $all_containers; do
        # Extract instance number from container name
        local instance_num=$(echo "$container_name" | sed "s/${PROJECT_NAME}-client-//")
        local vnc_port=$((BASE_VNC_PORT + instance_num - 1))
        local api_port=$((BASE_API_PORT + instance_num - 1))
        
        local status=$(docker ps -f name="^${container_name}$" --format "{{.Status}}" 2>/dev/null)
        
        if [ -n "$status" ]; then
            echo "  Instance $instance_num: RUNNING ($status)"
            echo "    VNC: localhost:$vnc_port"
            echo "    API: localhost:$api_port"
        else
            echo "  Instance $instance_num: STOPPED"
        fi
    done
    
    echo ""
    echo "Active containers:"
    docker ps -f name="${PROJECT_NAME}-client-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    echo "Resource usage:"
    docker stats --no-stream -f name="${PROJECT_NAME}-client-" --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "No running containers to show stats for"
}

function clean_volumes() {
    local instance_num=$1
    
    if [ -n "$instance_num" ]; then
        # Clean specific instance
        if [[ ! "$instance_num" =~ ^[1-9][0-9]*$ ]]; then
            echo "Error: Instance number must be a positive integer"
            exit 1
        fi
        
        echo "Cleaning volumes for instance $instance_num..."
        
        # Check if container is running
        local container_name="${PROJECT_NAME}-client-$instance_num"
        if docker ps -q --filter "name=^${container_name}$" | grep -q .; then
            echo "Error: Instance $instance_num is still running. Stop it first with: $0 stop"
            exit 1
        fi
        
        # Remove container if it exists (stopped)
        docker rm "$container_name" 2>/dev/null || true
        
        # Remove specific volumes
        local volumes=(
            "${PROJECT_NAME}-client-${instance_num}-data"
            "${PROJECT_NAME}-client-${instance_num}-lutris"
            "${PROJECT_NAME}-client-${instance_num}-wine"
        )
        
        for volume in "${volumes[@]}"; do
            if docker volume ls -q --filter "name=$volume" | grep -q "^$volume$"; then
                echo "  Removing volume: $volume"
                docker volume rm "$volume"
            else
                echo "  Volume not found: $volume"
            fi
        done
        
        echo "Volumes for instance $instance_num cleaned."
    else
        # Clean all volumes
        echo "WARNING: This will remove ALL WoW client data including saves and configurations!"
        echo "Make sure all instances are stopped first."
        echo ""
        read -p "Are you sure you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Operation cancelled."
            return
        fi
        
        # Stop all containers first
        echo "Stopping all WoW client instances..."
        stop_instances
        
        echo "Removing all containers..."
        docker ps -a --filter "name=${PROJECT_NAME}-client-" -q | xargs -r docker rm
        
        echo "Removing all volumes..."
        # Remove all volumes matching our pattern
        docker volume ls -q --filter "name=${PROJECT_NAME}-client-" | xargs -r docker volume rm
        
        echo "All volumes cleaned."
    fi
}

function clean_stopped() {
    echo "Cleaning volumes for stopped containers only..."
    
    # Get all containers (running and stopped) with our naming pattern
    local all_containers=$(docker ps -a --filter "name=${PROJECT_NAME}-client-" --format "{{.Names}}")
    local running_containers=$(docker ps --filter "name=${PROJECT_NAME}-client-" --format "{{.Names}}")
    
    if [ -z "$all_containers" ]; then
        echo "No WoW client containers found."
        return
    fi
    
    # Find stopped containers
    local stopped_containers=""
    for container in $all_containers; do
        if ! echo "$running_containers" | grep -q "^$container$"; then
            stopped_containers="$stopped_containers $container"
        fi
    done
    
    if [ -z "$stopped_containers" ]; then
        echo "No stopped containers found."
        return
    fi
    
    echo "Found stopped containers:$stopped_containers"
    
    for container in $stopped_containers; do
        # Extract instance number
        local instance_num=$(echo "$container" | sed "s/${PROJECT_NAME}-client-//")
        
        echo "Cleaning volumes for stopped instance $instance_num..."
        
        # Remove the stopped container
        docker rm "$container" 2>/dev/null || true
        
        # Remove volumes for this instance
        local volumes=(
            "${PROJECT_NAME}-client-${instance_num}-data"
            "${PROJECT_NAME}-client-${instance_num}-lutris"
            "${PROJECT_NAME}-client-${instance_num}-wine"
        )
        
        for volume in "${volumes[@]}"; do
            if docker volume ls -q --filter "name=$volume" | grep -q "^$volume$"; then
                echo "  Removing volume: $volume"
                docker volume rm "$volume"
            fi
        done
    done
    
    echo "Stopped container volumes cleaned."
}

function clean_all() {
    echo "WARNING: This will remove ALL WoW client containers, volumes, and networks!"
    echo "This is a destructive operation that cannot be undone."
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        return
    fi
    
    echo "Stopping all WoW client instances..."
    stop_instances
    
    echo "Removing all containers..."
    docker ps -a --filter "name=${PROJECT_NAME}-client-" -q | xargs -r docker rm -f
    
    echo "Removing all volumes..."
    docker volume ls -q --filter "name=${PROJECT_NAME}-client-" | xargs -r docker volume rm
    
    echo "Removing networks..."
    docker network ls --filter "name=${PROJECT_NAME}_wow-network" -q | xargs -r docker network rm 2>/dev/null || true
    
    echo "Cleaning up unused Docker resources..."
    docker system prune -f
    
    echo "Complete cleanup finished."
}

# Main script logic
case "$1" in
    "setup")
        setup_directories
        ;;
    "start")
        if [ -z "$2" ]; then
            echo "Error: Please specify number of instances to start"
            show_usage
            exit 1
        fi
        start_instances "$2"
        ;;
    "stop")
        stop_instances
        ;;
    "status")
        show_status
        ;;
    "scale")
        if [ -z "$2" ]; then
            echo "Error: Please specify target number of instances"
            show_usage
            exit 1
        fi
        scale_instances "$2"
        ;;
    "clean-volumes")
        clean_volumes "$2"
        ;;
    "clean-stopped")
        clean_stopped
        ;;
    "clean-all")
        clean_all
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
