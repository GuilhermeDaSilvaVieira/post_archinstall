#! /usr/bin/env bash

# TODO:
# 1. If group doesn't exists create it
# 2. Make a list of executables and desktop entries
# 3. Change permissions

change_permissions () {
  local executables=("${!1}")
  local desktop_entries=("${!2}")
  local group_name="$3"
  local user_name="$4"

  # Create group if it doesn't exist
  if ! getent group "$group_name" > /dev/null 2>&1; then
    groupadd "$group_name"
  fi

  # Add user to group (if not already a member)
  if ! id -nG "$user_name" | grep -qw "$group_name"; then
    usermod -aG "$group_name" "$user_name"
  fi

  for executable in "${executables[@]}"; do
    local path="/bin/$executable"
    if [ -e "$path" ]; then
      chown root:"$group_name" "$path"
      chmod 750 "$path"
    else
      echo "Warning: Executable not found: $path"
    fi
  done

  for desktop_entry in "${desktop_entries[@]}"; do
    local path="/usr/share/applications/$desktop_entry.desktop"
    if [ -e "$path" ]; then
      chown root:"$group_name" "$path"
      chmod 750 "$path"
    else
      echo "Warning: Desktop entry not found: $path"
    fi
  done
}

# Nami
nami_executables=(
  "tradingview"
)
nami_desktop_entries=(
  "tradingview"
)
change_permissions nami_executables[@] nami_desktop_entries[@] nami_only nami
echo ""
echo "nami programs isolated"
echo ""

# Robin
robin_executables=(
  "obsidian"
)
robin_desktop_entries=(
  "obsidian"
)
change_permissions robin_executables[@] robin_desktop_entries[@] robin_only robin
echo ""
echo "robin programs isolated"
echo ""

# Franky
franky_executables=(
  "lazygit"
  "gitui"
  "lldb"
  "mise"
  "rust-analyzer"
  "rustup"
  "bash-language-server"
  "basedpyright"
  "basedpyright-langserver"
  "ruff"
  "black"
  "blackd"
  "dnsmasq"
  "virt-manager"
  "chromium"
  "android-studio"
  "code"
)
franky_desktop_entries=(
  "virt-manager"
  "chromium"
  "android-studio"
  "code"
)
change_permissions franky_executables[@] franky_desktop_entries[@] franky_only franky
echo ""
echo "franky programs isolated"
echo ""

# Usopp
usopp_executables=(
  "ani-cli"
  "mangohud"
  "steam"
  "discord"
)
usopp_desktop_entries=(
  "steam"
  "discord"
)
change_permissions usopp_executables[@] usopp_desktop_entries[@] usopp_only usopp
echo ""
echo "usopp programs isolated"
echo ""
