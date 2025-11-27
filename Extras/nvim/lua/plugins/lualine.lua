return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'echasnovski/mini.icons' },
  event = 'VeryLazy',
  config = function()
    require('mini.icons').setup()
    require('mini.icons').mock_nvim_web_devicons()

    local zk_config = require('modules.zettels.config')

    local function get_note_title()
      if not zk_config.is_zk_workspace() or vim.bo.filetype ~= 'markdown' then
        return nil
      end

      local lines = vim.api.nvim_buf_get_lines(0, 0, 10, false)
      if #lines == 0 or lines[1] ~= '---' then
        return nil
      end

      for i = 2, #lines do
        if lines[i] == '---' then
          break
        end
        local title = lines[i]:match('^title:%s*["\']?([^"\']+)["\']?%s*$')
        if title then
          return title
        end
      end

      return nil
    end

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
            fmt = function(filename)
              local title = get_note_title()
              if title then
                local name = vim.fn.expand('%:t')
                return title .. ' (' .. name .. ')'
              end
              return filename
            end,
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
