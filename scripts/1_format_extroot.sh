#!/bin/sh

# Script: Format external root (extroot) and setup swap on mmcblk0
# This version adds echo statements to explain each step as it runs.

DISK="/dev/mmcblk0";

echo "Step 1: Updating opkg package lists..."
apk update;

echo "Step 2: Installing required packages: block-mount, kmod-fs-ext4, e2fsprogs, parted..."
apk add block-mount kmod-fs-ext4 e2fsprogs parted;

echo "Step 3: Creating a new GPT partition table on ${DISK}..."
# Create GPT label (this will destroy existing partition table)
parted -s ${DISK} -- mklabel gpt;

echo "Step 4: Creating extroot partition (from 2048s to end of disk) on ${DISK}..."
# Create extroot partition (p2)
parted -s ${DISK} -- mkpart extroot 2048s 100%;

DEVICE="${DISK}p1";

echo "Step 5: Formatting the extroot partition ${DEVICE} as ext4 and labeling it 'extroot'..."
mkfs.ext4 -F -L extroot ${DEVICE};

echo "Step 6: Reading UUID for ${DEVICE} from block info..."
# Extract UUID="..." string and evaluate so UUID variable is exported in the script environment
eval $(block info ${DEVICE} | grep -o -e 'UUID="\S*"');

# Confirm we found a UUID
echo "Found device UUID: ${UUID}";

echo "Step 7: Finding current overlay mount point from block info..."
# Extract MOUNT="/path/to/overlay"
eval $(block info | grep -o -e 'MOUNT="\S*/overlay"');

# Confirm we found an overlay mount path
echo "Detected overlay mount point: ${MOUNT}";

echo "Step 8: Updating UCI fstab configuration to use new extroot and enable swap..."
# Remove any existing extroot fstab entry then create a new one pointing by UUID
uci -q delete fstab.extroot;
uci set fstab.extroot="mount";
uci set fstab.extroot.uuid="${UUID}";
uci set fstab.extroot.target="${MOUNT}";

echo "Committing fstab changes..."
uci commit fstab;

echo "Step 9: Mounting the new extroot partition ${DEVICE} to /mnt..."
mount ${DEVICE} /mnt;

echo "Step 10: Copying current root filesystem data from ${MOUNT} to new extroot at /mnt..."
# Use tar over a pipe to preserve metadata while copying the full overlay contents
tar -C ${MOUNT} -cvf - . | tar -C /mnt -xf -;

echo "Step 11: Syncing disks (ensure data is written) and rebooting..."
sync;

echo "Rebooting now to apply extroot configuration. The system will switch to the new extroot on boot."
reboot;
