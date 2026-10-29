-- See https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
    general = {
        gaps_in          = 6,
        gaps_out         = 12,
        border_size      = 2,
        resize_on_border = true,
        layout           = "dwindle",
        col = {
            active_border   = "rgba(82aaffff)",
            inactive_border = "rgba(545c7eff)",
        },
    },

    decoration = {
        rounding = 4,
        blur = {
            enabled           = true,
            size              = 8,
            passes            = 2,
            new_optimizations = true,
            ignore_opacity    = true,
            xray              = false,
        },
        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },
    },

    animations = {
        enabled = true,
    },

    input = {
        kb_layout          = "us",
        kb_variant         = "intl",
        kb_model           = "",
        kb_options         = "",
        kb_rules           = "",
        follow_mouse       = 1,
        mouse_refocus      = false,
        accel_profile      = "flat",
        numlock_by_default = true,
        sensitivity        = 0, -- -1.0 - 1.0, 0 means no modification.
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        -- An app that asks for focus gets it (switching workspace): clicking a notification
        -- hands the app an activation token, and this is what lets it jump to the window
        focus_on_activate       = true,
        force_default_wallpaper = -1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = false, -- If true disables the random hyprland logo / anime girl background. :(
    },
})

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("quart", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })

hl.animation({ leaf = "windows",     enabled = true, speed = 6, bezier = "quart", style = "slide" })
hl.animation({ leaf = "border",      enabled = true, speed = 6, bezier = "quart" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 6, bezier = "quart" })
hl.animation({ leaf = "fade",        enabled = true, speed = 6, bezier = "quart" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 6, bezier = "quart" })

-- Closing layers start slow: swaync's panel layer spans the whole screen, so its "slide right"
-- travels 1920px and the panel (the right 440px) would leave in the first frames on "quart"
hl.curve("easein", { type = "bezier", points = { { 0.6, 0 }, { 0.9, 0.4 } } })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 4, bezier = "easein" })
