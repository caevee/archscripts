#!/bin/bash -e

greeting() {
  # Greeting
  echo "This is a guided script to receive caevees Openbox rice. This is intended to be used on fresh installs or in addition to caevees installscript."
}

setup_ethernet() {
  # Setup ethernet.
  read -r -p "Do you want to use ethernet? (y/n) " ethernet
  if [ "${ethernet}" = "y" ]; then
    # Enables systemd dhcpcd service.
    systemctl enable dhcpcd
  fi
}

setup_wifi() {
  # Setup WiFi.
  read -r -p "Do you want to use WiFi? (y/n) " wifi
  if [ "${wifi}" = "y" ]; then
    
    read -r -p "What is it called? " wifi_name
    read -r -p "What is change the password? " wifi_password
    read -r -p "What is your wifi interface? " wifi_interface
  
    # Copy netctl example profile.
    cp /etc/netctl/examples/wireless-wpa /etc/netctl/"${wifi_name}"
  
    # Insert needed details.
    sed -i "s/MyNetwork/${wifi_name}/" /etc/netctl/"${wifi_name}" # Change interface, ESSID, Key [Password]
    sed -i "s/WirelessKey/${wifi_password}/" /etc/netctl/"${wifi_name}"
    sed -i "s/wlan0/${wifi_interface}/" /etc/netctl/"${wifi_name}"
 
    # Start the WiFi connection.
    netctl start "${wifi_name}"
  fi
} 

set_locale_and_keymap() {
  # Set locale
  read -r -p "What language is your OS supposed to be in? (de, us, ru,) " locale
  if [ "${locale}" = "de" ]; then
    localectl set-locale LANG='de_DE.UTF-8'
  elif [ "${locale}" = "us" ]; then
    localectl set-locale LANG='en_US.UTF-8'
  elif [ "${locale}" = "ru" ]; then
    localectl set-locale LANG='ru_RU.UTF-8'
  fi

  # Set keymap
  read -r -p "What permanent keymap do you want to use? " keymap
  localectl set-keymap --no-convert "${keymap}"
}

install_extra_kernels() {
  # Install extra kernels.
  read -r -p "Do you want to install an extra kernel? (y/n) " kernel
  if [ "${kernel}" = "y" ]; then

    read -r -p "Do you want to install linux-hardened? (y/n) " linux_hardened
    if [ "${linux_hardened}" = "y" ]; then
      # Install linux-hardened.
      pacman -S --noconfirm -q linux-hardened >/dev/null

      # Generate initcpio.
      mkinitcpio -p linux-hardened

      # Generate new GRUB configuration.
      grub-mkconfig -o /boot/grub/grub.cfg
    fi

    read -r -p "Dou you want to install linux-lts? (y/n) " linux_lts
    if [ "${linux_lts}" = "y" ]; then
      # Install linux-lts.
      pacman -S --confirm -q linux-lts >/dev/null
      
      # Generate initcpio.
      mkinitcpio -p linux-hardened

      # Generate new GRUB configuration.
      grub-mkconfig -o /boot/grub/grub.cfg
    fi
  fi
}

set_root_password() {
  # Set root password.
  read -r -p "Do you want to set a root password? (y/n) " rootpass
  if [ "${rootpass}" = "y" ]; then
    passwd
  fi
}

install_packages() {
    # Add multilib repo
  read -r -p "Do you want to add the multilib repo to pacman.conf? This allows you to run 32-bit programs. (y/n) " multilib
  if [ "${multilib}" = "y" ]; then
    sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

    # Updates mirrorlists.
    pacman -Syyy
  fi

  read -r -p "Do you want to install all neccessary packages to copy caevees rice? (y/n) " allpackages
  if [ "${allpackages}" = "y" ]; then
    # Install packages
    pacman -S --noconfirm -q vim git xorg openbox obconf lxappearance lxappearance-obconf menumaker tint2 firefox mousepad flameshot mpv ranger w3m thunar rxvt-unicode htop xterm arandr go network-manager-applet polkit mate-polkit rofi networkmanager lightdm lightdm-gtk-greeter feh imagemagick python-pip python-pywal expac yajl otf-overpass archlinux-wallpaper libmtp simplescreenrecorder bash-completion cron
  fi
    # Add touchpad support.
  read -r -p "Do you want touchpad support? (y/n) " touchpad
  if [ "${touchpad}" = "y" ]; then
    pacman -S --noconfirm -q xf86-input-libinput >/dev/null
  fi
  # Install sudo.
  read -r -p "Do you want to install and configure sudo? (y/n) " sudo
  if [ "${sudo}" = "y" ]; then
    # Installs sudo.
    pacman -S --noconfirm -q sudo >/dev/null

    # Allows members of the wheel group to use sudo.
    sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
  fi
}

configure_system() {
  # Add user.
  read -r -p "Do you want to add a user? (y/n) " user
  if [ "${user}" = "y" ]; then
    read -r -p "What Name? " username

    # Create new user in the wheel group with a home directory and set its default shell to bash.
    useradd -m -G wheel -s /bin/bash "${username}"
    read -r -p "Do you want to set a password for your user? (y/n) " passwduser
    if [ "${passwduser}" = "y" ]; then
      passwd "${username}"
    fi
  fi

  # Change the hostname
  read -r -p "Do you want to change the hostname? (y/n) " change_hostname
  if [ "${change_hostname}" = "y" ]; then
    read -r -p "What do you want your hostname to be? " new_hostname

    # Set the hostname

    hostnamectl set-hostname "${new_hostname}"
  fi
}

enable_necessary_stuff() {
  systemctl enable lightdm.service
}

# Install yay.
install_yay() {
  read -r -p "Do you want to install yay? (y/n) " install_yay
  if [ "${install_yay}" = "y" ]; then
    # Create a yay user.
    useradd -m --home-dir /home/yay -s /bin/bash yay

    # Allow the yay user to run sudo without a password.
    echo "yay ALL=(ALL) ALL NOPASSWD: ALL" | tee -a /etc/sudoers >/dev/null

    # Clone yay.
    git clone https://aur.archlinux.org/yay.git /home/yay/yay
    chown yay -R /home/yay
    continue_yay_installation="y"

    # Verify PKGBUILD.
    read -r -p "Do you want to verify the yay PKGBUILD? (y/n) " verify_yay_pkgbuild
    if [ "${verify_yay_pkgbuild}" = "y" ]; then
      less /home/yay/yay/PKGBUILD

      # Allow the user to stop yay from being installed.
      read -r -p "Continue installing yay? (y/n) " continue_yay_installation
    fi

    if [ "${continue_yay_installation}" = "y" ]; then
      # Install yay as the yay user.
      sudo -u yay sh -c "cd /home/yay/yay && makepkg -si"
    else
      echo "Yay has not been installed."
    fi

    # Delete yay user.
    userdel -rf yay
    sed -i 's/yay ALL=(ALL) ALL NOPASSWD: ALL//' /etc/sudoers
  fi
  }

copy_rice() {
  wget https://raw.githubusercontent.com/caevee/archscripts/master/rice.sh -P /home/caevee/
}

# Call the functions

greeting
setup_ethernet
setup_wifi
set_locale_and_keymap
install_extra_kernels
set_root_password
install_packages
configure_system
enable_necessary_stuff
copy_rice

# Reboot
read -r -p "Post-Install finished. Do you want to reboot? (y/n) " reboot
if [ "${reboot}" = "y" ]; then
  reboot
fi

