#!/bin/bash

# Stop Local Test Script for PostgreSQL Auto-Failover

set -e

echo "=== Stopping PostgreSQL Auto-Failover Local Test ==="

# Stop all containers
echo "Stopping all containers..."
docker-compose -f docker-compose.db2.yml down --remove-orphans
docker-compose -f docker-compose.db1.yml down --remove-orphans
docker-compose -f docker-compose.monitor.yml down --remove-orphans

# Remove network
echo "Removing network..."
docker network rm pg_network_test 2>/dev/null || echo "Network already removed"

echo "All services stopped successfully!"
echo ""
echo "To clean up volumes (data will be lost):"
echo "  docker volume rm pg_monitor_data_test postgres_db1_data_test postgres_db2_data_test"