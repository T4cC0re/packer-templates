#!/bin/bash

set -e
set -x

ln -sf /usr/share/zoneinfo/UTC /etc/localtime

echo template > /etc/hostname

sed -i -e 's/^#\(en_US.UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

echo -e 'vagrant\nvagrant' | passwd
useradd -m -U vagrant
echo -e 'vagrant\nvagrant' | passwd vagrant
cat <<EOF > /etc/sudoers.d/vagrant
Defaults:vagrant !requiretty
vagrant ALL=(ALL) NOPASSWD: ALL
EOF
chmod 440 /etc/sudoers.d/vagrant


mkinitcpio -p linux

IF="$(ip -o a | grep -v lo | awk '{print $2}' | head -1)"

systemctl enable sshd
systemctl enable dhcpcd@${IF}

bootctl install --path "/boot"

ROOTDEV="$(mount | grep btrfs | awk '{print $1}')"
echo $ROOTDEV
UUID="$(blkid -o value -s UUID "$ROOTDEV")"

cat <<EOF > /boot/loader/entries/ArchLinux.conf
title ArchLinux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=UUID=$UUID rw
EOF
