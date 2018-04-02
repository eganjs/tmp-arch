#!/bin/sh -e

MOUNT_POINT="/mnt"

KEYMAP="uk"
LOCALE="en_GB.UTF-8"

install_pkg() {
	pacman -S --needed --noconfirm $@
}

sys_install_pkg() {
	pacstrap ${MOUNT_POINT} $@
}

sys_exec() {
	arch-chroot ${MOUNT_POINT} /bin/sh -c "$1"
}

sys_user_exec() {
	sys_exec "mv /etc/sudoers /etc/sudoers.bk"
	cat <<- EOF > ${MOUNT_POINT}/etc/sudoers
		root	ALL=(ALL) ALL
		%nobody	ALL=(ALL) NOPASSWD: ALL
	EOF
	sys_exec "su - nobody -s /bin/sh -c \"${1}\""
	sys_exec "mv /etc/sudoers.bk /etc/sudoers"
}

sys_aur_install_pkg() {
	for pkg in $@; do
		sys_user_exec "
			mkdir -p /tmp/${pkg}
			curl https://aur.archlinux.org/cgit/aur.git/snapshot/${pkg}.tar.gz | tar zxvf - -C /tmp/${pkg}
			cd /tmp/${pkg}/${pkg}
			makepkg -csi --noconfirm
		"
	done
}

print_title() {
	echo
	echo $(tput bold)$(tput setaf 6)${1}$(tput sgr0)
}

print_title "Syncing pkg db..."
{
	pacman -Sy
}

print_title "Installing base system..."
{
	install_pkg archlinux-keyring
	sys_install_pkg base base-devel linux-headers
}

print_title "Configuring networking..."
{
	wireless_devices=(`ip link | awk '$2 ~ /^wl/ {print $2}' | sed 's/:$//'`)
	if [[ ${wireless_devices[@]} ]]; then
		echo "Wireless interface(s) detected, installing additional packages..."
		sys_install_pkg netctl wpa_actiond wpa_supplicant dialog
	fi
	wired_devices=(`ip link | awk '$2 ~ /^(ens|eno|enp)/ {print $2}' | sed 's/:$//'`)
	for wired_device in ${wired_devices[@]}; do
		echo "Wired interface (${wired_device}) detected, enabling..."
		sys_exec "systemctl enable dhcpcd@${wired_device}.service"
	done
}

print_title "Configuring keymap..."
{
	cat <<- EOF > ${MOUNT_POINT}/etc/vconsole.conf
		KEYMAP=${KEYMAP}
	EOF
}

print_title "Configuring fstab..."
{
	genfstab -p ${MOUNT_POINT} >> ${MOUNT_POINT}/etc/fstab
}

print_title "Configuring timezone..."
{
	sys_exec "ln -sf /usr/share/zoneinfo/UTC /etc/localtime"
	cat <<- EOF > ${MOUNT_POINT}/etc/systemd/timesyncd.conf
		[Time]
		NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org
		FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org
	EOF
	sys_exec "systemctl enable systemd-timesyncd.service"
}

print_title "Configuring hardware clock..."
{
	sys_exec "hwclock --systohc --utc"
}

print_title "Configuring locale..."
{
	cat <<- EOF > ${MOUNT_POINT}/etc/locale.conf
		LANG=${LOCALE}
	EOF
	cat <<- EOF > ${MOUNT_POINT}/etc/locale.gen
		${LOCALE} UTF-8
	EOF
	sys_exec "locale-gen"
}

print_title "Configuring sudoers file..."
{
	cat <<- EOF > ${MOUNT_POINT}/etc/sudoers
		root	ALL=(ALL) ALL
		%wheel	ALL=(ALL) NOPASSWD: ALL
	EOF
}

print_title "Configuring initial ramdisk..."
{
	sys_aur_install_pkg aic94xx-firmware wd719x-firmware
	sys_exec "mkinitcpio -p linux"
}

print_title "Configuring bootloader..."
{
	sys_exec "bootctl --path=/boot install"
	root_device=`lsblk -nlp | awk '$7 == "'${MOUNT_POINT}'" {print $1}'`
	root_device_partuuid=`blkid -s PARTUUID ${root_device} | awk 'match($2, /"([^"]+)/, g) {print g[1]}'`
	cat <<- EOF > ${MOUNT_POINT}/boot/loader/entries/arch.conf
		title	Arch Linux
		linux	/vmlinuz-linux
		initrd	/initramfs-linux.img
		options	root=PARTUUID=${root_device_partuuid} rw
	EOF
	cat <<- EOF > ${MOUNT_POINT}/boot/loader/loader.conf
		default	arch
		timeout	4
		editor	0
	EOF
}

print_title "Configuring hostname..."
{
	read -p "Enter hostname: " hostname
	cat <<- EOF > ${MOUNT_POINT}/etc/hostname
		${hostname}
	EOF
}

print_title "Configuring password for root user..."
{
	sys_exec "passwd"
}
