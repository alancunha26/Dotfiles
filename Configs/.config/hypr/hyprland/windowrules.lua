-- █░█░█ █ █▄░█ █▀▄ █▀█ █░█░█   █▀█ █░█ █░░ █▀▀ █▀
-- ▀▄▀▄▀ █ █░▀█ █▄▀ █▄█ ▀▄▀▄▀   █▀▄ █▄█ █▄▄ ██▄ ▄█
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- Sizes and positions are math expressions (variables: monitor_w, monitor_h,
-- window_w, window_h, cursor_x, cursor_y), not percentages: "50% 50%" fails
-- silently, so half the screen is "monitor_w*0.5 monitor_h*0.5".
-- class/title patterns must match the whole string: "Settings - .*", not "^Settings - ".

local function rule(match, props)
    props.match = match
    hl.window_rule(props)
end

-- idleinhibit rules
rule({ class = ".*celluloid.*|.*mpv.*|.*vlc.*" }, { idle_inhibit = "fullscreen" })
rule({ class = ".*[Ss]potify.*" }, { idle_inhibit = "fullscreen" })
rule({ class = ".*LibreWolf.*|.*floorp.*|.*brave-browser.*|.*firefox.*|.*chromium.*|.*zen.*|.*vivaldi.*" }, { idle_inhibit = "fullscreen" })

-- Picture-in-Picture
rule({ title = "[Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture.*" }, {
    float             = true,
    keep_aspect_ratio = true,
    move              = "monitor_w*0.73 monitor_h*0.72",
    size              = "monitor_w*0.25 monitor_h*0.25",
    pin               = true,
})

rule({ class = "org.kde.dolphin", title = "Progress Dialog — Dolphin" }, { float = true })
rule({ class = "org.kde.dolphin", title = "Copying — Dolphin" }, { float = true })
rule({ title = "About Mozilla Firefox" }, { float = true })
rule({ class = "firefox", title = "Picture-in-Picture" }, { float = true })
rule({ class = "firefox", title = "Library" }, { float = true })

-- Obsidian opens its settings as a separate window (same class, title "Settings - <vault> - Obsidian")
rule({ class = "^md\\.obsidian\\.Obsidian$", title = "Settings - .*" }, {
    float  = true,
    size   = "monitor_w*0.6 monitor_h*0.7",
    center = true,
})

-- Floating apps
for _, class in ipairs({
    "top", "htop", "vlc", "kvantummanager", "qt5ct", "qt6ct", "nwg-look", "org.kde.ark",
    "org.pulseaudio.pavucontrol", "nm-applet", "Signal", "com.github.rafostar.Clapper",
    "app.drey.Warp", "net.davidotek.pupgui2", "yad", "eog", "io.github.alainm23.planify",
    "io.gitlab.theevilskeleton.Upscaler", "com.github.unrud.VideoDownloader",
    "io.gitlab.adhami3310.Impression", "io.missioncenter.MissionCenter", "org.gnome.Nautilus",
    "org.pwmt.zathura", "zoom",
}) do
    rule({ class = class }, { float = true })
end

-- Float Steam
rule({ class = "steam" }, { float = true, opacity = "1 1" })
rule({ class = "steam", title = "Steam" }, { center = true, size = "1100 700" })
rule({ class = "steam", title = "Friends List" }, { size = "460 800" })

-- Floating with custom sizes
for _, class in ipairs({ "mpv", "nm-connection-editor", "wiremix", "top", "htop", "btop", "dots-check" }) do
    rule({ class = class }, { float = true, size = "monitor_w*0.5 monitor_h*0.5" })
end
rule({ class = "org.corectrl.CoreCtrl" }, { float = true, size = "monitor_w*0.75 monitor_h*0.75" })
-- the calculator stays on top (pinned: also on every workspace); Super+T unpins it
rule({ class = "org.gnome.Calculator" }, { float = true, center = true, pin = true })

-- cliamp lives on the hidden "music" workspace and keeps playing there (Super+M)
rule({ class = "^cliamp$" }, {
    workspace = "special:music silent",
    float     = true,
    size      = "monitor_w*0.6 monitor_h*0.7",
    center    = true,
})

-- Common modals
for _, title in ipairs({
    "Open", "Authentication Required", "Add Folder to Workspace", "Open File", "Choose Files",
    "Save As", "Confirm to replace files", "File Operation Progress", "File Upload.*",
    "Choose wallpaper.*", "Library.*", ".*dialog.*",
}) do
    rule({ title = title }, { float = true })
end
rule({ class = "[Xx]dg-desktop-portal-gtk" }, { float = true })
rule({ class = ".*dialog.*" }, { float = true })

-- Ignore maximize requests from apps. You'll probably like this.
rule({ class = ".*" }, { suppress_event = "maximize" })

-- Fix some dragging issues with XWayland
rule({ class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false }, { no_focus = true })

-- XWayland Video Bridge - hide main window when sharing screen
rule({ class = "xwaylandvideobridge" }, {
    opacity          = "0.0 override",
    no_anim          = true,
    no_initial_focus = true,
    max_size         = "1 1",
    no_blur          = true,
    no_focus         = true,
})

-- ueberzugpp disable animations and hyprland flare
rule({ class = "ueberzug.*" }, {
    no_anim          = true,
    no_blur          = true,
    max_size         = "1 1",
    no_initial_focus = true,
    no_focus         = true,
})

-- Godot specifics
hl.window_rule({
    name  = "Godot Float Internal Windows",
    match = { class = "^Godot$" },
    float = true,
    tile  = false,
})
hl.window_rule({
    name  = "Godot Tile Main Window",
    match = { class = "^Godot$", initial_title = "^Godot$" },
    float = false,
    tile  = true,
})

-- █░░ ▄▀█ █▄█ █▀▀ █▀█   █▀█ █░█ █░░ █▀▀ █▀
-- █▄▄ █▀█ ░█░ ██▄ █▀▄   █▀▄ █▄█ █▄▄ ██▄ ▄█
-- ignore_alpha skips blur on pixels at or below that opacity: 0 blurs everything
-- the layer draws (the old `ignorezero`); 1 would skip every pixel, so no blur at all
for namespace, alpha in pairs({
    rofi = 0,
    kitty = 0,
    waybar = 0.3,
    notifications = 0,
    ["swaync-notification-window"] = 0,
    ["swaync-control-center"] = 0,
}) do
    hl.layer_rule({ match = { namespace = namespace }, blur = true, ignore_alpha = alpha })
end
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true })

-- No animation on slurp's selection overlay, so it never shows up in screenshots/recordings
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })
