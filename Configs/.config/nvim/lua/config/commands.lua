-- [[ Text expansion (insert-mode abbreviations) ]]
vim.cmd("inoreabbrev ,m —")
vim.cmd("inoreabbrev ,n –")
vim.cmd("iabbrev <expr> ,d strftime('%Y-%m-%d')")
vim.cmd("iabbrev <expr> ,t strftime('%Y-%m-%dT%TZ')")
-- [[ General Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesActionRename',
  callback = function(event)
    Snacks.rename.on_rename_file(event.data.from, event.data.to)
  end,
})

-- Disable snack animation for blink-cmp
-- See: https://github.com/Saghen/blink.cmp/issues/1338#issuecomment-2708402335
vim.api.nvim_create_autocmd('User', {
  pattern = 'BlinkCmpMenuOpen',
  callback = function()
    vim.g.snacks_animate = false
  end,
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'BlinkCmpMenuClose',
  callback = function()
    vim.g.snacks_animate = true
  end,
})

-- [[ Godot ]]
-- When started inside a Godot project, listen on a pipe so the Godot
-- editor (configured as external editor) can open files in this instance.
local godot_root = vim.fs.root(vim.fn.getcwd(), 'project.godot')
if godot_root then
  local pipe = godot_root .. '/server.pipe'

  -- A socket left behind by a crashed or killed nvim makes this look taken,
  -- and Godot's "open in external editor" then silently does nothing. Probe
  -- it: if nobody answers, the file is stale and can be replaced.
  local function pipe_answers()
    local ok, chan = pcall(vim.fn.sockconnect, 'pipe', pipe, { rpc = true })
    if ok and chan > 0 then
      pcall(vim.fn.chanclose, chan)
      return true
    end
    return false
  end

  if vim.uv.fs_stat(pipe) and not pipe_answers() then
    vim.uv.fs_unlink(pipe)
  end
  if not vim.uv.fs_stat(pipe) then
    vim.fn.serverstart(pipe)
    -- Leave no stale socket behind on a clean exit
    vim.api.nvim_create_autocmd('VimLeavePre', {
      desc = 'Remove the Godot editor server pipe',
      group = vim.api.nvim_create_augroup('godot-server-pipe', { clear = true }),
      callback = function()
        pcall(vim.fn.serverstop, pipe)
        vim.uv.fs_unlink(pipe)
      end,
    })
  end

  -- Gutter marks like the editor's indicators: signal-connected methods
  -- and engine/parent-script overrides
  require('modules.godot.signals').setup(godot_root)
  require('modules.godot.overrides').setup(godot_root)

  -- Godot's LSP resolves $Node completions from the scene file on disk and
  -- caches it per script without ever invalidating it, so completions go
  -- stale when nodes are added/renamed. When nvim regains focus (coming
  -- back from Godot), restart the client if any saved scene changed.
  local scene_mtimes
  local function scenes_changed()
    local seen, changed = {}, false
    for _, scene in ipairs(vim.fn.glob(godot_root .. '/**/*.tscn', true, true)) do
      local stat = vim.uv.fs_stat(scene)
      seen[scene] = stat and (stat.mtime.sec .. ':' .. stat.size) or ''
      if scene_mtimes and scene_mtimes[scene] ~= seen[scene] then
        changed = true
      end
    end
    if scene_mtimes then
      for scene in pairs(scene_mtimes) do
        if not seen[scene] then
          changed = true
        end
      end
    end
    scene_mtimes = seen
    return changed
  end
  scenes_changed() -- prime the baseline at startup

  vim.api.nvim_create_autocmd('FocusGained', {
    desc = 'Restart GDScript LSP when a Godot scene changed on disk',
    group = vim.api.nvim_create_augroup('godot-scene-watch', { clear = true }),
    callback = function()
      -- godotdev.nvim owns the LSP client; reconnecting clears Godot's
      -- stale per-script scene cache
      if not scenes_changed() or #vim.lsp.get_clients({ name = 'gdscript' }) == 0 then
        return
      end
      -- GodotReconnectLSP already notifies, no extra message needed
      vim.cmd('GodotReconnectLSP')
    end,
  })
end

-- [[ Speed reading ]]
-- RSVP reader for notes, see lua/modules/speedread.lua. It reads markdown
-- (plain text is markdown without syntax), so it's only set up for those.
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Set up the speed reader for prose buffers',
  group = vim.api.nvim_create_augroup('speedread-setup', { clear = true }),
  pattern = { 'markdown', 'text' },
  callback = function(event)
    vim.api.nvim_buf_create_user_command(event.buf, 'SpeedRead', function()
      require('modules.speedread').start()
    end, { desc = 'Speed read the buffer from the cursor' })
    vim.keymap.set('n', '<leader>zR', '<cmd>SpeedRead<CR>', { buffer = event.buf, desc = 'Speed read from cursor' })
  end,
})
