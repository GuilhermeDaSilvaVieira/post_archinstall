#! /usr/bin/env bash

install_paru() {
  # AUR Helper (Paru)
  cd &&
  git clone https://aur.archlinux.org/paru-bin.git &&
  cd paru-bin &&
  makepkg -sri --noconfirm &&
  cd &&
  rm -rf paru-bin &&
  echo "" &&
  echo "Paru installed" &&
  echo ""
}

configure_pacman_and_paru() {
  # Pacman config
  sed -i 's/#Color/Color/' /etc/pacman.conf &&
  sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 20/' /etc/pacman.conf &&
  sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf &&
  sed -i '/^ParallelDownloads =/a ILoveCandy' /etc/pacman.conf &&
  sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf &&
  echo "" &&
  echo "Pacman configured" &&
  echo "" &&

  # Paru config
  sed -i 's/\#BottomUp/BottomUp/' /etc/paru.conf &&
  sed -i 's/\#RemoveMake/RemoveMake/' /etc/paru.conf &&
  sed -i 's/\#CleanAfter/CleanAfter/' /etc/paru.conf &&
  sed -i 's/\#\[bin\]/\[bin\]/' /etc/paru.conf &&
  sed -i 's/\#FileManager = vifm/FileManager = yazi/' /etc/paru.conf
  echo "" &&
  echo "Paru configured" &&
  echo ""
}

cmd_to_be_executed_as_super_user() {
  
  # Increase time without sudo prompt
  echo 'Defaults        timestamp_timeout=15' >> /etc/sudoers &&
  echo "" &&
  echo "Sudo time without prompt increased" &&
  echo "" &&

  # Set systemd-boot timeout to 0
  sed -i 's/timeout 3/timeout 0/' /boot/loader/loader.conf &&
  echo "" &&
  echo "Systemd-boot timeout set to 0" &&
  echo "" &&

  # Set VTs to 10
  sed -i 's/#NAutoVTs=6/NAutoVTs=12/' /etc/systemd/logind.conf &&
  echo "" &&
  echo "Increase VTs to 10" &&
  echo "" &&

  # Set locale (Used en_US in arch installer)
  sed -i 's/#pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/' /etc/locale.gen &&
  sed -i 's/#en_IE.UTF-8 UTF-8/en_IE.UTF-8 UTF-8/' /etc/locale.gen &&
  locale-gen &&
  echo 'LC_ADDRESS=pt_BR.UTF-8' >> /etc/locale.conf &&
  echo 'LC_MEASUREMENT=pt_BR.UTF-8' >> /etc/locale.conf &&
  echo 'LC_MONETARY=pt_BR.UTF-8' >> /etc/locale.conf &&
  echo 'LC_NAME=pt_BR.UTF-8' >> /etc/locale.conf &&
  echo 'LC_NUMERIC=pt_BR.UTF-8' >> /etc/locale.conf &&
  echo 'LC_PAPER=pt_BR.UTF-8' >> /etc/locale.conf &&
  echo 'LC_TELEFONE=pt_BR.UTF-8' >> /etc/locale.conf &&
  echo 'LC_TIME=en_IE.UTF-8' >> /etc/locale.conf &&
  echo "" &&
  echo "Locale set" &&
  echo "" &&

  # All users (previously defined in arch installer)
  USERS=(
  "root"
  "luffy"
  "zoro"
  "nami"
  "usopp"
  "sanji"
  "chopper"
  "robin"
  "franky"
  "brook"
  "jinbe"
  )

  # User treatment
  for user in "${USERS[@]}";
  do
      # Add .xinitrc with exec awesome to /home/$USER/
      echo "cp /etc/X11/xinit/xinitrc ~/ &&
      head -n -5 ~/xinitrc > ~/temp &&
      echo 'exec awesome' >> ~/temp  &&
      rm ~/xinitrc &&
      mv ~/temp ~/.xinitrc" | su $user &&

      # Set default programs
      echo "xdg-mime default org.pwmt.zathura.desktop application/pdf &&
      xdg-mime default zen.desktop x-scheme-handler/https &&
      xdg-mime default zen.desktop x-scheme-handler/http" | su $user &&

      # Sync .dotfiles
      echo "cd &&
      git clone https://github.com/guilhermedasilvavieira/.dotfiles &&
      .dotfiles/install.sh" | su $user &&

      # Set gtk theme, icons and cursor
      echo 'gsettings set org.gnome.desktop.interface gtk-theme "Nordic-bluish-accent" &&
      gsettings set org.gnome.desktop.interface icon-theme "Tela circle orange dark" &&
      gsettings set org.gnome.desktop.interface cursor-theme "Nordzy-cursors"' | su $user &&

      # Define fish as main shell
      usermod -s /bin/fish $user &&

      echo "" &&
      echo "$user done" &&
      echo ""
  done
  usermod -aG libvirt franky &&
  echo "" &&
  echo "franky added to libvirt" &&
  echo "" &&

  # Change tty colorscheme
  echo 'colorscheme="cobalt-2"' > /etc/tty-colorscheme/tty-colorscheme.conf &&
  echo "" &&
  echo "TTY colorscheme changed" &&
  echo "" &&
  
  # All systems to be enabled
  SYSTEMS=(
    "libvirtd"
    "cups"
    "bluetooth"
    "tty-colorscheme"
    "syncthing@robin"
    "cronie"
    "docker"
    "tor"
  )

  # System Management
  for system in "${SYSTEMS[@]}";
  do
      systemctl enable --now $system
  done

  echo "" &&
  echo "Systems enabled" &&
  echo "" &&

  # Searxng
  cd /usr/local &&
  git clone https://github.com/searxng/searxng-docker.git &&
  cd searxng-docker &&
  sed -i "s|ultrasecretkey|$(openssl rand -hex 32)|g" searxng/settings.yml &&
  sed -i '/^\s*cap_drop:/s/^/# /' docker-compose.yaml &&
  sed -i '/^\s*- ALL/s/^/# /' docker-compose.yaml &&
  docker compose up -d &&
  sed 's/#/ /g' docker-compose.yaml &&
  cp searxng-docker.service.template searxng-docker.service &&
  systemctl enable --now $(pwd)/searxng-docker.service &&
  cd &&
  echo "" &&
  echo "Searxng active" &&
  echo "" &&

  # NVIDIA kernel modules
  sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf &&
  echo "" &&
  echo "NVIDIA kernel modules added" &&
  echo "" &&

  # Isolate programs to specific user
  mkdir -p /etc/pacman.d/hooks &&
  echo '[Trigger]' >> /etc/pacman.d/hooks/99-isolate-packages.hook &&
  echo 'Operation = Install' >> /etc/pacman.d/hooks/99-isolate-packages.hook &&
  echo 'Operation = Upgrade' >> /etc/pacman.d/hooks/99-isolate-packages.hook &&
  echo 'Operation = Remove' >> /etc/pacman.d/hooks/99-isolate-packages.hook &&
  echo 'Type = Package' >> /etc/pacman.d/hooks/99-isolate-packages.hook &&
  echo 'Target = *' >> /etc/pacman.d/hooks/99-isolate-packages.hook &&
  echo '' >> /etc/pacman.d/hooks/99-isolate-packages.hook &&
  echo '[Action]' >> /etc/pacman.d/hooks/99-isolate-packages.hook &&
  echo 'Description = Running my custom script after pacman/paru transaction...' >> /etc/pacman.d/hooks/99-isolate-packages.hook &&
  echo 'When = PostTransaction' >> /etc/pacman.d/hooks/99-isolate-packages.hook &&
  echo 'Exec = /home/franky/Development/Bash/post_archinstall/change_permissions.sh' >> /etc/pacman.d/hooks/99-isolate-packages.hook &&
  echo "" &&
  echo "Isolate packages hook active" &&
  echo ""
}

cp ./packages ~/ &&
sudo pacman --noconfirm --needed -Sy rustup &&
rustup default stable &&
install_paru &&
sudo bash -c "$(declare -f configure_pacman_and_paru); configure_pacman_and_paru" &&
paru --noconfirm --needed -Sy - < ./packages &&
rm ./packages &&
sudo bash -c "$(declare -f cmd_to_be_executed_as_super_user); cmd_to_be_executed_as_super_user"
