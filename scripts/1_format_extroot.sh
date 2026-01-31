#!/bin/sh

# Script: Format external root (extroot) and setup swap on mmcblk0
# This version adds echo statements to explain each step as it runs.

DISK="/dev/mmcblk0";

echo "Step 1: Updating opkg package lists...";
opkg update;

echo "Step 2: Installing required packages: block-mount, kmod-fs-ext4, e2fsprogs, parted...";
opkg install block-mount kmod-fs-ext4 e2fsprogs parted;

echo "Step 3: Creating a new GPT partition table on ${DISK}...";
# Create GPT label (this will destroy existing partition table)
parted -s ${DISK} -- mklabel gpt;

echo "Step 4: Creating a swap partition (start: 2048s, size: 256M) on ${DISK}...";
# Create swap partition (p1)
parted -s ${DISK} -- mkpart swap 2048s 256M;

echo "Step 5: Creating extroot partition (from 256M to end of disk) on ${DISK}...";
# Create extroot partition (p2)
parted -s ${DISK} -- mkpart extroot 256M 100%;

SWAP="${DISK}p1";
DEVICE="${DISK}p2";

echo "Step 6: Formatting the swap partition ${SWAP}...";
mkswap ${SWAP};

echo "Step 7: Formatting the extroot partition ${DEVICE} as ext4 and labeling it 'extroot'...";
mkfs.ext4 -L extroot ${DEVICE};

echo "Step 8: Reading UUID for ${DEVICE} from block info...";
# Extract UUID="..." string and evaluate so UUID variable is exported in the script environment
eval $(block info ${DEVICE} | grep -o -e 'UUID="\S*"');

# Confirm we found a UUID
echo "Found device UUID: ${UUID}";

echo "Step 9: Finding current overlay mount point from block info...";
# Extract MOUNT="/path/to/overlay"
eval $(block info | grep -o -e 'MOUNT="\S*/overlay"');

# Confirm we found an overlay mount path
echo "Detected overlay mount point: ${MOUNT}";

echo "Step 10: Updating UCI fstab configuration to use new extroot and enable swap...";
# Remove any existing extroot fstab entry then create a new one pointing by UUID
uci -q delete fstab.extroot;
uci set fstab.extroot="mount";
uci set fstab.extroot.uuid="${UUID}";
uci set fstab.extroot.target="${MOUNT}";

echo "Adding swap entry to fstab and enabling it...";
uci add fstab swap;
uci set fstab.@swap[-1].enabled="1";
uci set fstab.@swap[-1].device="${SWAP}";

echo "Committing fstab changes...";
u ci commit fstab;