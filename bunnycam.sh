#!/bin/bash
echo "starting process..."
podman start ring-mqtt
echo "going into directory..."
cd ~/home
echo "restarting go2rtc to clear old windows..."
pkill go2rtc; sleep 1
./go2rtc -c go2rtc.yaml &
sleep 15
echo "starting window..."
google-chrome --app=file:///home/cait/home/bunnycam.html --window-size=660,420
echo "window opened."