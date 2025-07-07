#!/bin/bash

# Local Test Script for PostgreSQL Auto-Failover
# This script runs all three services on a single machine

set -e

echo "=== PostgreSQL Auto-Failover Local Test Setup ==="

# Create shared network first
echo "Creating shared network..."
docker network create pg_network_test 2>/dev/null || echo "Network already exists"

# Stop any existing containers
echo "Stopping existing containers..."
docker-compose -f docker-compose.monitor.yml down --remove-orphans 2>/dev/null || true
docker-compose -f docker-compose.db1.yml down --remove-orphans 2>/dev/null || true
docker-compose -f docker-compose.db2.yml down --remove-orphans 2>/dev/null || true

# Remove old volumes (uncomment for fresh start)
# docker volume rm postgres_monitor_data_test postgres_db1_data_test postgres_db2_data_test 2>/dev/null || true

# Start Monitor Server
echo "Step 1: Starting Monitor Server..."
docker-compose -f docker-compose.monitor.yml up -d
echo "Waiting for monitor to be ready..."
sleep 30

# Start DB1 Server (Primary)
echo "Step 2: Starting DB1 Server (Primary)..."
docker-compose -f docker-compose.db1.yml up -d
echo "Waiting for DB1 to be ready..."
sleep 30

# Start DB2 Server (Secondary)
echo "Step 3: Starting DB2 Server (Secondary)..."
docker-compose -f docker-compose.db2.yml up -d
echo "Waiting for DB2 to be ready..."
sleep 30

# Final verification
echo "Step 4: Verification..."
echo "Checking cluster status..."
docker exec pg-monitor-test pg_autoctl show state --pgdata /var/lib/postgresql/data/monitor || true

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Services running:"
echo "  Monitor: localhost:5432"
echo "  Primary DB (DB1): localhost:5433"
echo "  Secondary DB (DB2): localhost:5434"
echo ""
echo "Container names:"
echo "  Monitor: pg-monitor-test"
echo "  DB1: postgres-db1-test"  
echo "  DB2: postgres-db2-test"
echo ""
echo "Useful commands:"
echo "  # Check cluster status"
echo "  docker exec pg-monitor-test pg_autoctl show state"
echo ""
echo "  # Check logs"
echo "  docker logs pg-monitor-test"
echo "  docker logs postgres-db1-test"
echo "  docker logs postgres-db2-test"
echo ""
echo "  # Perform manual failover"
echo "  docker exec pg-monitor-test pg_autoctl perform failover"
echo ""
echo "  # Connect to databases"
echo "  docker exec -it postgres-db1-test psql -U postgres -d appdb"
echo "  docker exec -it postgres-db2-test psql -U postgres -d appdb"
echo ""
echo "  # Stop all services"
echo "  ./stop-local-test.sh"