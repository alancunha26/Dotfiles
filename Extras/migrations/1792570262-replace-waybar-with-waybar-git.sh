echo "Replacing waybar with waybar-git (Lua-config support for clicking workspaces)"

# waybar and waybar-git conflict, so the packages step can't swap them on its
# own: remove waybar here and that step installs waybar-git from core.txt.
if pacman -Qq waybar &>/dev/null && ! pacman -Qq waybar-git &>/dev/null; then
  sudo pacman -Rdd --noconfirm waybar
fi
