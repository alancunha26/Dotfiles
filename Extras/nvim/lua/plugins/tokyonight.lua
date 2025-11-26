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
        colors.bg_statusline = colors.none
      end,
      on_highlights = function(hl, c)
        hl['@markup.italic.markdown_inline'] = { fg = c.yellow }
        hl['@markup.strong.markdown_inline'] = { bold = true, fg = c.red }
        hl['NoiceCmdlinePopupBorderCmdline'] = { fg = '#589ED7' }
        hl['SnacksPickerDir'] = { fg = '#565f89' }

        -- Remove background from markdown headings (added in recent tokyonight update)
        hl['@markup.heading.1.markdown'] = { fg = c.blue, bold = true }
        hl['@markup.heading.2.markdown'] = { fg = c.yellow, bold = true }
        hl['@markup.heading.3.markdown'] = { fg = c.green, bold = true }
        hl['@markup.heading.4.markdown'] = { fg = c.teal, bold = true }
        hl['@markup.heading.5.markdown'] = { fg = c.magenta, bold = true }
        hl['@markup.heading.6.markdown'] = { fg = c.purple, bold = true }

        -- Improves match highlighting
        hl['SnacksPickerMatch'] = {
          bg = '#3d3d00',
          fg = '#ffff00',
          bold = true,
          underline = true,
          sp = '#ffff00',
        }
        hl['Search'] = {
          bg = '#3d3d00',
          fg = '#ffff00',
          bold = true,
          underline = true,
          sp = '#ffff00',
        }
        hl['CurSearch'] = {
          bg = '#3d2a1a',
          fg = c.orange,
          bold = true,
          underline = true,
          sp = c.orange,
        }
        hl['IncSearch'] = {
          bg = '#3d2a1a',
          fg = c.orange,
          bold = true,
          underline = true,
          sp = c.orange,
        }
      end,
    },
    init = function()
      vim.cmd.colorscheme('tokyonight-moon')
    end,
  },
}
