#!/bin/bash

# PostgreSQL Auto-Failover Setup Script
# This master script orchestrates the setup of monitor and database servers
# across multiple independent servers

set -e

MONITOR_SERVER_IP="10.164.32.93"    # Update with actual monitor server IP
DB1_SERVER_IP="10.164.32.94"        # Update with actual DB1 server IP  
DB2_SERVER_IP="10.164.32.95"        # Update with actual DB2 server IP

# SSH connection details (update as needed)
MONITOR_USER="ubuntu"  # SSH username for monitor server
DB1_USER="ubuntu"      # SSH username for DB1 server
DB2_USER="ubuntu"      # SSH username for DB2 server

echo "=== PostgreSQL Auto-Failover Setup ==="
echo "Monitor Server: $MONITOR_SERVER_IP"
echo "DB1 Server: $DB1_SERVER_IP"
echo "DB2 Server: $DB2_SERVER_IP"
echo ""

# Function to check if server is reachable
check_server_connectivity() {
    local server_ip=$1
    local server_name=$2
    
    echo "Checking connectivity to $server_name ($server_ip)..."
    if ping -c 1 -W 3 "$server_ip" >/dev/null 2>&1; then
        echo "✓ $server_name is reachable"
    else
        echo "✗ $server_name is not reachable"
        return 1
    fi
}

# Function to copy files to remote server
copy_files_to_server() {
    local server_ip=$1
    local user=$2
    local server_name=$3
    
    echo "Copying files to $server_name..."
    scp docker-compose.*.yml setup-*.sh "$user@$server_ip:~/"
    echo "✓ Files copied to $server_name"
}

# Function to make scripts executable on remote server
make_scripts_executable() {
    local server_ip=$1
    local user=$2
    local server_name=$3
    
    echo "Making scripts executable on $server_name..."
    ssh "$user@$server_ip" "chmod +x setup-*.sh"
    echo "✓ Scripts are now executable on $server_name"
}

# Check connectivity to all servers
echo "Step 1: Checking server connectivity..."
check_server_connectivity "$MONITOR_SERVER_IP" "Monitor Server" || exit 1
check_server_connectivity "$DB1_SERVER_IP" "DB1 Server" || exit 1
check_server_connectivity "$DB2_SERVER_IP" "DB2 Server" || exit 1
echo ""

# Copy files to all servers
echo "Step 2: Copying files to servers..."
copy_files_to_server "$MONITOR_SERVER_IP" "$MONITOR_USER" "Monitor Server"
copy_files_to_server "$DB1_SERVER_IP" "$DB1_USER" "DB1 Server"
copy_files_to_server "$DB2_SERVER_IP" "$DB2_USER" "DB2 Server"
echo ""

# Make scripts executable
echo "Step 3: Making scripts executable..."
make_scripts_executable "$MONITOR_SERVER_IP" "$MONITOR_USER" "Monitor Server"
make_scripts_executable "$DB1_SERVER_IP" "$DB1_USER" "DB1 Server"
make_scripts_executable "$DB2_SERVER_IP" "$DB2_USER" "DB2 Server"
echo ""

# Start Monitor Server
echo "Step 4: Starting Monitor Server..."
echo "Running setup-monitor.sh on Monitor Server..."
ssh "$MONITOR_USER@$MONITOR_SERVER_IP" "cd ~ && ./setup-monitor.sh"
echo "✓ Monitor Server started successfully"
echo ""

# Wait for monitor to be fully ready
echo "Step 5: Waiting for Monitor Server to be ready..."
sleep 30
echo ""

# Start DB1 Server (Primary)
echo "Step 6: Starting DB1 Server (Primary)..."
echo "Running setup-db1.sh on DB1 Server..."
ssh "$DB1_USER@$DB1_SERVER_IP" "cd ~ && ./setup-db1.sh"
echo "✓ DB1 Server started successfully"
echo ""

# Wait for DB1 to be fully ready
echo "Step 7: Waiting for DB1 Server to be ready..."
sleep 30
echo ""

# Start DB2 Server (Secondary)
echo "Step 8: Starting DB2 Server (Secondary)..."
echo "Running setup-db2.sh on DB2 Server..."
ssh "$DB2_USER@$DB2_SERVER_IP" "cd ~ && ./setup-db2.sh"
echo "✓ DB2 Server started successfully"
echo ""

# Final verification
echo "Step 9: Final verification..."
echo "Checking cluster status on monitor..."
ssh "$MONITOR_USER@$MONITOR_SERVER_IP" "docker exec pg-monitor pg_autoctl show state --pgdata /var/lib/postgresql/data/monitor" || true
echo ""

echo "=== Setup Complete ==="
echo ""
echo "Your PostgreSQL Auto-Failover cluster is now running!"
echo ""
echo "Servers:"
echo "  Monitor: $MONITOR_SERVER_IP:5432"
echo "  Primary DB: $DB1_SERVER_IP:5432"
echo "  Secondary DB: $DB2_SERVER_IP:5432"
echo ""
echo "Useful commands:"
echo "  # Check cluster status"
echo "  ssh $MONITOR_USER@$MONITOR_SERVER_IP 'docker exec pg-monitor pg_autoctl show state'"
echo ""
echo "  # Perform manual failover"
echo "  ssh $MONITOR_USER@$MONITOR_SERVER_IP 'docker exec pg-monitor pg_autoctl perform failover'"
echo ""
echo "  # Check replication status"
echo "  ssh $DB1_USER@$DB1_SERVER_IP 'docker exec postgres psql -U postgres -d appdb -c \"SELECT * FROM pg_stat_replication;\"'"