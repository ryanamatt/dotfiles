#!/bin/bash

# Script to get the battery of my Razer Mouse

CHARGE=$(razer-cli -l | grep -A 1 "battery:" | grep "charge:" | awk '{print $2}')

if [ -z "$CHARGE" ]; then
    echo "Could not retrieve battery level. Is the mouse connected?"
else
    echo "Mouse battery: ${CHARGE}%"
fi
