#!/bin/sh -e

USERNAME="eganjs"
USER_HOME=/home/${USERNAME}
AUR_HELPER="trizen"

run_as_user() {
	su - ${USERNAME} sh -c "$@"
}

install_pkg() {
	run_as_user ${AUR_HELPER} -S --needed --noconfirm $@
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

print_title "Syncing pkg db and checking for updates..."
{
	run_as_user ${AUR_HELPER} -Syu --noconfirm
}

print_title "Installing X11..."
{
	install_pkg xorg-server xorg-server-xwayland xorg-apps xorg-xinit xorg-xkill xorg-xinput xf86-input-libinput
	install_pkg mesa
}

print_title "Installing i3..."
{
	install_pkg i3 dmenu
	cat <<- EOF > ${USER_HOME}/.xinitrc
		exec i3
	EOF
}

print_title "Installing zsh..."
{
	install_pkg zsh oh-my-zsh-git
	cp /usr/share/oh-my-zsh-git/zshrc ${USER_HOME}/.zshrc
	chsh ${USERNAME} -s /bin/zsh
}
