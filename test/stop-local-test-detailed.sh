#!/bin/bash

# Stop Local Test Script for PostgreSQL Auto-Failover with Detailed Logging

set -e

# Setup logging
LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/pg-auto-failover-stop-$(date +%Y%m%d_%H%M%S).log"
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
        log "WARNING: $description failed with exit code $exit_code (continuing...)"
        return $exit_code
    fi
}

# Function to collect final logs before stopping
collect_final_logs() {
    log "Collecting final logs from all containers..."
    
    for container in pg-monitor-test postgres-db1-test postgres-db2-test; do
        if docker ps -q -f name="$container" >/dev/null 2>&1; then
            log "Collecting final logs from $container..."
            echo "==================== FINAL $container LOGS ====================" >> "$LOG_FILE"
            docker logs --tail=50 "$container" >> "$LOG_FILE" 2>&1 || log "WARNING: Failed to collect logs from $container"
            echo "================= END FINAL $container LOGS ===================" >> "$LOG_FILE"
        else
            log "INFO: Container $container is not running"
        fi
    done
}

# Function to check container status
check_container_status() {
    log "Checking container status before shutdown..."
    
    for container in pg-monitor-test postgres-db1-test postgres-db2-test; do
        if docker ps -q -f name="$container" >/dev/null 2>&1; then
            local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "unknown")
            local uptime=$(docker inspect --format='{{.State.StartedAt}}' "$container" 2>/dev/null || echo "unknown")
            log "INFO: Container '$container' - Status: $status, Started: $uptime"
        else
            log "INFO: Container '$container' is not running"
        fi
    done
}

# Function to get cluster state before shutdown
get_final_cluster_state() {
    log "Getting final cluster state before shutdown..."
    
    if docker ps -q -f name="pg-monitor-test" >/dev/null 2>&1; then
        echo "==================== FINAL CLUSTER STATE ====================" >> "$LOG_FILE"
        docker exec pg-monitor-test pg_autoctl show state --pgdata /var/lib/postgresql/data/monitor >> "$LOG_FILE" 2>&1 || log "WARNING: Failed to get final cluster state"
        echo "================= END FINAL CLUSTER STATE ===================" >> "$LOG_FILE"
    else
        log "INFO: Monitor container is not running, cannot get cluster state"
    fi
}

# Function to gracefully stop containers
graceful_stop() {
    local compose_file="$1"
    local service_name="$2"
    
    log "Gracefully stopping $service_name..."
    
    # Try graceful stop first
    if run_with_log "docker-compose -f $compose_file stop --timeout 30" "Graceful stop of $service_name"; then
        log "SUCCESS: $service_name stopped gracefully"
    else
        log "WARNING: Graceful stop failed for $service_name, forcing stop..."
        run_with_log "docker-compose -f $compose_file kill" "Force kill $service_name" || true
    fi
    
    # Remove containers
    run_with_log "docker-compose -f $compose_file down --remove-orphans" "Remove $service_name containers" || true
}

# Main execution starts here
log "=== PostgreSQL Auto-Failover Local Test Shutdown with Detailed Logging ==="
log "Log file: $LOG_FILE"

# Pre-shutdown checks
check_container_status
get_final_cluster_state
collect_final_logs

# Stop containers in reverse order (DB2 -> DB1 -> Monitor)
log "Step 1: Stopping DB2 Server (Secondary)..."
graceful_stop "docker-compose.db2.yml" "DB2"

log "Step 2: Stopping DB1 Server (Primary)..."
graceful_stop "docker-compose.db1.yml" "DB1"

log "Step 3: Stopping Monitor Server..."
graceful_stop "docker-compose.monitor.yml" "Monitor"

# Check if any containers are still running
log "Step 4: Checking for remaining containers..."
remaining_containers=$(docker ps -q -f name="pg-monitor-test" -f name="postgres-db1-test" -f name="postgres-db2-test" 2>/dev/null || echo "")
if [ -n "$remaining_containers" ]; then
    log "WARNING: Some containers are still running, forcing removal..."
    echo "$remaining_containers" | xargs docker kill >> "$LOG_FILE" 2>&1 || true
    echo "$remaining_containers" | xargs docker rm >> "$LOG_FILE" 2>&1 || true
else
    log "SUCCESS: All containers have been stopped"
fi

# Remove network
log "Step 5: Removing network..."
if docker network inspect pg_network_test >/dev/null 2>&1; then
    run_with_log "docker network rm pg_network_test" "Remove Docker network" || log "WARNING: Failed to remove network (may still be in use)"
else
    log "INFO: Network 'pg_network_test' does not exist"
fi

# Check volumes
log "Step 6: Checking volumes..."
for volume in pg_monitor_data_test postgres_db1_data_test postgres_db2_data_test; do
    if docker volume inspect "$volume" >/dev/null 2>&1; then
        local size=$(docker system df -v | grep "$volume" | awk '{print $3}' || echo "unknown")
        log "INFO: Volume '$volume' exists (size: $size) - preserved for next run"
    else
        log "INFO: Volume '$volume' does not exist"
    fi
done

# Final system check
log "Step 7: Final system check..."
local running_pg_containers=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(postgres|pg-)" || echo "none")
log "INFO: Remaining PostgreSQL-related containers:"
echo "$running_pg_containers" >> "$LOG_FILE"

# Check port status
log "Checking port status after shutdown..."
for port in 5432 5433 5434; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        log "WARNING: Port $port is still in use"
    else
        log "SUCCESS: Port $port is free"
    fi
done

log "=== Shutdown Complete ==="
log ""
log "All PostgreSQL Auto-Failover services have been stopped!"
log ""
log "Data volumes preserved:"
log "  - pg_monitor_data_test"
log "  - postgres_db1_data_test"
log "  - postgres_db2_data_test"
log ""
log "To completely clean up (data will be lost):"
log "  docker volume rm pg_monitor_data_test postgres_db1_data_test postgres_db2_data_test"
log ""
log "To restart the services:"
log "  ./run-local-test-detailed.sh"
log ""
log "Log file location: $LOG_FILE"

echo ""
echo "Shutdown completed! Check the log file for detailed information:"
echo "  cat $LOG_FILE"