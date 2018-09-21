#!/bin/bash

set -e
set -x

if [ -e /dev/vda ]; then
  device=/dev/vda
elif [ -e /dev/sda ]; then
  device=/dev/sda
else
  echo "ERROR: There is no disk available for installation" >&2
  exit 1
fi
export device

memory_size_in_kilobytes=$(free | awk '/^Mem:/ { print $2 }')
swap_size_in_kilobytes=$((memory_size_in_kilobytes * 2))
sfdisk "$device" <<EOF
label: gpt
size=512MiB, type=1, bootable
size=${swap_size_in_kilobytes}KiB, type=19
type=20
EOF
mkswap "${device}2"
mkfs.btrfs "${device}3"
mount "${device}3" /mnt
mkdir /mnt/boot
mkfs.vfat -F 32 "${device}1"
mount "${device}1" /mnt/boot

cat <<\EOF > /etc/pacman.d/mirrorlist
Server = https://mirror.local.t4cc0.re/archlinux/$repo/os/$arch
Server = https://mirror.t4cc0.re/archlinux/$repo/os/$arch
Server = http://archlinux.mirror.iphh.net/$repo/os/$arch
EOF

pacstrap /mnt base openssh sudo btrfs-progs

swapon "${device}2"
genfstab -p /mnt >> /mnt/etc/fstab
swapoff "${device}2"

arch-chroot /mnt /bin/bash
