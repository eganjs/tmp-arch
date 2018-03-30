#!/bin/sh -e

DEVICE=""
ROOT_DEVICE=""
MOUNT_POINT="/mnt"


umount_partitions() {
  swapoff -a
  mounts=(`lsblk -nlp | awk '$7 ~ /^\'${MOUNT_POINT}'/ {print \$7}' | sort -r`)
  for mount in ${mounts[@]}; do
    umount ${mount}
  done
}
umount_partitions

echo
echo "Configuring disk..."
echo
echo "Select a disk to partition and install to"

select_device() {
  echo
  echo "Available devices:"
  lsblk -dnlp -I 8 | awk '{print $1,$4}' | column -t
  echo
  echo "Select a device to partition:"
  devices=(`lsblk -dnlp -I 8 | awk '{print $1}'`)
  select DEVICE in ${devices[@]}; do
    echo "Device ${DEVICE} selected"
    break
  done
}
select_device

gdisk ${DEVICE}
partpr

format_partitions() {
  options=("boot" "swap" "ext4" "skip")
  echo
  echo "Available partitions:"
  lsblk -nlp -I 8 ${DEVICE} | awk '$6 == "part" {print $1,$4}' | column -t
  echo
  echo "Configuring partition formatting..."
  partitions=(`lsblk -nlp ${DEVICE} | awk '$6 == "part" {print $1}'`)
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

mount_partitions() {
  lsblk -nlp -I 8 ${DEVICE} | awk '$6 == "part" {print $1,$4}' | column -t
  partitions=(`lsblk -nlp -I 8 ${DEVICE} | awk '$6 == "part" {print $1}'`)
  mount_partition() {
    echo
    echo "Select a partition to mount at ($1):"
    select partition in ${partitions[@]}; do
      device=${partition}
      mount_point="${MOUNT_POINT}$1"
      mkdir -p ${mount_point}
      mount ${device} ${mount_point}
      REPLY=$(( $REPLY - 1 ))
      unset partitions[REPLY]
      partitions=("${partitions[@]}")
      if [[ "$1" == "/" ]]; then
        ROOT_DEVICE=${device}
      fi
      break
    done
  }
  mount_partition "/"
  mount_partition "/boot"
  mount_additional_partitions() {
    options=("continue" "stop")
    while [[ ${partitions[@]} ]]; do
      echo
      echo "Mount additional partitions:"
      select option in ${options[@]}; do
        case $REPLY in
          1)
            read -p "Enter full mount path: " mount_path
            mount_partition ${mount_path}
            break
            ;;
          2)
            return
            ;;
        esac
      done
    done
  }
  mount_additional_partitions
}
mount_partitions
