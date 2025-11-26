return {
  'catgoose/nvim-colorizer.lua',
  event = 'BufReadPre',
  opts = {
    user_default_options = {
      names = false,
      RRGGBBAA = true,
      AARRGGBB = true,
      css = true,
      tailwind = true,
      tailwind_opts = {
        update_names = true,
      },
    },
  },
}
