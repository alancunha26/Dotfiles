return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'echasnovski/mini.icons' },
  event = 'VeryLazy',
  config = function()
    require('mini.icons').setup()
    require('mini.icons').mock_nvim_web_devicons()

    require('lualine').setup({
      options = {
        theme = require('lualine.themes._tokyonight').get('moon'),
        component_separators = '',
        section_separators = { left = '', right = '' },
        disabled_filetypes = { 'alpha', 'Outline' },
      },
      sections = {
        lualine_a = {
          {
            'macro',
            fmt = function()
              local reg = vim.fn.reg_recording()
              if reg ~= '' then
                return 'Recording @' .. reg
              end
              return nil
            end,
            separator = { left = ' ', right = '' },
            color = { bg = '#c53b53' },
            draw_empty = false,
          },
          {
            'mode',
            separator = { left = ' ', right = '' },
            icon = '',
          },
        },
        lualine_b = {
          {
            'filetype',
            icon_only = true,
            padding = { left = 1, right = 0 },
          },
          {
            'filename',
          },
        },
        lualine_c = {
          {
            'branch',
            icon = '',
          },
          {
            'diff',
            symbols = { added = ' ', modified = ' ', removed = ' ' },
            colored = false,
          },
        },
        lualine_x = {
          {
            'diagnostics',
            symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
            update_in_insert = true,
          },
        },
        lualine_y = {
          'lsp_status',
        },
        lualine_z = {
          { 'location', separator = { left = '', right = ' ' }, icon = '' },
        },
      },
      inactive_sections = {
        lualine_a = { 'filename' },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = { 'location' },
      },
      extensions = { 'toggleterm', 'trouble' },
    })
  end,
}
