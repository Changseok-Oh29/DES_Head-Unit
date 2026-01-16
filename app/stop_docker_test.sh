#!/bin/bash

echo "═══════════════════════════════════════════════════"
echo "Stopping PDC Docker Integration Test"
echo "═══════════════════════════════════════════════════"

# Stop Docker containers
cd "$(dirname "$0")"
docker-compose -f docker-compose.all.yml down

# Stop VehicleControlMock (if running)
if pgrep -f "VehicleControlMock" > /dev/null; then
    echo "Stopping VehicleControlMock..."
    pkill -f "VehicleControlMock"
fi

# Stop RemoteSpeakerApp (if running)
if pgrep -f "RemoteSpeakerApp" > /dev/null; then
    echo "Stopping RemoteSpeakerApp..."
    pkill -f "RemoteSpeakerApp"
fi

# Clean up PID files (legacy)
rm -f /tmp/vehiclecontrolmock.pid
rm -f /tmp/remotespeakerapp.pid

echo "All apps stopped!"
