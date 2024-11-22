#!/bin/sh

if [ -z "$1" ]; then
  echo "Usage: ./archinstall.sh <drive-name>"
  exit 1
fi

if [[ "$1" =~ ^/dev/(nvme|sd|hd|vd)[a-z0-9]+$ ]] && [ -b "$1" ]; then
  drive=$1
else
  echo "could not find $1"
  echo "Usage: ./archinstall.sh <drive-name>"
  exit 1
fi

echo "Loading German reyboard Layout"
loadkeys de-latin1

# check internet connection by pinging gnu.org
echo "Checking Network Connection"
ping -c 1 -W 1 gnu.org >/dev/null 2>&1 && echo "Network Connection Verified" || exit 2

echo "selecting repos"
# pings each in order to rank them by speed
reflector --country Germany --latest 15 --sort rate --save /etc/pacman.d/mirrorlist

echo "Erasing $drive if you input the wrong drive, cancel now!"

sleep 5

echo "Starting format. Now it's really not my problem anymore"

echo "Unmounting $drive"
umount ${drive}* 2>/dev/null

echo "Deleting existing partitions..."
echo -e "o\nw" | fdisk $drive

echo "creating boot partition"
echo -e "n\np\n1\n\n+1G\nw" | fdisk $drive

echo "Creating / partition..."
echo -e "n\np\n2\n\n\nw" | fdisk $drive
echo partitions created

mkfs.fat -F32 ${drive}1
mkfs.ext4 ${drive}2

echo "Mounting partitions"

mount --mkdir ${drive}2 /mnt
mount --mkdir ${drive}1 /mnt/boot
echo "partitions mounted"
lsblk
sleep 3

echo "pacstrap, only latest kernel, no nvidia, defaulting to intel-ucode, if amd cpu is used, replace with amd-ucode"
pacstrap -K /mnt base linux linux-firmware base-devel intel-ucode networkmanager neovim ntp grub efibootmgr

echo "generating fstab"
genfstab -U /mnt >>/mnt/etc/fstab
cat /mnt/etc/fstab

# Chrooting into a system means changing the entire environment which would lead to the script essentially pausing until the chroot environment is exited.
# Instead the rest of this script will be piped into bash directly.
#
# Could probably be done cleaner.
echo "chrooting into installation"
arch-chroot /mnt bash <<EOF

echo "installing bootlader"
# expects efi at this point
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck --no-floppy
grub-mkconfig -o /boot/grub/grub.cfg

echo "configuring localization"

echo "setting time"
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc
#service to get network time
systemctl enable ntpd.service

echo "setting language"
# removes # in front of desired lines
sed -i 's/^#de_DE.UTF-8/de_DE.UTF-8/' /etc/locale.gen
sed -i 's/^#de_DE@euro/de_DE@euro/' /etc/locale.gen
locale-gen
echo "LANG=de_DE.UTF-8" >/etc/locale.conf
echo "KEYMAP=de-latin1" >/etc/vconsole.conf

echo "networking"
systemctl enable NetworkManager
touch /etc/hostname
echo "archbtw" >/etc/hostname

EOF
