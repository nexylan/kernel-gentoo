#!/bin/bash

#
# SCRIPT DE MISE A JOUR DE NERL
# NEXYLAN SAS
# GAETAN ALLART / Guillaume (Llew) Delpierre
# 

# Get kernel locally
kerndir="/root/kernel"
bootdir="/boot"

cd "$kerndir" && git pull ||\
cd "${kerndir%%kernel}" && git clone http://git.nexylan.net/nexylan/kernel.git

# DETERMINING Last version
kernelVersion=`cat "$kerndir"/latest`
echo "Latest version of Kernel is $kernelVersion"

# DETERMINING Current version
currentKernel=`uname -a | awk '{print $3}'`
currentKernel="kernel-$currentKernel"
echo "Current version of Kernel is $currentKernel"

# CHECK if upgrade is required
if [ "$kernelVersion" == "$currentKernel" ]
then
        echo "Kernel up2date, no need for upgrade"
        exit
fi

# Mount /boot if needed
if ! grep -q "$bootdir" /proc/mounts
then
    echo "Mounting /boot"
    mount "$bootdir"
fi

# Upgrade
echo "Kernel upgrade required"
echo "Copying new kernel to /boot"
cp "$kerndir"/"$kernelVersion" "$bootdir"

# Update GRUB
echo "Updating GRUB"
grubversion=`equery list grub | sed -n 's/sys-boot\/grub-\([02]\).*/\1/p'`
if [ "$grubversion" -lt 2 ]; then
    sed -i -e "s#/kernel-[0-9\.\-]*gentoo#/$kernelVersion#" \
              "$bootdir"/grub/grub.conf
else
    grub2-mkconfig -o /boot/grub/grub.cfg

# Does udev needs upgrading
udev=`equery list udev | grep sys | cut -d'/' -f2 | cut -d'-' -f2`

if [ $udev -lt 200 ]
then
        echo "Udev needs upgrading"

        emerge -qu sysvinit util-linux

        emerge -qu udev

        rm /etc/udev/rules.d/*
        ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules
fi

echo "Upgrade is OK. You should reboot now !"