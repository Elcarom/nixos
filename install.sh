#!/bin/sh
#
# For installing NixOS having booted from the minimal USB image.
#
# To run:
#
#     sh -c "$(curl https://eipi.xyz/nixinst.sh)"
#

echo "Your attached storage devices will now be listed."
read -p "Press 'q' to exit the list. Press enter to continue." NULL

sudo fdisk -l | less


i=0
for device in $(sudo fdisk -l | grep "^Disk /dev" | awk '{print $2}' | sed 's/://'); do
    echo "[$i] $device"
    DEVICES[$i]=$device
    i=$((i+1))
done

echo
read -p "Which device do you wish to install on? " DEVICE

DEV=${DEVICES[$(($DEVICE+1))]}

echo "partitioning ${DEV}..."
(
    echo g # new gpt partition table

    echo n # new partition
    echo 1 # partition 1
    echo   # default start sector
    echo +500M # size is 500M

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

i=1
for part in $(sudo fdisk -l | grep $DEV | grep -v "," | awk '{print $1}'); do
    echo "[$i] $part"
    i=$((i+1))
    PARTITIONS[$i]=$part
done

P1=${PARTITIONS[2]}
P2=${PARTITIONS[3]}

read -p "Press enter to install NixOS." NULL

sudo mkfs.fat -F 32 -n boot ${P3}
sudo mkfs.ext4 -L nixos ${P1}

sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot                      # (for UEFI systems only)
sudo mount /dev/disk/by-label/boot /mnt/boot # (for UEFI systems only)

sudo nixos-generate-config --root /mnt

read -p "Press enter and the Nix configuration will be opened in nano."

sudo nano /mnt/etc/nixos/configuration.nix

sudo nixos-install

read -p "Remove installation media and press enter to reboot." NULL

reboot
