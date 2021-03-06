#!/bin/sh -e

install_pkg() {
  pacman -S --needed --noconfirm ${1}
}

sync_pkg_db() {
  pacman -Syy
}
sync_pkg_db

mount -o remount,size=2G /run/archiso/cowspace
install_pkg git
pushd ~ > /dev/null
git clone git://github.com/eganjs/tmp-arch
popd > /dev/null
