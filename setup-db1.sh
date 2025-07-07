#!/bin/bash

# DB1 Server Setup Script (Primary Database)
# This script should be run on the first database server

set -e

MONITOR_IP="10.164.32.93"  # Update this with actual monitor server IP

echo "Starting pg_auto_failover DB1 Server (Primary)..."

# Check if docker-compose.db1.yml exists
if [ ! -f "docker-compose.db1.yml" ]; then
    echo "Error: docker-compose.db1.yml not found"
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
docker-compose -f docker-compose.db1.yml down --remove-orphans

# Remove old volumes if needed (uncomment for fresh start)
# docker volume rm pg-auto-failover_postgres_data 2>/dev/null || true

# Start DB1 server
echo "Starting DB1 server..."
docker-compose -f docker-compose.db1.yml up -d

# Wait for DB1 to be healthy
echo "Waiting for DB1 to be ready..."
timeout=300
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker-compose -f docker-compose.db1.yml ps | grep -q "healthy"; then
        echo "DB1 server is ready!"
        break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
    echo "Waiting... ($elapsed/$timeout seconds)"
done

if [ $elapsed -ge $timeout ]; then
    echo "Error: DB1 server failed to start within $timeout seconds"
    exit 1
fi

# Show DB1 logs
echo "DB1 server logs:"
docker-compose -f docker-compose.db1.yml logs --tail=20

# Check registration with monitor
echo "Checking DB1 registration with monitor..."
sleep 10
docker exec postgres psql -U postgres -d appdb -c "SELECT * FROM pg_stat_replication;" || true

echo "DB1 server setup completed successfully!"
echo "DB1 is running on port 5432 as PRIMARY node"