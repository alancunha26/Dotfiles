-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

-- Any monitor: highest refresh rate, 8-bit color
hl.monitor({
    output   = "",
    mode     = "highrr",
    position = "auto",
    scale    = "auto",
    bitdepth = 8,
})

-- Samsung Odyssey G40B: 240Hz, FreeSync only for fullscreen apps (vrr = 2)
hl.monitor({
    output   = "desc:Samsung Electric Company Odyssey G40B HX5L100762",
    mode     = "1920x1080@239.76",
    position = "auto",
    scale    = 1,
    bitdepth = 8,
    vrr      = 2,
})

-- AOC 2460G5: highrr would pick 1024x768@75.03 over 1920x1080@74.99
hl.monitor({
    output   = "desc:AOC 2460G5 0x0000023E",
    mode     = "1920x1080@74.99",
    position = "auto",
    scale    = 1,
    bitdepth = 8,
})
