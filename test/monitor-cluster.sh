#!/bin/bash

# Cluster Monitoring Script for PostgreSQL Auto-Failover
# This script continuously monitors the cluster status and logs changes

set -e

# Setup logging
LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/cluster-monitor-$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$LOG_DIR"

# Configuration
MONITOR_INTERVAL=10  # seconds
MAX_ITERATIONS=0     # 0 = infinite

# Function to log with timestamp
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Function to get cluster state
get_cluster_state() {
    if docker exec pg-monitor-test pg_autoctl show state --pgdata /var/lib/postgresql/data/monitor 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to get container health
get_container_health() {
    local container="$1"
    local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "not-found")
    local health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-health-check")
    echo "$status/$health"
}

# Function to get replication lag
get_replication_lag() {
    docker exec postgres-db1-test psql -U postgres -d appdb -t -c "SELECT COALESCE(EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp())), 0) AS lag_seconds;" 2>/dev/null | xargs || echo "unknown"
}

# Function to check database connectivity
check_db_connectivity() {
    local container="$1"
    local port="$2"
    
    if docker exec "$container" pg_isready -U postgres -h localhost -p "$port" >/dev/null 2>&1; then
        echo "✓"
    else
        echo "✗"
    fi
}

# Function to display status dashboard
display_dashboard() {
    local iteration="$1"
    
    clear
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "                    PostgreSQL Auto-Failover Cluster Monitor"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "Iteration: $iteration | Interval: ${MONITOR_INTERVAL}s | Log: $LOG_FILE"
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # Container Status
    echo "Container Status:"
    echo "┌─────────────────────┬──────────────┬────────────────┬──────────────────┐"
    echo "│ Container           │ Status       │ Health         │ Connectivity     │"
    echo "├─────────────────────┼──────────────┼────────────────┼──────────────────┤"
    
    local monitor_health=$(get_container_health "pg-monitor-test")
    local db1_health=$(get_container_health "postgres-db1-test")
    local db2_health=$(get_container_health "postgres-db2-test")
    
    local monitor_conn=$(check_db_connectivity "pg-monitor-test" "5432")
    local db1_conn=$(check_db_connectivity "postgres-db1-test" "5432")
    local db2_conn=$(check_db_connectivity "postgres-db2-test" "5432")
    
    printf "│ %-19s │ %-12s │ %-14s │ %-16s │\n" "pg-monitor-test" "${monitor_health%/*}" "${monitor_health#*/}" "$monitor_conn"
    printf "│ %-19s │ %-12s │ %-14s │ %-16s │\n" "postgres-db1-test" "${db1_health%/*}" "${db1_health#*/}" "$db1_conn"
    printf "│ %-19s │ %-12s │ %-14s │ %-16s │\n" "postgres-db2-test" "${db2_health%/*}" "${db2_health#*/}" "$db2_conn"
    echo "└─────────────────────┴──────────────┴────────────────┴──────────────────┘"
    echo ""
    
    # Port Status
    echo "Port Status:"
    echo "┌──────┬────────────┬─────────────────────────────────────────────────────────┐"
    echo "│ Port │ Status     │ Service                                                 │"
    echo "├──────┼────────────┼─────────────────────────────────────────────────────────┤"
    
    for port_info in "5432:Monitor" "5433:DB1 (Primary)" "5434:DB2 (Secondary)"; do
        local port="${port_info%:*}"
        local service="${port_info#*:}"
        local status="✗ Closed"
        
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            status="✓ Open"
        fi
        
        printf "│ %-4s │ %-10s │ %-55s │\n" "$port" "$status" "$service"
    done
    echo "└──────┴────────────┴─────────────────────────────────────────────────────────┘"
    echo ""
    
    # Cluster State
    echo "Cluster State:"
    echo "┌─────────────────────────────────────────────────────────────────────────────┐"
    local cluster_state=$(get_cluster_state 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "$cluster_state" | while IFS= read -r line; do
            printf "│ %-75s │\n" "$line"
        done
    else
        printf "│ %-75s │\n" "ERROR: Unable to retrieve cluster state"
    fi
    echo "└─────────────────────────────────────────────────────────────────────────────┘"
    echo ""
    
    # Replication Info
    echo "Replication Information:"
    echo "┌─────────────────────────────────────────────────────────────────────────────┐"
    
    # Get replication status from primary
    local repl_status=$(docker exec postgres-db1-test psql -U postgres -d appdb -t -c "SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn FROM pg_stat_replication;" 2>/dev/null | head -5)
    if [ -n "$repl_status" ] && [ "$repl_status" != "" ]; then
        echo "$repl_status" | while IFS= read -r line; do
            if [ -n "$line" ]; then
                printf "│ %-75s │\n" "$line"
            fi
        done
    else
        printf "│ %-75s │\n" "No active replication connections"
    fi
    
    # Check if DB2 is in recovery
    local recovery_status=$(docker exec postgres-db2-test psql -U postgres -d postgres -t -c "SELECT pg_is_in_recovery();" 2>/dev/null | xargs || echo "unknown")
    printf "│ %-75s │\n" "DB2 in recovery mode: $recovery_status"
    
    echo "└─────────────────────────────────────────────────────────────────────────────┘"
    echo ""
    
    echo "Commands: [Ctrl+C] Stop monitoring | [./stop-local-test-detailed.sh] Stop cluster"
    echo "═══════════════════════════════════════════════════════════════════════════════"
}

# Trap Ctrl+C
trap 'log "Monitoring stopped by user"; exit 0' INT

# Main monitoring loop
log "Starting cluster monitoring..."
log "Monitor interval: ${MONITOR_INTERVAL} seconds"
log "Max iterations: $([ $MAX_ITERATIONS -eq 0 ] && echo "infinite" || echo $MAX_ITERATIONS)"

iteration=1
while true; do
    # Log detailed status
    log "=== Monitoring Iteration $iteration ==="
    
    # Check if containers exist
    for container in pg-monitor-test postgres-db1-test postgres-db2-test; do
        if ! docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            log "ERROR: Container '$container' does not exist"
        fi
    done
    
    # Get and log cluster state
    log "Cluster state:"
    if cluster_state=$(get_cluster_state); then
        echo "$cluster_state" >> "$LOG_FILE"
    else
        log "ERROR: Failed to retrieve cluster state"
    fi
    
    # Log container health
    for container in pg-monitor-test postgres-db1-test postgres-db2-test; do
        local health=$(get_container_health "$container")
        log "Container $container: $health"
    done
    
    # Display dashboard
    display_dashboard "$iteration"
    
    # Check if we should stop
    if [ $MAX_ITERATIONS -gt 0 ] && [ $iteration -ge $MAX_ITERATIONS ]; then
        log "Reached maximum iterations ($MAX_ITERATIONS), stopping..."
        break
    fi
    
    # Wait for next iteration
    sleep "$MONITOR_INTERVAL"
    iteration=$((iteration + 1))
done

log "Monitoring completed"