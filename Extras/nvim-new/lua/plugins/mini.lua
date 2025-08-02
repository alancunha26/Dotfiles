return {
  'echasnovski/mini.nvim',
  version = '*',
  config = function()
    -- [[ Text editing ]]
    require('mini.move').setup()
    require('mini.pairs').setup()
    require('mini.surround').setup()
    require('mini.operators').setup()
    require('mini.splitjoin').setup()
    require('mini.ai').setup({ n_lines = 500 })

    -- [[ Appearance ]]
    require('mini.icons').setup()
    require('mini.bracketed').setup()
    require('mini.trailspace').setup()

    local hipatterns = require('mini.hipatterns')
    -- TODO: finish tailwind implementation to replace nvim-colorizer
    -- local hipatterns_extras = require('modules.mini.hipatterns')
    hipatterns.setup({
      highlighters = {
        fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
        hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
        todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
        note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },

        -- hex_color = hipatterns.gen_highlighter.hex_color(),
        -- hex_color_short = hipatterns_extras.hex_color_short(),
        -- hsl_color = hipatterns_extras.hsl_color(),
        -- rgb_color = hipatterns_extras.rgb_color(),
        -- rgba_color = hipatterns_extras.rgba_color(),
      },
    })

    -- [[ Workflow ]]
    require('mini.jump').setup()

    require('mini.git').setup()
    require('mini.diff').setup({
      view = {
        style = 'sign',
        -- signs = { add = '+', change = '~', delete = '_' },
        signs = { add = '┃', change = '┃', delete = '_' },
        priority = 199,
      },
    })

    require('mini.files').setup({
      options = {
        permanent_delete = false,
        use_as_default_explorer = true,
      },
    })

    require('modules.mini/files-git')

    local statusline = require('mini.statusline')
    statusline.setup({ use_icons = vim.g.have_nerd_font })

    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l:%-2v'
    end
  end,

  keys = {
    { '<leader>ee', '<cmd>lua MiniFiles.open()<cr>', desc = 'File explorer' },
    { '<leader>eE', '<cmd>lua MiniFiles.open(vim.uv.cwd(), true)<cr>', desc = 'File explorer (cwd)' },
    { '<leader>gt', '<cmd>lua MiniTrailspace.trim()<cr>', desc = 'Trim trailing whitespace' },
  },
}
