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
		echo "[D 0]: ${pkg}"
		temp_folder=`sys_user_exec "mktemp -d --suffix=-${pkg}"`
		echo "[D 1]: ${temp_folder}"
		sys_user_exec "curl https://aur.archlinux.org/cgit/aur.git/snapshot/${pkg}.tar.gz | tar zxvf - -C ${temp_folder}"
		echo "[D 2]: "`ls ${MOUNT_POINT}/${temp_folder}`
		sys_user_exec "cd ${temp_folder}/${pkg}; makepkg -csi --noconfirm"
		echo "[D 3]: "`ls ${MOUNT_POINT}/${temp_folder}/${pkg}`
	done
}

sys_aur_install_pkg aic94xx-firmware wd719x-firmware
