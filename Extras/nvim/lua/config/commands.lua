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
  if not vim.uv.fs_stat(pipe) then
    vim.fn.serverstart(pipe)
  end

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
