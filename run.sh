#!/bin/bash
# Auto-detects your current LAN IP and injects it as the API base URL.
# Usage:
#   ./run.sh          → flutter run (debug, auto IP)
#   ./run.sh build    → flutter build apk (release, auto IP)
#   ./run.sh adb      → sets up ADB reverse then flutter run (USB cable, no IP needed)

set -e

case "${1:-run}" in
  adb)
    echo "Setting up ADB reverse tunnel..."
    adb reverse tcp:8000 tcp:8000
    echo "Tunnel active: phone localhost:8000 → this machine :8000"
    flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
    ;;
  build)
    IP=$(hostname -I | awk '{print $1}')
    echo "Building with API: http://$IP:8000/api"
    flutter build apk --dart-define=API_BASE_URL=http://$IP:8000/api
    ;;
  *)
    IP=$(hostname -I | awk '{print $1}')
    echo "Running with API: http://$IP:8000/api"
    flutter run --dart-define=API_BASE_URL=http://$IP:8000/api
    ;;
esac
