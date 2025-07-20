#!/bin/bash

# Generate docker-compose.yml dynamically
# Usage: ./generate-compose.sh <number_of_instances> [output_file]

function generate_compose() {
    local num_instances=$1
    local output_file=${2:-"docker-compose.generated.yml"}
    
    if [[ ! "$num_instances" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: Number of instances must be a positive integer"
        exit 1
    fi
    
    echo "Generating docker-compose.yml for $num_instances instances..."
    
    # Start the compose file
    cat > "$output_file" << 'EOF'
version: '3.8'

services:
EOF

    # Generate services
    for i in $(seq 1 $num_instances); do
        local vnc_port=$((5899 + i))
        local api_port=$((4999 + i))
        
        cat >> "$output_file" << EOF
  wow-client-$i:
    build: .
    container_name: wow-client-$i
    ports:
      - "$vnc_port:5900"  # VNC
      - "$api_port:5000"  # API
    volumes:
      # Read-only client files shared across all instances
      - ./wow-client:/mnt/wow-client:ro
      # Writable overlay for saves, configs, etc. (each instance gets its own)
      - wow-client-$i-data:/root/Desktop/Client
      # Lutris and Wine data persistence
      - wow-client-$i-lutris:/root/.local/share/lutris
      - wow-client-$i-wine:/root/.wine
    environment:
      - INSTANCE_ID=$i
      - VNC_PASSWD=\${VNC_PASSWD:-password}
      - VNC_GEOMETRY=\${VNC_GEOMETRY:-1280x800}
      - VNC_DEPTH=\${VNC_DEPTH:-24}
      - SNAPSHOT_PATH=/tmp/desktop_snapshot.png
      - SNAPSHOT_INTERVAL_MS=\${SNAPSHOT_INTERVAL_MS:-500}
    tmpfs:
      - /tmp
    restart: unless-stopped
    networks:
      - wow-network

EOF
    done
    
    # Add networks section
    cat >> "$output_file" << 'EOF'
networks:
  wow-network:
    driver: bridge

volumes:
EOF

    # Generate volumes
    for i in $(seq 1 $num_instances); do
        cat >> "$output_file" << EOF
  wow-client-$i-data:
  wow-client-$i-lutris:
  wow-client-$i-wine:
EOF
    done
    
    echo "Generated $output_file with $num_instances instances"
    echo "Port mapping:"
    for i in $(seq 1 $num_instances); do
        local vnc_port=$((5899 + i))
        local api_port=$((4999 + i))
        echo "  Instance $i: VNC=localhost:$vnc_port, API=localhost:$api_port"
    done
}

# Main execution
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <number_of_instances> [output_file]"
    echo "Example: $0 10 docker-compose.yml"
    exit 1
fi

generate_compose "$1" "$2"
