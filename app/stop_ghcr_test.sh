#!/bin/bash

echo "═══════════════════════════════════════════════════"
echo "Stopping PDC Docker Test (GHCR Images)"
echo "═══════════════════════════════════════════════════"
echo ""

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$APP_DIR"

# Stop Docker containers
echo "Stopping Docker containers..."
echo "────────────────────────────────────────────────────"
docker-compose -f docker-compose.ghcr.yml down
echo "✅ Docker containers stopped"
echo ""

# Kill native processes
echo "Stopping native processes..."
echo "────────────────────────────────────────────────────"
pkill -f VehicleControlMock 2>/dev/null && echo "✅ VehicleControlMock stopped" || echo "⚠️  VehicleControlMock was not running"
pkill -f RemoteSpeakerApp 2>/dev/null && echo "✅ RemoteSpeakerApp stopped" || echo "⚠️  RemoteSpeakerApp was not running"
echo ""

# Clean runtime directory
echo "Cleaning runtime directory..."
echo "────────────────────────────────────────────────────"
if [ -d "/tmp/runtime-root" ]; then
    sudo rm -rf /tmp/runtime-root
    echo "✅ Runtime directory cleaned"
else
    echo "⚠️  Runtime directory not found"
fi
echo ""

echo "═══════════════════════════════════════════════════"
echo "✅ All stopped!"
echo "═══════════════════════════════════════════════════"
