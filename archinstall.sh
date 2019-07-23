#!/bin/bash -e

# Greeting
echo "Hello this is caevees Installscript which is heavily inspired by aidans script. "
sleep 2

# Shutdown
read -r -p "Do you want to start the Arch installation? Press 'n' to shutdown the computer. 'y' to start the script. " start
if [ "${start}" = "n" ]; then
  shutdown 0
fi

setup_wifi() {
  ## Setup WiFi.
  read -r -p "Do you want to use WiFi? (y/n) " wifi
  if [ "${wifi}" = "y" ]; then
    # Details needed to create connection.
    read -r -p "What is it called? " wifi_name
    read -r -p "What is the password " wifi_password

    # Show list of network interfaces.
    ip a
    read -r -p "What is your wifi interface? " wifi_interface

    # Copy netctl example profile
    cp /etc/netctl/examples/wireless-wpa /etc/netctl/"${wifi_name}"

    # Insert needed details.
    sed -i "s/MyNetwork/${wifi_name}/" /etc/netctl/"${wifi_name}" # Change interface, ESSID, Key [Password]
    sed -i "s/WirelessKey/${wifi_password}/" /etc/netctl/"${wifi_name}"
    sed -i "s/wlan0/${wifi_interface}/" /etc/netctl/"${wifi_name}" 

    # Start the WiFi connection.
    netctl start "${wifi_name}"
  fi
}

update_mirrorlist() {
  ## Update mirrorlist.
  # Move current mirrorlist for use as a backup.
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bkp

  read -r -p "What mirror location do you prefer? DE US RU or CH? " mirrorcountry

  # List of all currently supported mirrorlists.
  if [ "${mirrorcountry}" = "DE" ]; then
    wget -q -O /etc/pacman.d/mirrorlist "https://www.archlinux.org/mirrorlist/?country=DE&protocol=http&protocol=https&ip_version=4"
    sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist
    pacman -Syyy
  elif [ "${mirrorcountry}" = "US" ]; then
    wget -q -O /etc/pacman.d/mirrorlist "https://www.archlinux.org/mirrorlist/?country=US&protocol=http&protocol=https&ip_version=4"
    sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist
    pacman -Syyy
  elif [ "${mirrorcountry}" = "RU" ]; then
    wget -q -O /etc/pacman.d/mirrorlist "https://www.archlinux.org/mirrorlist/?country=RU&protocol=http&protocol=https&ip_version=4"
    sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist
    pacman -Syyy
  elif [ "${mirrorcountry}" = "CH" ]; then
    wget -q -O /etc/pacman.d/mirrorlist "https://www.archlinux.org/mirrorlist/?country=CH&protocol=http&protocol=https&ip_version=4"
    sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist
    pacman -Syyy
  fi
}
    
partition_drive() {
  # Show the user their drives.
  fdisk -l
  sleep 2

  # Ask what device to use and the size of the root partition.
  read -r -p "What drive to partition? Type /dev/sda if you have only one drive. " device
  read -r -p "How big do you want the root partition? Use 'GiB' or 'MiB' example: 300GiB to make it 300 Gegibytes big. Enter '100%' if you want it to fill up the rest of the drive. " rootsize

  # Check for UEFI
  if [ -d /sys/firmware/efi/ ]; then
    uefi=y
  fi

 # BIOS partitioning.
 if [ "${uefi}" = "n" ]; then
   # Create a new DOS partition layout.
   yes | parted "${device}" mklabel msdos

   # Create a EXT4 root partition.
   parted "${device}" mkpart primary ext4 1MiB "${rootsize}" 

   # Allow it to be booted into.
   parted "${device}" set 1 boot on

   # Format the partition.
   mkfs.ext4 "${device}"1

   # Mount the partition as /mnt
   mount "${device}"1 /mnt

   # For home partition.
   home_part="2"
 fi
 

 # UEFI partitioning.
 if [ "${uefi}" = "y" ]; then
   # Create a new GPT partition layout.
   yes | parted "${device}" mklabel gpt

   # Create a 551MiB FAT32 boot partition.
   parted "${device}" mkpart primary fat32 1MiB 551MiB
   parted "${device}" set 1 esp on

   # Format the boot partition.
   mkfs.fat -F32 "${device}"1

   # Create a EXT4 root partition.
   parted "${device}" mkpart primary ext4 551MiB "${rootsize}"

   # Format the root partition.
   mkfs.ext4 "${device}"2

   # Mount the root partition as /mnt.
   mount "${device}"2 /mnt

   # For home partition.
   home_part="3"
 fi

 # Create a home partition.
 read -r -p "Do you want a seperate home partition? (y/n) " wanthome
 if [ "${wanthome}" = "y" ]; then
   read -r -p "How big do you want the home partition? Use 'GiB' or 'MiB'. '100%' to fill up the rest of the drive. " homesize

   # Create a EXT4 home partition.
   parted "${device}" mkpart primary ext4 "${rootsize}" "${homesize}"

   # Format the home partition.
   mkfs.ext4 "${device}""${home_part}"

   # Create a home directory and mount the drive .
   mkdir /mnt/home
   mount "${device}""${home_part}" /mnt/home
 fi
}

installation() {
  # Install base packages with pacstrap.
  pacstrap -i /mnt base base-devel

  # Generate /etc/fstab.
  genfstab -U -p /mnt >> /mnt/etc/fstab

  # Create the script to be run in the chroot.
  cat <<EOF > /mnt/root/archinstall-part2.sh
#!/bin/bash

# Install packages needed for GRUB. linux-headers isn't really needed but will help.
if [ "${uefi}" = "n" ]; then
  pacman -S --noconfirm -q grub-bios linux-headers
elif [ "${uefi}" = "y" ]; then
  pacman -S --noconfirm -q grub efibootmgr dosfstools mtools linux-headers
fi

# Generate inicpio.
mkinitcpio -p linux

# Set locale.
read -r -p "What language is your OS supposed to be in? (de, us, ru,) " locale
if [ "${locale}" = "de" ]; then
  sed -i 's/#de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen
elif [ "${locale}" = "us" ]; then
  sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
elif [ "${locale}" = "ru" ]; then
  sed -i 's/#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
fi

# Generate locale.
locale-gen

if [ "${uefi}" = "y" ]; then
  # Install GRUB for UEFI.
  mkdir /boot/EFI
  mount "${device}"1 /boot/EFI
  grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
elif [ "${uefi}" = "n" ]; then
  # Install GRUB for BIOS.
  grub-install --target=i386-pc --recheck "${device}"
fi

# Set GRUB locale.
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

# Generate GRUB configuration file.
grub-mkconfig -o /boot/grub/grub.cfg

# Download postinstall.sh
pacman -S wget --noconfirm
wget https://raw.githubusercontent.com/caevee/archscripts/master/postinstall.sh -P /root/

# Exit the chroot.
exit
EOF
  # Make the script executable.
  chmod +x /mnt/root/archinstall-part2.sh

  # Chroot into system and run the script.
  arch-chroot /mnt /root/archinstall-part2.sh
}

last_steps() {
  # Umount all partitions.
  umount -a

  # Reboot.
  read -r -p "Install finished. You should now reboot, log into root and run 'sh postinstall.sh'."
  read -r -p "Do you want to reboot or keep making changes? y for reboot n for changes. (y/n) " reboot
  if [ "${reboot}" = "y" ]; then
    reboot
  fi
}

setup_wifi
update_mirrorlist
partition_drive
installation
last_steps
