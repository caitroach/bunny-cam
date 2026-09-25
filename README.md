## what is this?
(a center for ants???) 

I'm away at university right now and I miss my two bunnies very much. We have a Ring camera set up to check on them, so sometimes in class I'll sneakily open my phone and watch them nap, snack, and flop. Phones aren't very discreet, though, so I made an always-on-top window that lives at the corner of my screen and shows me what they're up to at all times, which starts up automatically on login.

<img width="2877" height="1797" alt="ye" src="https://github.com/user-attachments/assets/09cb2b54-4c6f-4aba-85ca-ab8bdd8ace89" />


## how it works 
This uses Ring-MQTT, an open-source bridge that connects Ring cameras and doorbells to local applications. mosquitto is the MQTT broker that Ring-MQTT needs to run. 

1. First, Ring-MQTT logs into Ring and turns the camera feed into an RTSP stream.
2. Then go2rtc converts RTSP into something a browser can actually play.
3. Google Chrome uses bunnycam.html to display the footage.
4. bunnycam.sh starts everything, and if you configure your Autostart settings, you can boot it up automatically at login.

## setup from scratch
1. Install stuff. Run:
   ```
   sudo dnf install mosquitto mpv chromium
   sudo systemctl enable --now mosquitto
   ```
   
2. Make `~/home/ring-data/config.json`:
   ```
   {
     "mqtt_url": "mqtt://localhost:1883",
     "livestream_user": "",
     "livestream_pass": "",
     "disarm_code": "",
     "enable_cameras": true,
     "enable_modes": false,
     "enable_panic": false,
     "hass_topic": "homeassistant/status",
     "ring_topic": "ring",
     "location_ids": [] 
   }
   ```
3. Run ring-mqtt
   `podman run -d --name ring-mqtt --network host -v ~/home/ring-data:/data:Z docker.io/tsightler/ring-mqtt`

4. Log into Ring at http://localhost:55123 (one time only!)
5. Find the camera id
   `podman logs ring-mqtt | grep -o "camera/[a-f0-9]*" | sort -u`
6. Test your stream link by running `mpv rtsp://localhost:8554/<CAMERA_ID>_live`
7. Set up go2rtc
   ```
   cd home
   wget https://github.com/AlexxIT/go2rtc/releases/latest/download/go2rtc_linux_amd64 -O go2rtc
   chmod +x go2rtc
   ```
   Then edit go2rtc.yaml:
   ```
   streams:
     bunnies: rtsp://localhost:8554/<CAMERA_ID>_live
   api:
     listen: "127.0.0.1:1984"
   rtsp:
     listen: "" (this is super important because it stops go2rtc from stealing port 8554 from ring-
     mqtt which will break your entire thing lolol)
   ```
8. Point the page at go2rtc in bunnycam.html:
   `const STREAM_URL = "http://localhost:1984/stream.html?src=bunnies&mode=webrtc";`
9. Make a startup script:
   ```
      #!/bin/bash
   podman start ring-mqtt
   cd ~/home
   pkill go2rtc; sleep 1
   ./go2rtc -c go2rtc.yaml &
   sleep 15
   chromium-browser --app=file:///home/[your name]/home/bunnycam.html --window-size=340,220 
   ```
   you can also use google-chrome in place of chromium-browser if that gives you issues.
  Add that script in System Settings -> Autostart -> Add Login Script.
10. Make the KDE window rule so it stays on top. to make it cute, hide the border in this menu!!

## controls
- *How do I move it?* = meta + left-drag
- *How do I resize it?* = meta + right-drag
- *How do I minimize it?* = meta + pgdown, or click its taskbar icon
- *How do I get rid of it?* = press the cute X button or Alt+F4
- *How do I change the reaction bubble?* = press on it

## troubleshooting
- *The stream isn't loading. Why is it broken?* = Ctrl+R until it works
- *No configuration file found* = Make ring-data/config.json, then run `podman start ring-mqtt`.
- *404 not found on DESCRIBE* = Add `rtsp: listen: "",` then `pkill go2rtc` then `podman restart ring-mqtt`
- *Connection refused* = Wait
- *1984: address already in use* = `pkill go2rtc`
- *My window opens in the middle and ignores my special script!* = just fix it in KDE window rules
- *chromium-browser: command not found* = `sudo dnf install chromium` or just switch to chrome

## warnings 
- While the window is open, bunny cam won't send motion alerts. Close the window if you need them.
- The window is always on top so close it if you're in a zoom call...
- audio is streamed by default even though the page is muted.
- Battery cams drain fast af while streaming, so i'd only really do this with a wired camera.
- Keep ring-data private if you don't want random people spying on you.
- If you care about people on the same WiFi stealing your key, set livestream_user and livestream_pass and block them in firewalld like this:
  ```
    sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-rich-rule='rule port port="8554" protocol="tcp" reject'
  sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-rich-rule='rule port port="55123" protocol="tcp" reject'
  sudo firewall-cmd --reload
  ```

feel free to fork and fix it. 

made with <3 for bill and chippy
 
