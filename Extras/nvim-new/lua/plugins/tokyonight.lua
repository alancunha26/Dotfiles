return {
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    opts = {
      transparent = true,
      styles = {
        sidebars = 'transparent',
        floats = 'transparent',
      },
      on_colors = function(colors)
        colors.border = '#565f89'
        colors.fg_gutter = '#565f89'
      end,
      on_highlights = function(hl, c)
        hl['@markup.italic.markdown_inline'] = { fg = c.yellow }
        hl['@markup.strong.markdown_inline'] = { bold = true, fg = c.red }
      end,
    },
    init = function()
      vim.cmd.colorscheme('tokyonight-moon')
    end,
  },
}
