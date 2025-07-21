#!/bin/bash

# WoW Client Manager Script - Docker Swarm Version
# Usage: ./manage-clients-swarm.sh [init|start|stop|status|scale] [number_of_instances]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
SERVICE_NAME="wow-clients_wow-client"
STACK_NAME="wow-clients"

function show_usage() {
    echo "Usage: $0 [init|deploy|stop|status|scale|clean-volumes|clean-stopped|clean-all] [number_of_instances]"
    echo ""
    echo "Commands:"
    echo "  init              - Initialize Docker Swarm mode"
    echo "  deploy <N>        - Deploy stack with N instances"
    echo "  stop              - Remove the entire stack"
    echo "  status            - Show status of all instances"
    echo "  scale <N>         - Scale service to N instances"
    echo "  clean-volumes     - Clean unused volumes (Docker Swarm manages containers automatically)"
    echo "  clean-stopped     - Clean unused resources (in Swarm mode, stopped services are auto-removed)"
    echo "  clean-all         - Clean all stack resources and unused Docker resources (DESTRUCTIVE)"
    echo ""
    echo "Examples:"
    echo "  $0 init            # Initialize swarm mode"
    echo "  $0 deploy 5        # Deploy stack with 5 instances"
    echo "  $0 scale 10        # Scale to 10 instances"
    echo "  $0 status          # Show running instances"
    echo "  $0 stop            # Stop entire stack"
    echo "  $0 clean-volumes   # Clean unused volumes"
    echo "  $0 clean-all       # Clean everything"
    echo ""
    echo "Benefits of Swarm mode:"
    echo "  - True container orchestration"
    echo "  - Automatic load balancing"
    echo "  - Service discovery"
    echo "  - Rolling updates"
    echo "  - Health checks and auto-restart"
    echo "  - Automatic cleanup of stopped containers"
}

function init_swarm() {
    echo "Initializing Docker Swarm mode..."
    
    if docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
        echo "Swarm mode already initialized"
    else
        docker swarm init
        echo "Swarm mode initialized"
    fi
    
    # Build and push image to local registry (optional)
    echo "Building image..."
    docker build -t wow-client:latest .
}

function deploy_stack() {
    local num_instances=$1
    
    if [[ ! "$num_instances" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: Number of instances must be a positive integer"
        exit 1
    fi
    
    echo "Deploying stack with $num_instances instances..."
    
    # Deploy the stack
    docker stack deploy -c docker-compose.swarm.yml "$STACK_NAME"
    
    # Scale the service
    docker service scale "${STACK_NAME}_wow-client=$num_instances"
    
    echo "Stack deployed and scaled to $num_instances instances"
}

function scale_service() {
    local num_instances=$1
    
    if [[ ! "$num_instances" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: Number of instances must be a positive integer"
        exit 1
    fi
    
    echo "Scaling service to $num_instances instances..."
    
    docker service scale "${STACK_NAME}_wow-client=$num_instances"
    
    echo "Service scaled to $num_instances instances"
}

function stop_stack() {
    echo "Removing stack..."
    docker stack rm "$STACK_NAME"
    echo "Stack removed"
}

function show_status() {
    echo "WoW Client Service Status:"
    echo "========================="
    
    # Check if we're in swarm mode first
    if ! docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active"; then
        echo "Error: Docker is not in swarm mode. Run '$0 init' first."
        return 1
    fi
    
    # Check if stack exists
    if ! docker stack ls --format "{{.Name}}" | grep -q "^${STACK_NAME}$"; then
        echo "Stack '$STACK_NAME' is not deployed"
        return 1
    fi
    
    # Show service status
    echo "Service overview:"
    docker service ls --filter "name=${STACK_NAME}_"
    
    echo ""
    echo "Service details:"
    docker service ps "${STACK_NAME}_wow-client" --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}\t{{.Ports}}"
    
    echo ""
    echo "Service logs (last 10 lines):"
    docker service logs "${STACK_NAME}_wow-client" --tail 10
}

function clean_volumes() {
    echo "Cleaning unused volumes..."
    echo ""
    echo "Note: In Docker Swarm mode, individual container volumes are managed differently."
    echo "This operation will clean up unused volumes across the entire Docker host."
    echo ""
    read -p "Continue with volume cleanup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        return
    fi
    
    # Show volumes before cleanup
    echo "Volumes before cleanup:"
    docker volume ls --filter "dangling=true"
    
    # Remove unused volumes
    docker volume prune -f
    
    echo "Volume cleanup complete."
}

function clean_stopped() {
    echo "Cleaning stopped/unused resources..."
    echo ""
    echo "Note: Docker Swarm automatically manages container lifecycle."
    echo "This operation will clean up unused resources across the Docker host."
    
    # Clean unused containers (if any exist outside of swarm)
    echo "Removing unused containers..."
    docker container prune -f
    
    # Clean unused images
    echo "Removing unused images..."
    docker image prune -f
    
    # Clean unused networks
    echo "Removing unused networks..."
    docker network prune -f
    
    # Clean unused volumes
    echo "Removing unused volumes..."
    docker volume prune -f
    
    echo "Resource cleanup complete."
}

function clean_all() {
    echo "WARNING: This will remove the entire WoW client stack and clean all unused Docker resources!"
    echo "This is a destructive operation that cannot be undone."
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        return
    fi
    
    echo "Removing stack..."
    stop_stack
    
    echo "Waiting for stack removal to complete..."
    sleep 5
    
    echo "Cleaning up all unused Docker resources..."
    docker system prune -a -f --volumes
    
    echo "Complete cleanup finished."
}

# Main script logic
case "$1" in
    "init")
        init_swarm
        ;;
    "deploy")
        if [ -z "$2" ]; then
            echo "Error: Please specify number of instances to deploy"
            show_usage
            exit 1
        fi
        deploy_stack "$2"
        ;;
    "scale")
        if [ -z "$2" ]; then
            echo "Error: Please specify number of instances to scale to"
            show_usage
            exit 1
        fi
        scale_service "$2"
        ;;
    "stop")
        stop_stack
        ;;
    "status")
        show_status
        ;;
    "clean-volumes")
        clean_volumes
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
