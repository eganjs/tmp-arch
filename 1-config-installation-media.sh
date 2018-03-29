#!/bin/sh -e

KEYMAP="uk"
EDITOR="vim"
MIRRORS_BY_COUNTRY_CODE=("NL", "CH") # Netherlands, Switzerland


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
  loadkeys ${KEYMAP}
}
set_keymap

set_editor(){
  echo
  echo "Setting editor..."
  install_pkg ${EDITOR}
  export EDITOR=${EDITOR}
}
set_editor

configure_mirrorlist(){
  echo
  echo "Configuring mirrorlist..."
  tmp_file=$(mktemp --suffix=-mirrorlist)
  for country_code in ${MIRRORS_BY_COUNTRY_CODE[@]}; do
    url="https://www.archlinux.org/mirrorlist/?country=${country_code}&use_mirror_status=on"
    curl -so ${tmp_file} ${url}
  done
  sed -i 's/^#Server/Server/g' ${tmp_file}
  rankmirrors ${tmp_file} > /etc/pacman.d/mirrorlist
}
configure_mirrorlist
