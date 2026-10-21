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
bind(mainMod .. " + RETURN",         exec("$TERMINAL"))
bind(mainMod .. " + Q",              hl.dsp.window.close())
bind(mainMod .. " + E",              exec("nautilus"))
bind(mainMod .. " + F",              hl.dsp.window.float({ action = "toggle" }))
bind(mainMod .. " + SHIFT + F",      hl.dsp.window.fullscreen())
bind(mainMod .. " + SPACE",          exec(rofi .. "launcher.sh"))
bind(mainMod .. " + SHIFT + SPACE",  exec(rofi .. "finder.sh"))
bind(mainMod .. " + Tab",            exec(rofi .. "window.sh"))
bind(mainMod .. " + Delete",         exec(rofi .. "powermenu.sh"))
bind(mainMod .. " + V",              exec(rofi .. "clipboard.sh"))
bind(mainMod .. " + period",         exec(rofi .. "emoji.sh"))
bind(mainMod .. " + C",              exec("hyprpicker -a"))
bind(mainMod .. " + SHIFT + Q",      exec("hyprlock"))
bind(mainMod .. " + escape",         exec("dunstctl close-all"))
bind(mainMod .. " + SHIFT + escape", exec("dunstctl history-pop"))

-- Move focus with mainMod + vim keybinds
bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
bind(mainMod .. " + J", hl.dsp.focus({ direction = "up" }))
bind(mainMod .. " + K", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e-1" }))

-- Go to next/prev workspace
bind(mainMod .. " + N",         hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + SHIFT + N", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Alt tab functionality
bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)
bind("ALT + SHIFT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- Screenshot binds
bind("SUPER + P",          exec(grimblast .. " copysave area --notify --freeze"))
bind("SUPER + SHIFT + P",  exec(grimblast .. " copysave output --notify"))
bind("SUPER + CTRL + P",   exec(grimblast .. " copysave screen --notify"))
bind("SUPER + ALT + P",    exec(grimblast .. " copysave active --notify"))

-- Screen recording binds (press again to stop, quick binds record pc audio)
bind("SUPER + SHIFT + R",  exec(wfrecord .. " area"))
bind("SUPER + CTRL + R",   exec(wfrecord .. " output"))
bind("SUPER + ALT + R",    exec(wfrecord .. " menu"))

-- Multimedia keys for volume
bind("XF86AudioRaiseVolume", exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
bind("XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
bind("XF86AudioMute",        exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
bind("XF86AudioMicMute",     exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })

-- Requires playerctl
bind("XF86AudioNext",  exec("playerctl next"),       { locked = true })
bind("XF86AudioPause", exec("playerctl play-pause"), { locked = true })
bind("XF86AudioPlay",  exec("playerctl play-pause"), { locked = true })
bind("XF86AudioPrev",  exec("playerctl previous"),   { locked = true })

-- mainMod + R enters the resize submap: H/J/K/L resize the active window,
-- escape goes back to the normal binds
bind(mainMod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    bind("L", hl.dsp.window.resize({ x = 10,  y = 0,   relative = true }), { repeating = true })
    bind("H", hl.dsp.window.resize({ x = -10, y = 0,   relative = true }), { repeating = true })
    bind("K", hl.dsp.window.resize({ x = 0,   y = -10, relative = true }), { repeating = true })
    bind("J", hl.dsp.window.resize({ x = 0,   y = 10,  relative = true }), { repeating = true })
    bind("escape", hl.dsp.submap("reset"))
end)
