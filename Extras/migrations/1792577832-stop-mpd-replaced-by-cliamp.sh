echo "Stopping mpd: cliamp replaces mpd, mpc and rmpc"

# The packages are no longer listed, so `dots prune` offers to remove them.
if systemctl --user is-enabled -q mpd.service 2>/dev/null; then
  systemctl --user disable --now mpd.service
fi
