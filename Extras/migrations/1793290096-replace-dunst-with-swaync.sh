echo "Replacing dunst with swaync"

# Both ship a D-Bus activation file for org.freedesktop.Notifications, so dunst
# has to go rather than wait for `dots prune`. The packages step installs swaync
# from core.txt; it takes over at the next login (or start it by hand).
if pacman -Qq dunst &>/dev/null; then
  pkill -x dunst || true
  sudo pacman -Rns --noconfirm dunst
fi
