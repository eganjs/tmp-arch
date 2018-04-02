#!/bin/sh -e

MOUNT_POINT="/mnt"


print_title() {
	echo
	echo $(tput bold)$(tput setaf 6)${1}$(tput sgr0)
}

print_title "arch"

sys_exec() {
	arch-chroot ${MOUNT_POINT} /bin/sh -c "$1"
}

sys_user_exec() {
	sys_exec "mv /etc/sudoers /etc/sudoers.bk"
	cat <<- EOF > ${MOUNT_POINT}/etc/sudoers
		root	ALL=(ALL) ALL
		%nobody	ALL=(ALL) NOPASSWD: ALL
	EOF
	command=`printf "%q" "$1"`
	sys_exec "su - nobody -s /bin/sh -c \"${command}\""
	sys_exec "mv /etc/sudoers.bk /etc/sudoers"
}

sys_aur_install_pkg() {
	for pkg in $@; do
		sys_user_exec "
			temp_folder=mktemp -d --suffix=-${pkg}
			curl https://aur.archlinux.org/cgit/aur.git/snapshot/${pkg}.tar.gz | tar zxvf - -C \${temp_folder}
			cd \${temp_folder}/${pkg}
			makepkg -csi --noconfirm
		"
	done
}

sys_aur_install_pkg aic94xx-firmware wd719x-firmware
