#!/bin/sh -e

KEYMAP="uk"
EDITOR="vim"
DEVICE=""
UEFI=0
MOUNT="/mnt"

install_pkg() {
  pacman -S --needed --noconfirm ${1}
}

sync_pkg_db() {
  pacman -Syy
}
sync_pkg_db

set_keymap(){
  echo
  echo "Setting keymap..."
  loadkeys "$KEYMAP"
}
set_keymap

configure_mirrorlist(){
  echo
  echo "Configuring mirrorlist..."
  country_codes=("NL", "CH") # Netherlands, Switzerland
  tmp_file=$(mktemp --suffix=-mirrorlist)
  for country_code in ${country_codes[@]}; do
    url="https://www.archlinux.org/mirrorlist/?country=${country_code}&use_mirror_status=on"
    curl -so ${tmp_file} ${url}
  done
  sed -i 's/^#Server/Server/g' ${tmp_file}
  rankmirrors ${tmp_file} > /etc/pacman.d/mirrorlist
}
configure_mirrorlist

set_editor(){
  echo
  echo "Setting editor..."
  install_pkg "$EDITOR"
}
set_editor

detect_uefi() {
  echo
  echo "Checking for UEFI..."
  if [ -d "/sys/firmware/efi/efivars" ]; then
    echo "UEFI detected"
    UEFI=1
  else
    echo "UEFI not found"
  fi
}
detect_uefi

configure_device_partitioning() {
  echo
  echo "Configuring device partitioning..."
  select_device() {
    devices=(`lsblk -dnlp | awk '{print $1,$4}'`);
    echo
    echo "Available devices:"
    echo ${devices} | column -t
    echo
    echo "Select a device to partition:"
    devices=(`echo ${devices} | awk '{print $1}'`);
    select DEVICE in "${devices[@]}"; do
      break
    done
  }
  select_device
  gdisk ${DEVICE}
  format_partitions() {
    options=("boot" "swap" "ext4" "skip")
    partitions=(`lsblk -nlp ${DEVICE} | awk '$6 == "part" {print $1,$4}'`);
    echo
    echo "Available partitions:"
    echo ${partitions} | column -t
    echo ${partitions}
    partitions=(`echo ${partitions} | awk '{print $1}'`)
    echo ${partitions}
    echo
    echo "Configuring partition formatting..."
    for partition in ${partitions[@]}; do
      echo
      echo "Select format for device: ${partition}"
      select option in ${options[@]}; do
        case $REPLY in
          1)
            echo "Formatting ${partition} as fat32"
            mkfs.vfat -F32 ${partition}
            break
            ;;
          2)
            echo "Formatting ${partition} as swap"
            mkswap ${partition}
            swapon
            break
            ;;
          3)
            echo "Formatting ${partition} as ext4"
            mkfs.ext4 -F ${partition}
            break
            ;;
          4)
            break
            ;;
        esac
      done
    done
  }
  format_partitions
}
configure_device_partitioning
