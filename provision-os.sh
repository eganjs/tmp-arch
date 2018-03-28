#!/bin/sh -e

KEYMAP="uk"
EDITOR="vim"
DEVICE=""

install_pkg() {
  pacman -S --needed --noconfirm ${1}
}

sync_pkg_db() {
  pacman -Sy
}
sync_pkg_db

set_keymap(){
  echo "Setting keymap..."
  loadkeys "$KEYMAP"
}
set_keymap

configure_mirrorlist(){
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
  echo "Setting editor..."
  install_pkg "$EDITOR"
}
set_editor

configure_device_partitioning() {
  echo "Configuring device partitioning..."
  select_device() {
    devices=$(lsblk -dlnp -I 8)
    echo
    echo "Available devices:"
    echo ${devices} | awk '{print $1,$4}' | column -t
    echo
    echo "Select a device to partition:"
    devices=(`echo ${devices} | awk '{print $1}'`)
    select DEVICE in "${devices[@]}"; do
      break
    done
  }
  select_device
  gdisk ${DEVICE}
}
configure_device_partitioning

