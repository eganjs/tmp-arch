#!/bin/sh -e

USERNAME="eganjs"
AUR_HELPER="trizen"

aur_helper() {
	su - ${USERNAME} sh -c "${AUR_HELPER} $@"
}

install_pkg() {
	aur_helper -S --needed --noconfirm $@
}

print_title() {
	echo
	echo $(tput bold)$(tput setaf 6)${1}$(tput sgr0)
}

print_title "Creating user..."
{
	read -p "Username: " USERNAME
	USERNAME=`echo ${USERNAME} | tr '[:upper:]' '[:lower:]'`
	useradd -m -g users -G wheel -s /bin/bash ${USERNAME}
	chfn ${USERNAME}
	passwd ${USERNAME}
}

print_title "Installing AUR helper..."
{
	su - ${USERNAME} sh -c "
		tmp_dir=\`mktemp -d\`
		curl https://aur.archlinux.org/cgit/aur.git/snapshot/${AUR_HELPER}.tar.gz | tar zxvf - -C \${tmp_dir}
		cd \${tmp_dir}/${AUR_HELPER}
		makepkg -csi --noconfirm
	"
}

print_title "Syncing pkg db..."
{
	aur_helper -Syu --noconfirm
}

print_title "Installing X11"
{
	install_pkg xorg-server xorg-server-xwayland xorg-apps xorg-xinit xorg-xkill xorg-xinput xf86-input-libinput
	install_pkg mesa
}

print_title "Installing i3"
{
	install_pkg i3 dmenu
}
