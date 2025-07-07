#!/bin/bash

# Monitor Server Setup Script
# This script should be run on the monitor server

set -e

echo "Starting pg_auto_failover Monitor Server..."

# Check if docker-compose.monitor.yml exists
if [ ! -f "docker-compose.monitor.yml" ]; then
    echo "Error: docker-compose.monitor.yml not found"
    exit 1
fi

# Stop any existing containers
echo "Stopping existing containers..."
docker-compose -f docker-compose.monitor.yml down --remove-orphans

# Remove old volumes if needed (uncomment for fresh start)
# docker volume rm pg-auto-failover_pg_monitor_data 2>/dev/null || true

# Start monitor server
echo "Starting monitor server..."
docker-compose -f docker-compose.monitor.yml up -d

# Wait for monitor to be healthy
echo "Waiting for monitor to be ready..."
timeout=300
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker-compose -f docker-compose.monitor.yml ps | grep -q "healthy"; then
        echo "Monitor server is ready!"
        break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
    echo "Waiting... ($elapsed/$timeout seconds)"
done

if [ $elapsed -ge $timeout ]; then
    echo "Error: Monitor server failed to start within $timeout seconds"
    exit 1
fi

# Show monitor logs
echo "Monitor server logs:"
docker-compose -f docker-compose.monitor.yml logs --tail=20

echo "Monitor server setup completed successfully!"
echo "Monitor is running on port 5432"