-- ░█▀█░█░░░█▀█░█▀█░░░█▀▀░█░█░█▀█░█░█░█▀█
-- ░█▀█░█░░░█▀█░█░█░░░█░░░█░█░█░█░█▀█░█▀█
-- ░▀░▀░▀▀▀░▀░▀░▀░▀░░░▀▀▀░▀▀▀░▀░▀░▀░▀░▀░▀
-- ======================================
-- Full documentation: https://wiki.hypr.land/Configuring/Basics/Binds/

local mainMod   = "SUPER" -- Sets "Windows" key as main modifier
local rofi      = "$HOME/.config/rofi/"
local grimblast = "$HOME/.local/bin/grimblast"
local wfrecord  = "$HOME/.local/bin/wf-record"

local bind = hl.bind

local function exec(cmd)
    return hl.dsp.exec_cmd(cmd)
end

-- Apps and tools
bind(mainMod .. " + RETURN",         exec("$TERMINAL"), { description = "Terminal" })
bind(mainMod .. " + Q",              hl.dsp.window.close(), { description = "Close window" })
bind(mainMod .. " + E",              exec("nautilus"), { description = "File manager" })
bind(mainMod .. " + F",              hl.dsp.window.float({ action = "toggle" }), { description = "Float/tile window" })
bind(mainMod .. " + SHIFT + F",      hl.dsp.window.fullscreen(), { description = "Fullscreen" })

-- Always on top: Hyprland only pins floating windows (a pinned window also shows on
-- every workspace), so a tiled window floats first and goes back to tiling when unpinned
local floated_to_pin = {}
bind(mainMod .. " + T", function()
    local w = hl.get_active_window()
    if not w then return end
    if w.pinned then
        hl.dispatch(hl.dsp.window.pin())
        if floated_to_pin[w.address] then
            hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
        end
        floated_to_pin[w.address] = nil
    else
        if not w.floating then
            hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
            floated_to_pin[w.address] = true
        end
        hl.dispatch(hl.dsp.window.pin())
    end
end, { description = "Always on top (on every workspace)" })
bind(mainMod .. " + SPACE",          exec(rofi .. "launcher.sh"), { description = "App launcher" })
bind(mainMod .. " + SHIFT + SPACE",  exec(rofi .. "finder.sh"), { description = "Find files" })
bind(mainMod .. " + Tab",            exec(rofi .. "window.sh"), { description = "Switch window" })
bind(mainMod .. " + Delete",         exec(rofi .. "powermenu.sh"), { description = "Power menu" })
bind(mainMod .. " + V",              exec(rofi .. "clipboard.sh"), { description = "Clipboard history" })
bind(mainMod .. " + period",         exec(rofi .. "emoji.sh"), { description = "Emoji picker" })
bind(mainMod .. " + C",              exec("hyprpicker -a"), { description = "Color picker" })
bind(mainMod .. " + SHIFT + Q",      exec("hyprlock"), { description = "Lock screen" })
bind(mainMod .. " + escape",         exec("dunstctl close-all"), { description = "Dismiss notifications" })
bind(mainMod .. " + SHIFT + escape", exec("dunstctl history-pop"), { description = "Show last notification" })
bind(mainMod .. " + slash",          exec("$HOME/.local/bin/keybinds menu"), { description = "Keybind cheat sheet" })
bind(mainMod .. " + W",              exec("$HOME/.local/bin/wallpaper"), { description = "Change wallpaper" })

-- Move focus with mainMod + vim keybinds
bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }), { description = "Focus left" })
bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }), { description = "Focus right" })
bind(mainMod .. " + J", hl.dsp.focus({ direction = "up" }), { description = "Focus up" })
bind(mainMod .. " + K", hl.dsp.focus({ direction = "down" }), { description = "Focus down" })

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }), { description = "Go to workspace " .. i })
    bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { description = "Move window to workspace " .. i })
end

-- Special workspace (scratchpad)
bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"), { description = "Show/hide scratchpad" })
bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Move window to scratchpad" })

-- Scroll through existing workspaces with mainMod + scroll
bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })

-- Go to next/prev workspace
bind(mainMod .. " + N",         hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
bind(mainMod .. " + SHIFT + N", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })

-- Move/resize windows with mainMod + LMB/RMB and dragging
bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Move window (drag)" })
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window (drag)" })

-- Alt tab functionality
bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "Cycle windows" })
bind("ALT + SHIFT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "Cycle windows backwards" })

-- Screenshot binds
bind("SUPER + P",          exec(grimblast .. " copysave area --notify --freeze"), { description = "Screenshot area" })
bind("SUPER + SHIFT + P",  exec(grimblast .. " copysave output --notify"), { description = "Screenshot monitor" })
bind("SUPER + CTRL + P",   exec(grimblast .. " copysave screen --notify"), { description = "Screenshot all monitors" })
bind("SUPER + ALT + P",    exec(grimblast .. " copysave active --notify"), { description = "Screenshot window" })

-- Screen recording binds (press again to stop, quick binds record pc audio)
bind("SUPER + SHIFT + R",  exec(wfrecord .. " area"), { description = "Record area (again to stop)" })
bind("SUPER + CTRL + R",   exec(wfrecord .. " output"), { description = "Record monitor (again to stop)" })
bind("SUPER + ALT + R",    exec(wfrecord .. " menu"), { description = "Recording menu" })

-- Multimedia keys for volume
bind("XF86AudioRaiseVolume", exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, description = "Volume up" })
bind("XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true, description = "Volume down" })
bind("XF86AudioMute",        exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true, description = "Mute" })
bind("XF86AudioMicMute",     exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true, description = "Mute microphone" })

-- Music without media keys (40% keyboard): Super+Alt with the vim keys. `music`
-- controls whichever player started playing last (cliamp, Brave, mpv...)
bind(mainMod .. " + M",             exec("$HOME/.local/bin/cliamp-toggle"), { description = "Show/hide music player" })
bind(mainMod .. " + ALT + SPACE",   exec("$HOME/.local/bin/music toggle"),                               { locked = true, description = "Play/pause" })
bind(mainMod .. " + ALT + L",       exec("$HOME/.local/bin/music next"),                                 { locked = true, description = "Next track" })
bind(mainMod .. " + ALT + H",       exec("$HOME/.local/bin/music prev"),                                 { locked = true, description = "Previous track" })
bind(mainMod .. " + ALT + K",       exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, description = "Volume up" })
bind(mainMod .. " + ALT + J",       exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true, description = "Volume down" })

-- Media keys, for keyboards that have them
bind("XF86AudioNext",  exec("$HOME/.local/bin/music next"),       { locked = true, description = "Next track" })
bind("XF86AudioPause", exec("$HOME/.local/bin/music toggle"), { locked = true, description = "Play/pause" })
bind("XF86AudioPlay",  exec("$HOME/.local/bin/music toggle"), { locked = true, description = "Play/pause" })
bind("XF86AudioPrev",  exec("$HOME/.local/bin/music prev"),   { locked = true, description = "Previous track" })

-- mainMod + R enters the resize submap: H/J/K/L resize the active window,
-- escape goes back to the normal binds
bind(mainMod .. " + R", hl.dsp.submap("resize"), { description = "Resize mode (HJKL, escape to leave)" })
hl.define_submap("resize", function()
    bind("L", hl.dsp.window.resize({ x = 10,  y = 0,   relative = true }), { repeating = true, description = "Resize: wider" })
    bind("H", hl.dsp.window.resize({ x = -10, y = 0,   relative = true }), { repeating = true, description = "Resize: narrower" })
    bind("K", hl.dsp.window.resize({ x = 0,   y = -10, relative = true }), { repeating = true, description = "Resize: shorter" })
    bind("J", hl.dsp.window.resize({ x = 0,   y = 10,  relative = true }), { repeating = true, description = "Resize: taller" })
    bind("escape", hl.dsp.submap("reset"), { description = "Leave resize mode" })
end)
