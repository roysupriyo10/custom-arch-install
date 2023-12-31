

echo "set root password"

passwd

echo "efi: "

read EFI

echo "root: "

read ROOT

echo "hostname: "

read HOSTNAME

echo "username: "

read USER

echo "passwd: "

read PASSWORD



timedatectl set-timezone Asia/Kolkata

echo -e "changed to Asia/Kolkata timezone"

mkfs.fat -F32 "${EFI}"

echo "formatted efi partition"

mkfs.ext4 "${ROOT}"

echo "formatted root partition"


echo "mounted efi partition to /mnt/boot/efi"

mount "${ROOT}" /mnt
mkdir /mnt/boot/
mkdir /mnt/boot/efi
mount "${EFI}" /mnt/boot/efi

echo "mounted root partition to /mnt"

pacman -Sy

echo "update pacman database"

pacman -S pacman-contrib

echo "install rankmirrors tool"

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

echo "backup previous mirrorlist"

rankmirrors -n 10 /etc/pacman.d/mirrorlist.bak > /etc/pacman.d/mirrorlist

echo "generated new mirror list"

pacstrap -K /mnt base base-devel linux linux-firmware linux-headers intel-ucode sudo vim git dhcpcd networkmanager --noconfirm --needed

echo "installed base, base-devel, kernel and other basics"

genfstab -U /mnt >> /mnt/etc/fstab

cat /mnt/etc/fstab

echo "generated file system table"

cat <<REALEND > /mnt/next.sh

useradd -m $USER
echo $USER:$PASSWORD | chpasswd
usermod -aG wheel,power,storage,audio $USER
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "added user ${USER}"

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen

echo "uncommented locale for locale-gen"

locale-gen

echo LANG=en_US.UTF-8 > /etc/locale.conf

ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

echo "synced hardware clock"

echo "${HOSTNAME}" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	${HOSTNAME}.localdomain	${HOSTNAME}
EOF

echo "added localhost to /etc/hosts and changed host name"

pacman -S grub efibootmgr dosfstools mtools --noconfirm --needed

echo "installed grub and relevant tools"

grub-install --target=x86_64-efi --bootloader-id=grub --recheck

echo "grub install done"

grub-mkconfig -o /boot/grub/grub.cfg

fallocate -l 11G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

systemctl enable dhcpcd
systemctl enable NetworkManager

echo "created necessary symlinks"

echo "set root passwd"

passwd

REALEND

arch-chroot /mnt sh next.sh
