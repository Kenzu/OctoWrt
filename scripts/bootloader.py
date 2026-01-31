#!/usr/bin/python
import mraa
import time

RESET = mraa.Gpio(37);
RESET.dir(mraa.DIR_OUT);
BOOTLOADER = mraa.Gpio(17);
BOOTLOADER.dir(mraa.DIR_OUT);

print("PREPARING");
RESET.write(1);
BOOTLOADER.write(1);

time.sleep(2);
print("PUSHING RESET");
RESET.write(0);

time.sleep(2);
print("PUSHING BOOTLOADER");
BOOTLOADER.write(0);

time.sleep(2);
print("RELEASING RESET");
RESET.write(1);

time.sleep(2);
print("RELEASING BOOTLOADER");
BOOTLOADER.write(1);

time.sleep(2);
