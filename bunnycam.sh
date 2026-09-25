#!/bin/bash
podman start ring-mqtt
cd ~/home
pkill go2rtc; sleep 1
./go2rtc -c go2rtc.yaml &
sleep 15
google-chrome --app=file:///home/cait/home/bunnycam.html --window-size=660,420
