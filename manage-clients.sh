#!/bin/bash

# WoW Client Manager Script
# Usage: ./manage-clients.sh [start|stop|status] [number_of_instances]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

function show_usage() {
    echo "Usage: $0 [start|stop|status|setup] [number_of_instances]"
    echo ""
    echo "Commands:"
    echo "  start <N>  - Start N instances of WoW clients (1-5)"
    echo "  stop       - Stop all running WoW client instances"
    echo "  status     - Show status of all instances"
    echo "  setup <N>  - Create shared wow-client directory"
    echo ""
    echo "Examples:"
    echo "  $0 setup 3     # Create shared client directory"
    echo "  $0 start 1     # Start only the first instance"
    echo "  $0 start 3     # Start 3 instances"
    echo "  $0 stop        # Stop all instances"
    echo "  $0 status      # Show running instances"
    echo ""
    echo "Port mapping:"
    echo "  Instance 1: VNC=5900, API=5000"
    echo "  Instance 2: VNC=5901, API=5001"
    echo "  Instance 3: VNC=5902, API=5002"
    echo "  Instance 4: VNC=5903, API=5003"
    echo "  Instance 5: VNC=5904, API=5004"
    echo ""
    echo "Shared Client Files:"
    echo "  All instances share read-only client files from ./wow-client"
    echo "  Each instance has separate writable configs and saves"
}

function setup_directories() {
    local num_instances=$1
    
    if [[ ! "$num_instances" =~ ^[1-5]$ ]]; then
        echo "Error: Number of instances must be between 1 and 5"
        exit 1
    fi
    
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
    echo "2. Run: $0 start $num_instances"
    echo ""
    echo "Benefits of this approach:"
    echo "- Single copy of client files (saves disk space)"
    echo "- Each instance has isolated saves and configurations"
    echo "- Easy updates: just update the wow-client directory"
}

function start_instances() {
    local num_instances=$1
    
    if [[ ! "$num_instances" =~ ^[1-5]$ ]]; then
        echo "Error: Number of instances must be between 1 and 5"
        exit 1
    fi
    
    echo "Starting $num_instances WoW client instance(s)..."
    
    # Build the image first
    echo "Building Docker image..."
    docker-compose build
    
    if [ "$num_instances" -eq 1 ]; then
        # Start only the first instance
        docker-compose up -d wow-client-1
    else
        # Start multiple instances using profiles
        docker-compose --profile multi up -d $(seq -f "wow-client-%.0f" 1 $num_instances | tr '\n' ' ')
    fi
    
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
    docker-compose --profile multi down
    echo "All instances stopped."
}

function show_status() {
    echo "WoW Client Instance Status:"
    echo "=========================="
    
    for i in {1..5}; do
        local container_name="wow-client-$i"
        local status=$(docker ps --filter "name=$container_name" --format "{{.Status}}" 2>/dev/null)
        
        if [ -n "$status" ]; then
            local vnc_port=$((5899 + i))
            local api_port=$((4999 + i))
            echo "  Instance $i: RUNNING ($status)"
            echo "    VNC: localhost:$vnc_port"
            echo "    API: localhost:$api_port"
        else
            echo "  Instance $i: STOPPED"
        fi
    done
    
    echo ""
    echo "Active containers:"
    docker ps --filter "name=wow-client" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Main script logic
case "$1" in
    "setup")
        if [ -z "$2" ]; then
            echo "Error: Please specify number of instances to setup"
            show_usage
            exit 1
        fi
        setup_directories "$2"
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
    *)
        show_usage
        exit 1
        ;;
esac
