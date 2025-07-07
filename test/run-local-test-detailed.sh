#!/bin/bash

# Local Test Script for PostgreSQL Auto-Failover with Detailed Logging
# This script runs all three services on a single machine and logs everything

set -e

# Setup logging
LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/pg-auto-failover-setup-$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$LOG_DIR"

# Function to log with timestamp
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Function to run command with logging
run_with_log() {
    local cmd="$1"
    local description="$2"
    
    log "EXECUTING: $description"
    log "COMMAND: $cmd"
    
    if eval "$cmd" >> "$LOG_FILE" 2>&1; then
        log "SUCCESS: $description completed successfully"
        return 0
    else
        local exit_code=$?
        log "ERROR: $description failed with exit code $exit_code"
        return $exit_code
    fi
}

# Function to wait for container health
wait_for_health() {
    local container_name="$1"
    local max_wait="$2"
    local elapsed=0
    
    log "Waiting for container '$container_name' to become healthy (max ${max_wait}s)..."
    
    while [ $elapsed -lt $max_wait ]; do
        if docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null | grep -q "healthy"; then
            log "SUCCESS: Container '$container_name' is healthy after ${elapsed}s"
            return 0
        fi
        
        local status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "unknown")
        log "INFO: Container '$container_name' health status: $status (${elapsed}/${max_wait}s)"
        
        sleep 5
        elapsed=$((elapsed + 5))
    done
    
    log "ERROR: Container '$container_name' failed to become healthy within ${max_wait}s"
    return 1
}

# Function to collect container logs
collect_logs() {
    local container_name="$1"
    local service_name="$2"
    
    log "Collecting logs for $service_name ($container_name)..."
    
    echo "==================== $service_name LOGS ====================" >> "$LOG_FILE"
    docker logs "$container_name" >> "$LOG_FILE" 2>&1 || log "WARNING: Failed to collect logs for $container_name"
    echo "================= END $service_name LOGS ===================" >> "$LOG_FILE"
}

# Function to check docker status
check_docker() {
    log "Checking Docker daemon status..."
    if ! docker info >/dev/null 2>&1; then
        log "ERROR: Docker daemon is not running"
        exit 1
    fi
    log "SUCCESS: Docker daemon is running"
}

# Function to check system resources
check_resources() {
    log "Checking system resources..."
    
    # Check available memory
    local mem_available=$(free -m | awk '/^Mem:/{print $7}' 2>/dev/null || echo "unknown")
    log "INFO: Available memory: ${mem_available}MB"
    
    # Check disk space
    local disk_available=$(df -h . | awk 'NR==2{print $4}' 2>/dev/null || echo "unknown")
    log "INFO: Available disk space: $disk_available"
    
    # Check running containers
    local running_containers=$(docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "none")
    log "INFO: Currently running containers:"
    echo "$running_containers" >> "$LOG_FILE"
}

# Main execution starts here
log "=== PostgreSQL Auto-Failover Local Test Setup with Detailed Logging ==="
log "Log file: $LOG_FILE"

# Pre-flight checks
check_docker
check_resources

# Create shared network
log "Step 0: Creating shared network..."
if docker network inspect pg_network_test >/dev/null 2>&1; then
    log "INFO: Network 'pg_network_test' already exists"
else
    run_with_log "docker network create pg_network_test" "Create Docker network"
fi

# Stop any existing containers
log "Step 1: Stopping existing containers..."
run_with_log "docker-compose -f docker-compose.monitor.yml down --remove-orphans" "Stop monitor containers" || true
run_with_log "docker-compose -f docker-compose.db1.yml down --remove-orphans" "Stop DB1 containers" || true
run_with_log "docker-compose -f docker-compose.db2.yml down --remove-orphans" "Stop DB2 containers" || true

# Check for existing volumes
log "Checking existing volumes..."
for volume in pg_monitor_data_test postgres_db1_data_test postgres_db2_data_test; do
    if docker volume inspect "$volume" >/dev/null 2>&1; then
        log "INFO: Volume '$volume' already exists (will reuse)"
    else
        log "INFO: Volume '$volume' does not exist (will be created)"
    fi
done

# Start Monitor Server
log "Step 2: Starting Monitor Server..."
run_with_log "docker-compose -f docker-compose.monitor.yml up -d" "Start monitor server"

# Wait for monitor to be healthy
wait_for_health "pg-monitor-test" 120 || {
    log "ERROR: Monitor server failed to start properly"
    collect_logs "pg-monitor-test" "MONITOR"
    exit 1
}

collect_logs "pg-monitor-test" "MONITOR"

# Start DB1 Server (Primary)
log "Step 3: Starting DB1 Server (Primary)..."
run_with_log "docker-compose -f docker-compose.db1.yml up -d" "Start DB1 server"

# Wait for DB1 to be healthy
wait_for_health "postgres-db1-test" 180 || {
    log "ERROR: DB1 server failed to start properly"
    collect_logs "postgres-db1-test" "DB1"
    exit 1
}

collect_logs "postgres-db1-test" "DB1"

# Start DB2 Server (Secondary)
log "Step 4: Starting DB2 Server (Secondary)..."
run_with_log "docker-compose -f docker-compose.db2.yml up -d" "Start DB2 server"

# Wait for DB2 to be healthy
wait_for_health "postgres-db2-test" 180 || {
    log "ERROR: DB2 server failed to start properly"
    collect_logs "postgres-db2-test" "DB2"
    exit 1
}

collect_logs "postgres-db2-test" "DB2"

# Additional wait for cluster formation
log "Step 5: Waiting for cluster formation..."
sleep 30

# Final verification
log "Step 6: Final verification and status check..."

# Check cluster state
log "Checking cluster state..."
if docker exec pg-monitor-test pg_autoctl show state --pgdata /var/lib/postgresql/data/monitor >> "$LOG_FILE" 2>&1; then
    log "SUCCESS: Cluster state retrieved successfully"
else
    log "WARNING: Failed to retrieve cluster state"
fi

# Check container status
log "Checking container status..."
for container in pg-monitor-test postgres-db1-test postgres-db2-test; do
    local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "unknown")
    local health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-health-check")
    log "INFO: Container '$container' - Status: $status, Health: $health"
done

# Check port accessibility
log "Checking port accessibility..."
for port in 5432 5433 5434; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        log "SUCCESS: Port $port is listening"
    else
        log "WARNING: Port $port is not accessible"
    fi
done

# Test database connections
log "Testing database connections..."

# Test monitor connection
if docker exec pg-monitor-test pg_isready -U autoctl_node -h localhost -p 5432 >> "$LOG_FILE" 2>&1; then
    log "SUCCESS: Monitor database connection test passed"
else
    log "WARNING: Monitor database connection test failed"
fi

# Test DB1 connection
if docker exec postgres-db1-test pg_isready -U postgres -h localhost -p 5432 >> "$LOG_FILE" 2>&1; then
    log "SUCCESS: DB1 database connection test passed"
else
    log "WARNING: DB1 database connection test failed"
fi

# Test DB2 connection
if docker exec postgres-db2-test pg_isready -U postgres -h localhost -p 5432 >> "$LOG_FILE" 2>&1; then
    log "SUCCESS: DB2 database connection test passed"
else
    log "WARNING: DB2 database connection test failed"
fi

# Get replication status
log "Checking replication status..."
echo "==================== REPLICATION STATUS ====================" >> "$LOG_FILE"
docker exec postgres-db1-test psql -U postgres -d appdb -c "SELECT * FROM pg_stat_replication;" >> "$LOG_FILE" 2>&1 || log "WARNING: Failed to get replication status from DB1"
docker exec postgres-db2-test psql -U postgres -d postgres -c "SELECT pg_is_in_recovery();" >> "$LOG_FILE" 2>&1 || log "WARNING: Failed to check recovery status on DB2"
echo "================= END REPLICATION STATUS ===================" >> "$LOG_FILE"

log "=== Setup Complete ==="
log ""
log "Services running:"
log "  Monitor: localhost:5432"
log "  Primary DB (DB1): localhost:5433"
log "  Secondary DB (DB2): localhost:5434"
log ""
log "Container names:"
log "  Monitor: pg-monitor-test"
log "  DB1: postgres-db1-test"
log "  DB2: postgres-db2-test"
log ""
log "Log file location: $LOG_FILE"
log ""
log "Useful commands:"
log "  # Check cluster status"
log "  docker exec pg-monitor-test pg_autoctl show state"
log ""
log "  # Check logs"
log "  docker logs pg-monitor-test"
log "  docker logs postgres-db1-test"
log "  docker logs postgres-db2-test"
log ""
log "  # View setup logs"
log "  cat $LOG_FILE"
log ""
log "  # Perform manual failover"
log "  docker exec pg-monitor-test pg_autoctl perform failover"
log ""
log "  # Connect to databases"
log "  docker exec -it postgres-db1-test psql -U postgres -d appdb"
log "  docker exec -it postgres-db2-test psql -U postgres -d appdb"
log ""
log "  # Stop all services"
log "  ./stop-local-test.sh"

echo ""
echo "Setup completed! Check the log file for detailed information:"
echo "  tail -f $LOG_FILE"