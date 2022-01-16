#!/bin/bash
# Hyeon's own Arch Linux Automatic Installation script
#
# Download this script...
#
# With wget:
#
# wget -O https://baehyeonwoo.com/hyeonalis/install.sh
#
# With curl:
#
# curl "https://baehyeonwoo.com/hyeonalis/install.sh" > install.sh
#
# This script is licensed under Do What The Fuck You Want To Public License v2.0.

# Script was based on Jeon W. H.'s Arch Linux Install Guide: https://jeonwh.com/arch-install/ (Korean)
# For starters, I highly recommend to check his guide.

# EFI Check

if [ -d "/sys/firmware/efi/efivars" ]
then
    echo ""
else
    echo "This computer is not in EFI Platform. Please check the EFI state and try again."
    exit
fi

clear

# Configuring Mirrorlist

echo "//////////MIRRORLIST//////////"

read -r -p "Do you have your own mirrorlist? (y/n): " yn


case $yn in
            [Yy]* ) echo;;
            [Nn]* ) rm -rf /etc/pacman.d/mirrorlist;
                    echo "Server = http://ftp.kaist.ac.kr/ArchLinux/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist;
                    echo "Server = https://ftp.kaist.ac.kr/ArchLinux/\$repo/os/\$arch" >> /etc/pacman.d/mirrorlist;
                    curl "https://archlinux.org/mirrorlist/?country=KR&protocol=http&protocol=https&ip_version=4" >> /etc/pacman.d/temp;
                    tail -n +7 /etc/pacman.d/temp >> /etc/pacman.d/mirrorlist;
                    sed -i '3,10s/.//' /etc/pacman.d/mirrorlist; # To remove comment signification
                    rm -rf /etc/pacman.d/temp;;
            * ) echo "Please answer yes or no.";;
  esac
clear

# Partitioning

SKIPPARTITIONING=FALSE

echo "//////////PARTITIONING//////////"
echo "This is your block devices list:"
lsblk
echo ""

echo "Choose your tool to partition with:"
echo "1) cfdisk"
echo "2) gdisk"
echo "or, if you want to skip partitioning, please write \"skip\" (case-sensitive)"
echo ""

read -r -p "Write your favorite partition tool as a number: " parttool
echo ""

if [ "${parttool}" == "skip" ]; then
    export SKIPPARTITIONING=TRUE
elif [ "${parttool}" == "1" ]; then
    echo ""
elif [ "${parttool}" == "2" ]; then
    echo ""
else
    echo "Please answer the question correctly."
fi

if [ $SKIPPARTITIONING == "FALSE" ]; then
    read -r -p "Choose your disk to partition (PLEASE TYPE IT CLEARLY! ex: /dev/sda): " diskinput
    if [ "${parttool}" == "1" ]; then
        cfdisk "${diskinput}"
    elif [ "${parttool}" == "2" ]; then
        gdisk "${diskinput}"
    fi
else
    echo "Please type your disk clearly, with no typos."
    exit 1
fi

clear

# Formatting / SWAP

SKIPFORMATTING=FALSE

echo "//////////FORMATTING//////////"

  if [ $SKIPFORMATTING == "FALSE" ]; then
    lsblk
    echo "WARNING: IN THIS SECTION YOU NEED TO TYPE YOUR PARTITION ALL EXPLICITLY. PLEASE BE CAREFUL NOT TO MAKE ANY ERRORS."

    read -r -p "Type your EFI Partition to format. If yo don't want to format it, please enter \"skip\". (case-sensitive, ex: sda1): " efipart

    if [ "$efipart" == "skip" ]; then
	    read -r -p "Type your EFI Partition. This for configuring bootloader later, not for formatting. (case-sensitive, ex: sda1): " efipart
    elif [ "$efipart" == "" ]; then
        echo "Please answer the question correctly."
    else
        mkfs.vfat -F32 /dev/"$efipart"
    fi

    read -r -p "Type your SWAP Partition. If you don't have it, please enter \"skip\". (case-sensitive, ex: sda2): " swappart

    if [ "$swappart" == "skip" ]; then
      echo ""
    elif [ "$swappart" == "" ]; then
        echo "Please answer the question corretly."
    else
        mkswap /dev/"$swappart"
        swapon /dev/"$swappart"
    fi

    read -r -p "Type your ROOT Partition ro format (case-sensitive, ex: sda3): " rootpart

    if [ "$rootpart" == "" ]; then
        echo "Please answer the question corretly."
    else
        mkfs.ext4 -j /dev/"$rootpart"
    fi
  else
    echo ""
fi

# Mount

mount /dev/"$rootpart" /mnt
mkdir /mnt/boot
mount /dev/"$efipart" /mnt/boot

clear

# Time Congfiguration, using ntp
echo "//////////Time Configuration is automatically being processed...//////////"
pacman -S ntp --noconfirm ; ntpd -q -g

hwclock --systohc --utc

clear

# Base Package Installation
echo "//////////BASE PACKAGE INSTALLATION//////////"

echo "These are the base packages are going to installed: \"base linux linux-firmware nano vim dhcpcd base-devel man-db man-pages texinfo dosfstools e2fsprogs git go\""
echo "If you don't want something in this packages, remember the package name for a while and use \"pacman -R\" to remove them."
echo "Base package installation setup will start in 15 seconds."
sleep 15

pacstrap /mnt base linux linux-firmware nano vim dhcpcd base-devel man-db man-pages texinfo dosfstools e2fsprogs git go

# genfstab
genfstab -U /mnt >> /mnt/etc/fstab

clear

# USER CHROOT CONFIG

echo "//////////User Configurations//////////"

read -r -s -p "Please enter root password: " rootpwd

if [ "$rootpwd" == "" ]
then
    echo "Please answer the question correctly."
else
    echo ""
fi

echo ""

read -r -p "Please enter your locale (ex: en_US): " locconfig

if [ "$locconfig" == "" ]
then
    echo "Please answer the question correctly."
else
    echo ""
fi

read -r -p "Please enter your hostname(ex: archcomputer): " host

if [ "$host" == "" ]
then
    echo "Please answer the question correctly."
else
    echo ""
fi

read -r -p "Please enter your username: " username

if [ "$username" == "" ]
then
    echo "Please answer the question correctly."
else
    echo ""
fi

read -r -s -p "Please enter ${username}'s password: " userpwd

if [ "$userpwd" == "" ]
then
    echo "Please answer the question correctly."
else
    echo ""
fi

echo ""

clear

echo "As you know, you need to remember your Username, Password, and the root's password. Be sure to remember what you have entered right now!"
echo "Local time configuration will be set to Asia/Seoul for initial settings. Change the settings after reboot if you want."
echo "User configuration setup will start in 10 seconds."
sleep 10

clear

arch-chroot /mnt bash -c "echo \"root:$rootpwd\" | chpasswd;
                          echo \"$locconfig.UTF-8 UTF-8\" > /etc/locale.gen; locale-gen; echo \"LANG=$locconfig.UTF-8\" > /etc/locale.conf;
                          echo \"$host\" > /etc/hostname;
                          ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime;
                          useradd -m -g users -G wheel -s /bin/bash \"$username\";
                          echo \"$username:$userpwd\" | chpasswd;
                          sed -i \"80 i $username ALL=(ALL) ALL\" /etc/sudoers;
                          pacman -S grub efibootmgr --noconfirm; grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch --recheck; grub-mkconfig -o /boot/grub/grub.cfg;
                          systemctl enable dhcpcd"

clear

echo "Installation has successfully finished!"
echo "Thank you for using my sciprt!"
echo "-Hyeon"
echo ""
read -r -p "Do you want to reboot? (y/n): " yn

case $yn in
            # So Long, and Thanks for all the fish.
            [Yy]* ) reboot;; echo "So Long, and Thanks for all the fish."; umount -lR /mnt; reboot;;
            [Nn]* ) echo "Exiting..."; exit;;
            * ) echo "Exiting..."; exit;;
esac
