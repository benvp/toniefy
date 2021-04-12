#!/bin/bash

echo "Starting pulseaudio..."

pulseaudio -D --exit-idle-time=-1 --system --disallow-exit

echo "✅ Ready."
echo "Starting recorder..."

xvfb-run mix record
