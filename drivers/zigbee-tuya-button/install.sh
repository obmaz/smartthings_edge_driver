#!/bin/bash
set -euo pipefail

# DEV
# https://bestow-regional.api.smartthings.com/invite/BxlrxQ835YMP 

# PRD
#  https://bestow-regional.api.smartthings.com/invite/Q1jPbWZXad2L

driverId=95b94182-0102-47ce-acef-553cbd8aa6d6
hub=b5434d2c-cd4e-4bde-a91b-d419ee72c55e
hub_address=192.168.10.189

target="${1:-dev}"
case "$target" in
  dev) channel=715733f3-8cac-451d-8164-a3ae65a4a7cd ;;
  prd) channel=699fefe6-7b99-40b2-acfd-662ed510a84d ;;
  *)
    echo "Usage: $0 [dev|prd]" >&2
    exit 2
    ;;
esac

echo "Deploy target: $target"
echo "Channel ID:    $channel"

# smartthings edge:drivers:uninstall "$driverId" --hub "$hub"
smartthings edge:drivers:package ./ --channel "$channel" --hub "$hub"
smartthings edge:channels:assign "$driverId" --channel "$channel"
smartthings edge:drivers:install "$driverId" --channel "$channel" --hub "$hub"
smartthings edge:drivers:logcat "$driverId" --hub-address="$hub_address"
