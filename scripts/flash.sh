#!/bin/sh

DIR="$( cd "$( dirname "$0" )" && pwd )"
cd $DIR

echo "Entering bootloader mode..."
./bootloader.py
echo "Programming..."

until lpc21isp $1 /dev/ttyS0 115200 12000
do
    echo "Retrying in 5..."
    sleep 5
done
