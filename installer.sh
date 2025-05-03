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

  # Isolate programs to specific user
  # Nami
  groupadd nami_only &&
  usermod -aG nami_only nami &&
  chown root:nami_only /bin/tradingview /usr/share/applications/tradingview.desktop &&
  chmod 750 /bin/tradingview /usr/share/applications/tradingview.desktop &&
  echo "" &&
  echo "Nami programs isolated" &&
  echo "" &&

  # Robin
  groupadd robin_only &&
  usermod -aG robin_only robin &&
  chown root:robin_only /bin/obsidian /usr/share/applications/obsidian.desktop &&
  chmod 750 /bin/obsidian /usr/share/applications/obsidian.desktop &&
  echo "" &&
  echo "Robin programs isolated" &&
  echo "" &&

  # Franky
  groupadd franky_only &&
  usermod -aG franky_only franky &&
  chown root:franky_only /bin/lazygit &&
  chmod 750 /bin/lazygit &&
  chown root:franky_only /bin/gitui &&
  chmod 750 /bin/gitui &&
  chown root:franky_only /bin/lldb &&
  chmod 750 /bin/lldb &&
  chown root:franky_only /bin/mise &&
  chmod 750 /bin/mise &&
  chown root:franky_only /bin/rust-analyzer &&
  chmod 750 /bin/rust-analyzer &&
  chown root:franky_only /bin/rustup &&
  chmod 750 /bin/rustup &&
  chown root:franky_only /bin/bash-language-server &&
  chmod 750 /bin/bash-language-server &&
  chown root:franky_only /bin/basedpyright &&
  chmod 750 /bin/basedpyright &&
  chown root:franky_only /bin/basedpyright-langserver &&
  chmod 750 /bin/basedpyright-langserver &&
  chown root:franky_only /bin/ruff &&
  chmod 750 /bin/ruff &&
  chown root:franky_only /bin/black &&
  chmod 750 /bin/black &&
  chown root:franky_only /bin/blackd &&
  chmod 750 /bin/blackd &&
  chown root:franky_only /bin/dnsmasq &&
  chmod 750 /bin/dnsmasq &&
  chown root:franky_only /bin/virt-manager /usr/share/applications/virt-manager.desktop &&
  chmod 750 /bin/virt-manager /usr/share/applications/virt-manager.desktop &&
  chown root:franky_only /bin/chromium /usr/share/applications/chromium.desktop &&
  chmod 750 /bin/chromium /usr/share/applications/chromium.desktop &&
  chown root:franky_only /bin/android-studio /usr/share/applications/android-studio.desktop &&
  chmod 750 /bin/android-studio /usr/share/applications/android-studio.desktop &&
  chown root:franky_only /bin/code /usr/share/applications/code.desktop &&
  chmod 750 /bin/code /usr/share/applications/code.desktop &&
  echo "" &&
  echo "Franky programs isolated" &&
  echo "" &&

  # Usopp
  groupadd usopp_only &&
  usermod -aG usopp_only usopp &&
  chown root:usopp_only /bin/ani-cli &&
  chmod 750 /bin/ani-cli  &&
  chown root:usopp_only /bin/mangohud &&
  chmod 750 /bin/mangohud  &&
  chown root:usopp_only /bin/steam /usr/share/applications/steam.desktop &&
  chmod 750 /bin/steam /usr/share/applications/steam.desktop &&
  chown root:usopp_only /bin/discord /usr/share/applications/discord.desktop &&
  chmod 750 /bin/discord /usr/share/applications/discord.desktop
  echo "" &&
  echo "Usopp programs isolated" &&
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
