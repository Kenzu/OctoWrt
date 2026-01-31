#!/bin/sh
DISK="/dev/mmcblk0";
opkg update;
opkg install block-mount kmod-fs-ext4 e2fsprogs parted;
parted -s ${DISK} -- mklabel gpt;
parted -s ${DISK} -- mkpart swap 2048s 256M;
parted -s ${DISK} -- mkpart extroot 256M 100%;
SWAP="${DISK}p1";
DEVICE="${DISK}p2";
mkswap ${SWAP};
mkfs.ext4 -L extroot ${DEVICE};
eval $(block info ${DEVICE} | grep -o -e 'UUID="\S*"');
eval $(block info | grep -o -e 'MOUNT="\S*/overlay"');
uci -q delete fstab.extroot;
uci set fstab.extroot="mount";
uci set fstab.extroot.uuid="${UUID}";
uci set fstab.extroot.target="${MOUNT}";
uci commit fstab;
mount ${DEVICE} /mnt;
tar -C ${MOUNT} -cvf - . | tar -C /mnt -xf -;
echo "Updating rc.local for swap"
rm /etc/rc.local;
cat << "EOF" > /etc/rc.local
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.
###activate the swap file on the SD card
swapon ${SWAP}
###expand /tmp space
mount -o remount,size=128M /tmp
exit 0
EOF;
reboot;
