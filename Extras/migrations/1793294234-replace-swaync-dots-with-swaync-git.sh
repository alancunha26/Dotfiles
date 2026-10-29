echo "Replacing swaync with swaync-git (calendar widget)"

# swaync-git conflicts with swaync and with the short-lived patched swaync-dots,
# so the packages step can't swap them on its own: remove the installed one here
# and that step builds swaync-git from core.txt.
if ! pacman -Qq swaync-git &>/dev/null; then
  for p in swaync-dots swaync; do
    if pacman -Qq "$p" &>/dev/null; then sudo pacman -Rdd --noconfirm "$p"; fi
  done
fi
