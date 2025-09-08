local extras = require('modules.zettels.extras')

return {
  'HakonHarnes/img-clip.nvim',
  event = 'VeryLazy',
  opts = {
    -- add options here
    -- or leave it empty to use the default settings
    default = {

      use_absolute_path = false, ---@type boolean

      relative_to_current_file = true, ---@type boolean
      relative_template_path = false, ---@type boolean

      dir_path = '', ---@type string | fun(): string
      prompt_for_file_name = false, ---@type boolean

      ---@type string | fun(): string
      file_name = function()
        local id = extras.suid()

        if id ~= nil then
          return id
        else
          return '%Y-%m-%d-%H-%M-%S'
        end
      end,

      -- image options
      copy_images = true, ---@type boolean | fun(): boolean
      download_images = true, ---@type boolean | fun(): boolean

      extension = 'png', ---@type string
      process_cmd = 'convert - -quality 100 png:-', ---@type string

      -- drag and drop options
      drag_and_drop = {
        enabled = true, ---@type boolean | fun(): boolean
        insert_mode = true, ---@type boolean | fun(): boolean
      },
    },

    filetypes = {
      markdown = {
        url_encode_path = true, ---@type boolean
        relative_template_path = true, ---@type boolean
        template = '![$CURSOR]($FILE_PATH)', ---@type string
      },
    },
  },
  keys = {
    -- suggested keymap
    { '<leader>zp', '<cmd>PasteImage<cr>', desc = 'Paste image' },
  },
}
