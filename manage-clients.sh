#!/bin/bash

# WoW Client Manager Script
# Usage: ./manage-clients.sh [start|stop|status] [number_of_instances]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

function show_usage() {
    echo "Usage: $0 [start|stop|status|setup|clean-volumes|clean-stopped|clean-all] [number_of_instances|instance_numbers]"
    echo ""
    echo "Commands:"
    echo "  start <N>         - Start N instances of WoW clients (unlimited)"
    echo "  stop              - Stop all running WoW client instances"
    echo "  status            - Show status of all instances"
    echo "  setup             - Create shared wow-client directory"
    echo "  clean-volumes [N] - Clean volumes for specific instance(s) or all if no number given"
    echo "  clean-stopped     - Clean volumes only for stopped/non-existent containers"
    echo "  clean-all         - Clean all containers, volumes, and networks (DESTRUCTIVE)"
    echo ""
    echo "Examples:"
    echo "  $0 setup           # Create shared client directory"
    echo "  $0 start 1         # Start only 1 instance"
    echo "  $0 start 10        # Start 10 instances"
    echo "  $0 stop            # Stop all instances"
    echo "  $0 status          # Show running instances"
    echo "  $0 clean-volumes 3 # Clean volumes for instance 3 only"
    echo "  $0 clean-volumes   # Clean ALL volumes (WARNING: removes all data)"
    echo "  $0 clean-stopped   # Clean volumes for stopped containers only"
    echo "  $0 clean-all       # Nuclear option - clean everything"
    echo ""
    echo "Port mapping (dynamic):"
    echo "  Instance N: VNC=localhost:$((5899 + N)), API=localhost:$((4999 + N))"
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
    echo "- Dynamic scaling to any number of instances"
}

function start_instances() {
    local num_instances=$1
    
    if [[ ! "$num_instances" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: Number of instances must be a positive integer"
        exit 1
    fi
    
    echo "Starting $num_instances WoW client instance(s)..."
    
    # Generate dynamic docker-compose file
    echo "Generating docker-compose configuration for $num_instances instances..."
    ./generate-compose.sh "$num_instances" "docker-compose.generated.yml"
    
    # Build the image first
    echo "Building Docker image..."
    docker-compose -f docker-compose.generated.yml build
    
    # Start all instances
    docker-compose -f docker-compose.generated.yml up -d
    
    echo ""
    echo "Instances started! Access them via:"
    for i in $(seq 1 $num_instances); do
        local vnc_port=$((5899 + i))
        local api_port=$((4999 + i))
        echo "  Instance $i: VNC=localhost:$vnc_port, API=localhost:$api_port"
    done
}

function stop_instances() {
    echo "Stopping all WoW client instances..."
    
    # Use the generated compose file if it exists, otherwise try the original
    if [ -f "docker-compose.generated.yml" ]; then
        docker-compose -f docker-compose.generated.yml down
    else
        docker-compose --profile multi down
    fi
    
    echo "All instances stopped."
}

function show_status() {
    echo "WoW Client Instance Status:"
    echo "=========================="
    
    local found_containers=0
    
    for i in {1..20}; do
        local container_name="wow-client-$i"
        local status=$(docker ps --filter "name=$container_name" --format "{{.Status}}" 2>/dev/null)
        
        if [ -n "$status" ]; then
            local vnc_port=$((5899 + i))
            local api_port=$((4999 + i))
            echo "  Instance $i: RUNNING ($status)"
            echo "    VNC: localhost:$vnc_port"
            echo "    API: localhost:$api_port"
            found_containers=1
        elif docker ps -a --filter "name=$container_name" --format "{{.Names}}" | grep -q "^$container_name$"; then
            echo "  Instance $i: STOPPED"
            found_containers=1
        fi
    done
    
    echo ""
    echo "Active containers:"
    docker ps --filter "name=wow-client" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    echo "Resource usage:"
    local running_containers=$(docker ps -q --filter "name=wow-client")
    if [ -n "$running_containers" ]; then
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $running_containers
    else
        echo "No running containers to show stats for"
    fi
    
    # If we expected containers but didn't find any, that's an error
    if [ $found_containers -eq 0 ]; then
        # Check for containers created by other methods (Docker Compose or Dynamic)
        local compose_containers=$(docker ps --filter "name=wow-clients-client" --format "{{.Names}}" | wc -l)
        local all_wow_containers=$(docker ps --filter "name=wow" --format "{{.Names}}" | wc -l)
        
        if [ $compose_containers -gt 0 ]; then
            echo ""
            echo "Note: Found $compose_containers containers created by other methods (Dynamic/Compose):"
            docker ps --filter "name=wow-clients-client" --format "  {{.Names}} ({{.Status}})"
            echo "Use './manage-clients-dynamic.sh status' to manage these containers."
            return 0  # Don't treat this as an error
        elif [ $all_wow_containers -eq 0 ]; then
            echo "Warning: No WoW client containers found"
            return 1
        fi
    fi
}

function clean_volumes() {
    local instance_num=$1
    local project_prefix=$(basename "$(pwd)")
    
    if [ -n "$instance_num" ]; then
        # Clean specific instance
        if [[ ! "$instance_num" =~ ^[1-9][0-9]*$ ]]; then
            echo "Error: Instance number must be a positive integer"
            exit 1
        fi
        
        echo "Cleaning volumes for instance $instance_num..."
        
        # Check if container is running
        if docker ps -q --filter "name=wow-client-$instance_num" | grep -q .; then
            echo "Error: Instance $instance_num is still running. Stop it first with: $0 stop"
            exit 1
        fi
        
        # Remove container if it exists (stopped)
        docker rm "wow-client-$instance_num" 2>/dev/null || true
        
        # Remove specific volumes
        local volumes=(
            "${project_prefix}_wow-client-${instance_num}-data"
            "${project_prefix}_wow-client-${instance_num}-lutris"
            "${project_prefix}_wow-client-${instance_num}-wine"
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
        docker ps -a --filter "name=wow-client-" -q | xargs -r docker rm
        
        echo "Removing all volumes..."
        # Remove all volumes matching our pattern
        docker volume ls -q --filter "name=${project_prefix}_wow-client-" | xargs -r docker volume rm
        
        echo "All volumes cleaned."
    fi
}

function clean_stopped() {
    echo "Cleaning volumes for stopped containers only..."
    local project_prefix=$(basename "$(pwd)")
    
    # Get all containers (running and stopped) with our naming pattern
    local all_containers=$(docker ps -a --filter "name=wow-client-" --format "{{.Names}}")
    local running_containers=$(docker ps --filter "name=wow-client-" --format "{{.Names}}")
    
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
        local instance_num=$(echo "$container" | sed 's/wow-client-//')
        
        echo "Cleaning volumes for stopped instance $instance_num..."
        
        # Remove the stopped container
        docker rm "$container" 2>/dev/null || true
        
        # Remove volumes for this instance
        local volumes=(
            "${project_prefix}_wow-client-${instance_num}-data"
            "${project_prefix}_wow-client-${instance_num}-lutris"
            "${project_prefix}_wow-client-${instance_num}-wine"
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
    
    local project_prefix=$(basename "$(pwd)")
    
    echo "Stopping all WoW client instances..."
    stop_instances
    
    echo "Removing all containers..."
    docker ps -a --filter "name=wow-client-" -q | xargs -r docker rm -f
    
    echo "Removing all volumes..."
    docker volume ls -q --filter "name=${project_prefix}_wow-client-" | xargs -r docker volume rm
    
    echo "Removing networks..."
    docker network ls --filter "name=wow-network" -q | xargs -r docker network rm 2>/dev/null || true
    
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
