return {
  'TaDaa/vimade',
  event = 'VeryLazy',
  opts = {
    recipe = { 'default', { animate = true } },
    ncmode = 'windows',
    fadelevel = 0.6,
    blocklist = {
      win_separator = {
        highlights = { 'WinSeparator', 'VertSplit' },
      },
    },
  },
}
