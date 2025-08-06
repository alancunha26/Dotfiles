-- [[ Settings ]]

-- [[ Global Variables ]]
-- See `:help vim.g`

-- Set <leader> key to space bar
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- Set variable to know if is a WSL session
vim.g.have_wsl_session = os.getenv('WSL_INTEROP') ~= nil or os.getenv('WSL_DISTRO_NAME')

-- Overrides netrw_browsex_viewer to cd to the current directory
vim.g.netrw_browsex_viewer = 'cd %:h && xdg-open'

-- Disable default netrw
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1

-- [[ Set Options ]]
-- See `:help vim.o`
-- vim.opt.winborder = 'rounded'

-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Enable soft wrap
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = false

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Identation config
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2

-- Sets how neovim will display certain whitespace characters in the editor.
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- If performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
vim.o.confirm = true

-- Setup spellcheck languages
vim.opt.spelllang = 'en_us,pt_br'
vim.opt.spell = false

-- Disable swap files
-- vim.opt.swapfile = false
