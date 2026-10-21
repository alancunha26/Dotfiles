-- ░█▀█░█░░░█▀█░█▀█░░░█▀▀░█░█░█▀█░█░█░█▀█
-- ░█▀█░█░░░█▀█░█░█░░░█░░░█░█░█░█░█▀█░█▀█
-- ░▀░▀░▀▀▀░▀░▀░▀░▀░░░▀▀▀░▀▀▀░▀░▀░▀░▀░▀░▀
-- ======================================
-- Autostart necessary processes and apps
-- Full documentation: https://wiki.hypr.land/Useful-Utilities/Systemd-start

hl.on("hyprland.start", function()
    -- Autostart scripts
    -- hl.exec_cmd("uwsm app -- $HOME/.local/bin/reset-xdg-portal")
    hl.exec_cmd('xrdb -load "$HOME/.Xresources"')
    hl.exec_cmd("nwg-look -a")

    -- Share picker system theme fix
    hl.exec_cmd("uwsm app -- dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("uwsm app -- systemctl --user import-environment QT_QPA_PLATFORMTHEME WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Everything else
    hl.exec_cmd("uwsm app -t service -s s -- dunst")
    hl.exec_cmd("uwsm app -t service -s a -- nm-applet --indicator")
    hl.exec_cmd("uwsm app -t service -s s -- wl-paste --type text --watch cliphist store")
    hl.exec_cmd("uwsm app -t service -s s -- wl-paste --type image --watch cliphist store")
    hl.exec_cmd("uwsm app -t service -s s -- wl-clip-persist --clipboard regular")
    hl.exec_cmd("uwsm app -t service -s a -- udiskie --no-automount --smart-tray")
end)
