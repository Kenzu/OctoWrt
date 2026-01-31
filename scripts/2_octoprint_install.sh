#!/bin/sh

tag="main";

if mount | grep "/dev/mmcblk0p2 on /overlay type ext4" > /dev/null; then

echo " "
echo " "
echo " "
echo "This script will download and install ALL packages from the internet"
echo " "
echo "   ######################################################"
echo "   ## Make sure you have a stable internet connection! ##"
echo "   ######################################################"
echo " "
read -p "Press [ENTER] to Continue ...or [ctrl+c] to exit"

echo " "
echo "   ###############################"
echo "   ### Installing dependencies ###"
echo "   ###############################"
echo " "

opkg update
opkg install --force-overwrite gcc;
opkg install make unzip htop wget-ssl git-http kmod-video-uvc luci-app-mjpg-streamer v4l-utils mjpg-streamer-input-uvc mjpg-streamer-output-http mjpg-streamer-www ffmpeg
opkg install python3 python3-pip python3-dev python3-netifaces python3-markupsafe python3-zeroconf

wget -q https://raw.githubusercontent.com/shivajiva101/KlipperWrt/v4.4/python/python3-pillow_10.1.0-r1_mipsel_24kc.ipk
opkg install /root/python3-pillow_10.1.0-r1_mipsel_24kc.ipk

pip install --upgrade setuptools
pip install --upgrade pip

echo "Fetching wheels..."
mkdir python_wheels
cd python_wheels
wget https://raw.githubusercontent.com/Kenzu/OctoWrt/$tag/python/python_wheels/Archive.tar.gz
tar -xzf Archive.tar.gz
cd ~
wget https://raw.githubusercontent.com/Kenzu/OctoWrt/$tag/scripts/pdeps.txt

echo "Installing wheels..."
pip install -r pdeps.txt;

echo " "
echo "   ############################"
echo "   ### Installing Octoprint ###"
echo "   ############################"
echo " "
echo " This is going to take about 35-40 minutes... "
echo " "

echo "Cloning source..."
git clone --depth 1 -b 1.10.3 https://github.com/OctoPrint/OctoPrint.git src
cd src
echo "Patching source..."
wget https://github.com/Kenzu/OctoWrt/raw/$tag/octoprint/openwrt.patch
git apply openwrt.patch

echo "Starting pip install..."
pip install .
cd ~

echo " "
echo "   ###################"
echo "   ### Hostname/ip ###"
echo "   ###################"
echo " "

opkg install avahi-daemon-service-ssh avahi-daemon-service-http;

echo " "
echo "   ##################################"
echo "   ### Creating Octoprint service ###"
echo "   ##################################"
echo " "

rm -f /etc/init.d/octoprint
cat << "EOF" > /etc/init.d/octoprint
#!/bin/sh /etc/rc.common
# Copyright (C) 2009-2014 OpenWrt.org
# Put this inside /etc/init.d/

START=91
STOP=10
USE_PROCD=1


start_service() {
    procd_open_instance
    procd_set_param command octoprint serve --iknowwhatimdoing
    procd_set_param respawn
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}
EOF

chmod +x /etc/init.d/octoprint
/etc/init.d/octoprint enable

echo " "
echo "   ##################################"
echo "   ### Reboot and wait a while... ###"
echo "   ##################################"
echo " "
read -p "Press [ENTER] to reboot...or [ctrl+c] to exit"

reboot

else
echo "Run the first script before attempting to run this one!"
fi
