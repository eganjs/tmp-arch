#!/bin/sh -e

USERNAME="eganjs"
AUR_HELPER="trizen"

print_title() {
	echo
	echo $(tput bold)$(tput setaf 6)${1}$(tput sgr0)
}

print_title "Creating user..."
{
	#read -p "Username: " USERNAME
	USERNAME=`echo ${USERNAME} | tr '[:upper:]' '[:lower:]'`
	useradd -m -g users -G wheel -s /bin/bash ${USERNAME}
	#chfn ${USERNAME}
	passwd ${USERNAME}
}

print_title "Installing AUR helper..."
{
		mkdir -p /tmp/${AUR_HELPER}
		curl https://aur.archlinux.org/cgit/aur.git/snapshot/${AUR_HELPER}.tar.gz | tar zxvf - -C /tmp/${AUR_HELPER}
		cd /tmp/${AUR_HELPER}/${AUR_HELPER}
		makepkg -csi --noconfirm
}
