#!/bin/sh
#
# For installing NixOS after booting from the minimal USB image.
#
# To run:
#
#     sh -c "$(curl https://eipi.xyz/nixinst.sh)"
#

echo "Your attached storage devices will now be listed."
read -p "Press 'q' to exit the list. Press enter to continue." NULL

# Show the list of devices
sudo fdisk -l | less

i=0
for device in $(sudo fdisk -l | grep "^Disk /dev" | awk '{print $2}' | sed 's/://'); do
    echo "[$i] $device"
    DEVICES[$i]=$device
    i=$((i+1))
done

echo
read -p "Which device do you wish to install on? " DEVICE

# Adjust the index correctly
DEV=${DEVICES[$DEVICE]}

echo "Partitioning ${DEV}..."
(
    echo g # new gpt partition table
    echo n # new partition
    echo 1 # partition 1
    echo   # default start sector
    echo +500M # size is 500M for EFI

    echo n # new partition
    echo 2 # second partition
    echo   # default start sector
    echo   # default end sector

    echo t # set type
    echo 1 # first partition
    echo 1 # EFI System

    echo t # set type
    echo 2 # second partition
    echo 20 # Linux Filesystem

    echo p # print layout
    echo w # write changes
) | sudo fdisk ${DEV}

# Scan partitions again to ensure the changes are applied
sudo partprobe ${DEV}

# List partitions and allow user to select
i=1
for part in $(sudo fdisk -l | grep ${DEV} | grep -v "," | awk '{print $1}'); do
    echo "[$i] $part"
    PARTITIONS[$i]=$part
    i=$((i+1))
done

# Assign partition variables dynamically
P1=${PARTITIONS[1]}  # EFI partition (typically the first partition)
P2=${PARTITIONS[2]}  # Root partition (second partition)

# Set up file systems
echo "Creating file systems..."
sudo mkfs.fat -F 32 -n boot ${P1}
sudo mkfs.ext4 -L nixos ${P2}

# Mount the partitions
echo "Mounting partitions..."
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot                      # for UEFI systems
sudo mount /dev/disk/by-label/boot /mnt/boot # for UEFI systems

# Generate NixOS configuration
echo "Generating NixOS configuration..."
sudo nixos-generate-config --root /mnt

read -p "Press enter and the NixOS configuration will be opened in nano."

# Open the configuration file in nano
sudo nano /mnt/etc/nixos/configuration.nix

# Install NixOS
echo "Installing NixOS..."
sudo nixos-install

read -p "Remove installation media and press enter to reboot." NULL

# Reboot system
reboot
