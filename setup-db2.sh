#!/bin/bash

# DB2 Server Setup Script (Secondary Database)
# This script should be run on the second database server

set -e

MONITOR_IP="10.164.32.93"  # Update this with actual monitor server IP

echo "Starting pg_auto_failover DB2 Server (Secondary)..."

# Check if docker-compose.db2.yml exists
if [ ! -f "docker-compose.db2.yml" ]; then
    echo "Error: docker-compose.db2.yml not found"
    exit 1
fi

# Check if monitor is accessible
echo "Checking monitor server connectivity..."
if ! nc -z "$MONITOR_IP" 5432; then
    echo "Error: Cannot connect to monitor server at $MONITOR_IP:5432"
    echo "Please ensure monitor server is running first"
    exit 1
fi

# Stop any existing containers
echo "Stopping existing containers..."
docker-compose -f docker-compose.db2.yml down --remove-orphans

# Remove old volumes if needed (uncomment for fresh start)
# docker volume rm pg-auto-failover_postgres_data 2>/dev/null || true

# Start DB2 server
echo "Starting DB2 server..."
docker-compose -f docker-compose.db2.yml up -d

# Wait for DB2 to be healthy
echo "Waiting for DB2 to be ready..."
timeout=300
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker-compose -f docker-compose.db2.yml ps | grep -q "healthy"; then
        echo "DB2 server is ready!"
        break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
    echo "Waiting... ($elapsed/$timeout seconds)"
done

if [ $elapsed -ge $timeout ]; then
    echo "Error: DB2 server failed to start within $timeout seconds"
    exit 1
fi

# Show DB2 logs
echo "DB2 server logs:"
docker-compose -f docker-compose.db2.yml logs --tail=20

# Check registration with monitor
echo "Checking DB2 registration with monitor..."
sleep 10
docker exec postgres psql -U postgres -d postgres -c "SELECT pg_is_in_recovery();" || true

echo "DB2 server setup completed successfully!"
echo "DB2 is running on port 5432 as SECONDARY node"
