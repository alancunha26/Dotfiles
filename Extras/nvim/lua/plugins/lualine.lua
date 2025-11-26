return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'echasnovski/mini.icons' },
  event = 'VeryLazy',
  config = function()
    require('mini.icons').setup()
    require('mini.icons').mock_nvim_web_devicons()

    require('lualine').setup({
      options = {
        globalstatus = true,
        theme = 'tokyonight',
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = {
          statusline = { 'snacks_dashboard' },
        },
      },
      sections = {
        lualine_a = {
          {
            'mode',
            fmt = function(str)
              return str:sub(1, 1)
            end,
          },
        },
        lualine_b = {
          { 'branch', icon = '' },
          {
            'diff',
            symbols = { added = ' ', modified = ' ', removed = ' ' },
          },
        },
        lualine_c = {
          {
            'filetype',
            icon_only = true,
            padding = { left = 1, right = 0 },
          },
          {
            'filename',
            path = 1,
            symbols = { modified = ' ●', readonly = ' ', unnamed = '[No Name]' },
          },
        },
        lualine_x = {
          {
            'macro',
            fmt = function()
              local reg = vim.fn.reg_recording()
              if reg ~= '' then
                return ' @' .. reg
              end
              return nil
            end,
            color = { fg = '#c53b53' },
          },
          {
            'searchcount',
            maxcount = 999,
          },
          {
            'selectioncount',
            fmt = function(str)
              if str ~= '' then
                return '󰒅 ' .. str
              end
              return nil
            end,
          },
          {
            'diagnostics',
            symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
          },
        },
        lualine_y = {
          { 'filetype', icons_enabled = false },
        },
        lualine_z = {
          { 'location', icon = '' },
        },
      },
      extensions = { 'lazy', 'trouble', 'quickfix' },
    })
  end,
}
