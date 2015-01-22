#!/bin/bash

#
# SCRIPT DE MISE A JOUR DE NERL
# NEXYLAN SAS
# GAETAN ALLART / Guillaume (Llew) Delpierre
# 

VERSION="1.04"

# Reset
Color_Off='\e[0m'       # Text Reset

# Regular Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White

# Underline
UBlack='\e[4;30m'       # Black
URed='\e[4;31m'         # Red
UGreen='\e[4;32m'       # Green
UYellow='\e[4;33m'      # Yellow
UBlue='\e[4;34m'        # Blue
UPurple='\e[4;35m'      # Purple
UCyan='\e[4;36m'        # Cyan
UWhite='\e[4;37m'       # White

# Background
On_Black='\e[40m'       # Black
On_Red='\e[41m'         # Red
On_Green='\e[42m'       # Green
On_Yellow='\e[43m'      # Yellow
On_Blue='\e[44m'        # Blue
On_Purple='\e[45m'      # Purple
On_Cyan='\e[46m'        # Cyan
On_White='\e[47m'       # White

# High Intensty
IBlack='\e[0;90m'       # Black
IRed='\e[0;91m'         # Red
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
IPurple='\e[0;95m'      # Purple
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White

# Bold High Intensty
BIBlack='\e[1;90m'      # Black
BIRed='\e[1;91m'        # Red
BIGreen='\e[1;92m'      # Green
BIYellow='\e[1;93m'     # Yellow
BIBlue='\e[1;94m'       # Blue
BIPurple='\e[1;95m'     # Purple
BICyan='\e[1;96m'       # Cyan
BIWhite='\e[1;97m'      # White

# High Intensty backgrounds
On_IBlack='\e[0;100m'   # Black
On_IRed='\e[0;101m'     # Red
On_IGreen='\e[0;102m'   # Green
On_IYellow='\e[0;103m'  # Yellow
On_IBlue='\e[0;104m'    # Blue
On_IPurple='\e[10;95m'  # Purple
On_ICyan='\e[0;106m'    # Cyan
On_IWhite='\e[0;107m'   # White

# MOTD

echo -e ${BRed} ".__   __.  __________   ___ ____    ____  __          ___      .__   __."
echo -e "|  \ |  | |   ____\  \ /  / \   \  /   / |  |        /   \     |  \ |  |"
echo -e "|   \|  | |  |__   \  V  /   \   \/   /  |  |       /  ^  \    |   \|  |"
echo -e "|  . '  | |   __|   >   <     \_    _/   |  |      /  /_\  \   |  . '  |"
echo -e "|  |\   | |  |____ /  .  \      |  |     |  '----./  _____  \  |  |\   |"
echo -e "|__| \__| |_______/__/ \__\     |__|     |_______/__/     \__\ |__| \__|"

echo
echo

echo -e "${Green}Welcome to kernel upgrade disk"
echo -e "${Blue}This is version ${VERSION}"
echo -e "Do you wish to continue ?"
read

# DETERMINING Kernel Path
kernelPath="https://raw.github.com/Nexylan/kernel-gentoo/master"
bootdir="/boot"

# DETERMINING Last version
kernelVersion=$(wget -q -O - $kernelPath/latest)
echo -e "${Cyan}Latest version of Kernel is $kernelVersion"

# DETERMINING Current version
currentKernel=$(uname -a | awk '{print $3}')
currentKernel="kernel-$currentKernel"
echo -e "${Cyan}Current version of Kernel is $currentKernel"

echo

# CHECK if upgrade is required
if [ "$kernelVersion" == "$currentKernel" ]
then
        echo -e "${Yellow}Kernel up2date, no need for upgrade"
        exit
fi

# Mount /boot if needed
if ! grep -q "$bootdir" /proc/mounts
then
    echo -e "${Green}Mounting /boot"
    mount "$bootdir"

    if [ $? -ne 0 ]; then
    	echo -e "${Red}Mouting /boot partition failed. ABORTING."
    	exit 1
    fi
fi

# Upgrade
echo -e "${Yellow}Kernel upgrade required. Downloading Kernel."
wget -q -O "$bootdir/kernel-$kernelVersion" "$kernelPath/kernel-$kernelVersion"

echo

# Select latest GCC profile
echo -e "${Green}Selecting latest GCC profile"
gcc=$(gcc-config -l | tail -1 | awk '{print $2}')
gcc-config $gcc >> /dev/null
emerge -q1 libtool > /dev/null
env-update > /dev/null
. /etc/profile
echo -e "${Yellow}- Done"

echo

# Update GRUB
echo -e "${Yellow}Checking if grub:0 is installed"
equery list grub:0  >> /dev/null
if [ $? -eq 0 ] || [ -d /boot/grub2 ] || [ ! -d /boot/grub ]; then
	echo -e "${Green}Removing old grub"
	emerge -C grub:0 >> /dev/null 2>&1
	rm -rf /boot/grub*
	echo -e "${Yellow}- Done"

	echo

	echo -e "${Green} Installing new grub"
	emerge -qu grub >> /dev/null
	if [ $? -ne 0 ]; then
		echo -e "- {$Red}Upgrading GRUB failed. CANNOT CONTINUE"
		exit 1
	fi
	echo -e "${Yellow}- Done"

	echo

	if [ -e /dev/xvda ]
	then
		echo
		echo -e "${Green}Installing grub on disk /dev/xvda"
		grub2-install /dev/xvda >> /dev/null
		echo -e "${Yellow}- Done"
	else
		if [ -e /dev/sdb ]
		then
			echo
			echo -e "${Green}Installing grub on disk /dev/sdb"
			emerge -qu mdadm >> /dev/null
			grub2-install /dev/sdb >> /dev/null
			echo -e "${Yellow}- Done"
		fi
		echo
		echo -e "- ${Green}Installing grub on disk /dev/sda"
		grub2-install /dev/sda >> /dev/null
		echo -e "${Yellow}- Done"
	fi
else
	echo
	echo -e "${Green}Upgrading Grub"
	emerge -qu grub	 >> /dev/null
	echo -e "${Yellow}- Done"
fi


echo -e "- ${Green}Generating grub config file"
grub2-mkconfig -o "$bootdir"/grub/grub.cfg

echo


# Does udev needs upgrading
udev=$(equery list udev | grep sys | cut -d'/' -f2 | cut -d'-' -f2)

echo -e "${Yellow}Checking if udev ($udev) needs upgrading"
#if [ $udev -lt 200 ]
if [ $udev -lt 216 ]
then
        echo -e "- ${Green}Udev needs upgrading. Emerging Udev."

        emerge -qu sysvinit util-linux pciutils >> /dev/null
        emerge -qu udev >> /dev/null

    	if [ $? -ne 0 ]; then
    		echo -e "${Red}Udev upgrade failed. You should NOT reboot"
    		exit 1
    	fi

        rm /etc/udev/rules.d/*
        ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
fi

# Determine if XEN disk pattern upgrade
if grep -q "nx3" /etc/conf.d/hostname
then
	if grep -q "sda" /etc/fstab
	then
		echo "Upgrading disk pattern for xen kernel"
		sed -i -e "s/sda/xvda/g" /etc/fstab
		sed -i -e "s/sda/xvda/g" /boot/grub/grub.conf
	fi
fi


echo -e "${BPurple}Upgrade is OK. You should reboot now !"
