# Simple script that installs arch to my preferences. A lot of assumptions are made and I do not expect this to work on any computer.
# Besides that it automatically installs my configs.

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

echo "updating"
pacman -Syu --noconfirm >/dev/null

echo "installing necessary packages"
# pacman -S grub --noconfirm >/dev/null

echo "selecting repos"
reflector --country Germany --latest 15 --sort rate --save /etc/pacman.d/mirrorlist

echo "Erasing $drive if you input the wrong drive, that's kinda not my problem tbh"

sleep 5

echo "Starting format. Now it's really not my problem anymore"

echo "Unmounting $drive"
umount ${drive}* 2>/dev/null

echo "Deleting existing partitions..."
echo -e "o\nw" | fdisk $drive

sleep 2 # just to be sure

echo "done"

echo "creating boot partition"
echo -e "n\np\n1\n\n+1G\nw" | fdisk $drive

echo "Creating / partition..."
echo -e "n\np\n2\n\n\nw" | fdisk $drive

sleep 2
echo partitions created

mkfs.fat -F 32 ${drive}1
mkfs.ext4 ${drive}2

sleep 2

echo "Mounting partitions"
mkdir -p /mnt/boot

mount --mkdir ${drive}2 /mnt
mount ${drive}1 /mnt/boot
echo "partitions mounted"
lsblk

echo "pacstrap, only latest kernel, no nvidia, defaulting to intel-ucode, if amd cpu is used, replace with amd-ucode, BIOS based systems will not work with rEFInd"
pacstrap -K /mnt base linux linux-firmware base-devel intel-ucode networkmanager neovim ntp refind

echo "generating fstab"
genfstab -U /mnt >>/mnt/etc/fstab
cat /mnt/etc/fstab

echo "chrooting into installation"
arch-chroot /mnt

echo "configuring localization"

echo "setting time"
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc
systemctl enable ntpd.service

echo "setting language"
sed -i 's/^#de_DE.UTF-8/de_DE.UTF-8/' /etc/locale.gen
sed -i 's/^#de_DE@euro/de_DE@euro/' /etc/locale.gen
locale-gen
echo "LANG=de_DE.UTF-8" >/etc/locale.conf
echo "KEYMAP=de-latin1" >/etc/vconsole.conf

echo "networking"
systemctl enable NetworkManager --now
touch /etc/hostname
echo "archbtw" >/etc/hostname

echo "installing rEFInd bootlader"
refind-install

echo "choose your root password"
passwd

#echo "Installing GRUB"
#grub-install --target=x86_64-efi --efi-directory=/mnt/boot --bootloader-id=grub --recheck --no-floppy
#chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
