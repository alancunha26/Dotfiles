local zk_short_id = require('utils.zk-short-id')
local config = require('utils.zk-vault-config')

return {
  'HakonHarnes/img-clip.nvim',
  event = 'VeryLazy',
  opts = {
    -- add options here
    -- or leave it empty to use the default settings
    default = {

      -- file and directory options
      -- expands dir_path to an absolute path
      -- When you paste a new image, and you hover over its path, instead of:
      -- test-images-img/2024-06-03-at-10-58-55.webp
      -- You would see the entire path:
      -- /Users/linkarzu/github/obsidian_main/999-test/test-images-img/2024-06-03-at-10-58-55.webp
      --
      -- IN MY CASE I DON'T WANT TO USE ABSOLUTE PATHS
      -- if I switch to a nother computer and I have a different username,
      -- therefore a different home directory, that's a problem because the
      -- absolute paths will be pointing to a different directory
      use_absolute_path = false, ---@type boolean

      -- make dir_path relative to current file rather than the cwd
      -- To see your current working directory run `:pwd`
      -- So if this is set to false, the image will be created in that cwd
      -- In my case, I want images to be where the file is, so I set it to true
      relative_to_current_file = false, ---@type boolean
      relative_template_path = false, ---@type boolean

      -- Resolves to the default 'assets' folder if not in a zk notebookk
      dir_path = function()
        if not config then
          return 'assets'
        else
          return vim.fn.expand(config.assets_dir)
        end
      end,

      -- If you want to get prompted for the filename when pasting an image
      -- This is the actual name that the physical file will have
      -- If you set it to true, enter the name without spaces or extension `test-image-1`
      -- Remember we specified the extension above
      --
      -- I don't want to give my images a name, but instead autofill it using
      -- the date and time as shown on `file_name` below
      prompt_for_file_name = false, ---@type boolean

      ---@type string | fun(): string
      file_name = function()
        local id = zk_short_id()

        if id ~= nil then
          return id
        else
          return '%Y-%m-%d-%H-%M-%S'
        end
      end,

      -- -- Set the extension that the image file will have
      -- -- I'm also specifying the image options with the `process_cmd`
      -- -- Notice that I HAVE to convert the images to the desired format
      -- -- If you don't specify the output format, you won't see the size decrease

      extension = 'png', ---@type string
      -- process_cmd = 'convert - -quality 100 png:-', ---@type string

      -- extension = "webp", ---@type string
      -- process_cmd = "convert - -quality 75 webp:-", ---@type string

      -- extension = "png", ---@type string
      -- process_cmd = "convert - -quality 75 png:-", ---@type string

      -- extension = "jpg", ---@type string
      -- process_cmd = "convert - -quality 75 jpg:-", ---@type string

      -- -- Here are other conversion options to play around
      -- -- Notice that with this other option you resize all the images
      -- process_cmd = "convert - -quality 75 -resize 50% png:-", ---@type string

      -- -- Other parameters I found in stackoverflow
      -- -- https://stackoverflow.com/a/27269260
      -- --
      -- -- -depth value
      -- -- Color depth is the number of bits per channel for each pixel. For
      -- -- example, for a depth of 16 using RGB, each channel of Red, Green, and
      -- -- Blue can range from 0 to 2^16-1 (65535). Use this option to specify
      -- -- the depth of raw images formats whose depth is unknown such as GRAY,
      -- -- RGB, or CMYK, or to change the depth of any image after it has been read.
      -- --
      -- -- compression-filter (filter-type)
      -- -- compression level, which is 0 (worst but fastest compression) to 9 (best but slowest)
      -- process_cmd = "convert - -depth 24 -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 png:-",
      --
      -- -- These are for jpegs
      -- process_cmd = "convert - -sampling-factor 4:2:0 -strip -interlace JPEG -colorspace RGB -quality 75 jpg:-",
      -- process_cmd = "convert - -strip -interlace Plane -gaussian-blur 0.05 -quality 75 jpg:-",
      --

      -- image options
      copy_images = true, ---@type boolean | fun(): boolean
      download_images = true, ---@type boolean | fun(): boolean

      -- drag and drop options
      drag_and_drop = {
        enabled = true, ---@type boolean | fun(): boolean
        insert_mode = true, ---@type boolean | fun(): boolean
      },
    },

    -- filetype specific options
    filetypes = {
      markdown = {
        -- encode spaces and special characters in file path
        url_encode_path = true, ---@type boolean
        relative_template_path = true, ---@type boolean
        template = '![$CURSOR]($FILE_PATH)', ---@type string
      },
    },
  },
  keys = {
    -- suggested keymap
    { '<leader>pi', '<cmd>PasteImage<cr>', desc = '[P]aste [I]mage from system clipboard' },
  },
}
