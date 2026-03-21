-- Neovim ↔ Grimoire sync module
-- Sends the current note + scroll position to the Grimoire dev server via HTTP POST.
-- The Vite plugin relays it to the browser via WebSocket.
-- Fails silently if the dev server is not running.

local M = {}

local base_url = "http://localhost:24680"
local last_note_id = nil
local last_top_line = nil
local registered = false

-- Check if a buffer is a zettel file
local function is_zettel(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr or 0)
  return path:match("/zettels/[%w]+%.md$") ~= nil
end

-- Extract the note ID from a zettel file path
local function get_note_id(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr or 0)
  return path:match("/zettels/([%w]+)%.md$")
end

-- Slugify a heading text (matches Astro's rehype-slug algorithm)
function M.slugify(text)
  text = text:gsub("%[([^%]]*)%]%([^%)]*%)", "%1")
  text = text:gsub("[*_`]", "")
  text = text:lower()
  text = text:gsub("[^%w%s%-]", "")
  text = text:gsub("%s+", "-")
  text = text:gsub("^%-+", ""):gsub("%-+$", "")
  return text
end

-- Find the nearest heading above the cursor
function M.get_nearest_heading()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  for line = cursor_line, 1, -1 do
    local text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1]
    if text then
      local heading = text:match("^#+%s+(.+)$")
      if heading then
        return M.slugify(heading)
      end
    end
  end
  return nil
end

-- Find the line offset to convert file line → content body line.
-- Returns the number of lines to subtract (frontmatter + blank line after it).
local frontmatter_cache = {}
local function get_frontmatter_offset(bufnr)
  bufnr = bufnr or 0
  local name = vim.api.nvim_buf_get_name(bufnr)
  if frontmatter_cache[name] then return frontmatter_cache[name] end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)
  if #lines == 0 or lines[1] ~= "---" then
    frontmatter_cache[name] = 0
    return 0
  end

  for i = 2, #lines do
    if lines[i] == "---" then
      -- Skip blank lines immediately after closing ---
      local offset = i
      while offset + 1 <= #lines and lines[offset + 1]:match("^%s*$") do
        offset = offset + 1
      end
      frontmatter_cache[name] = offset
      return offset
    end
  end

  frontmatter_cache[name] = 0
  return 0
end

-- Get the cursor line number relative to content body (after frontmatter)
local function get_content_line()
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local fm_end = get_frontmatter_offset()
  return math.max(1, cursor - fm_end)
end

-- Send a JSON payload to the Vite server (async, fire-and-forget)
function M.send(endpoint, data)
  local json = vim.fn.json_encode(data)
  vim.fn.jobstart({
    "curl",
    "-s",
    "-X",
    "POST",
    "-H",
    "Content-Type: application/json",
    "-d",
    json,
    base_url .. "/" .. endpoint,
  }, {
    on_exit = function() end,
  })
end

-- Register this Neovim instance with the Vite server
function M.register()
  local socket = vim.v.servername
  if not socket or socket == "" then return end

  M.send("register", { socket = socket })
  registered = true
end

-- Send the current note + scroll position to the browser
function M.navigate()
  if not is_zettel() then return end

  local note_id = get_note_id()
  if not note_id then return end

  local content_line = get_content_line()

  -- For same note, only send if cursor moved
  if note_id == last_note_id and content_line == last_top_line then return end

  local changed_note = note_id ~= last_note_id
  last_note_id = note_id
  last_top_line = content_line

  local data = {
    type = "navigate",
    noteId = note_id,
    topLine = content_line,
  }


  if not registered then
    M.register()
  end

  M.send("send", data)
end

-- Flag to suppress our autocmds during browser-initiated actions
M._from_browser = false

-- Don't disrupt insert/visual/command mode — sync can wait
local function is_editing()
  local mode = vim.api.nvim_get_mode().mode
  return mode ~= "n" and mode ~= "no" and mode ~= "nt"
end

-- Called by the Vite server to open a file without polluting the jump list
function M.open_from_browser(filepath)
  if is_editing() then return "" end
  local current = vim.api.nvim_buf_get_name(0)
  if current == filepath then return "" end

  M._from_browser = true
  vim.cmd("keepjumps edit " .. vim.fn.fnameescape(filepath))
  vim.cmd("keepjumps normal! 1Gzt")
  vim.defer_fn(function() M._from_browser = false end, 500)
  return ""
end

-- Called by the Vite server to scroll to a line without polluting the jump list
-- `line` is content-relative (after frontmatter)
function M.scroll_from_browser(filepath, line)
  if is_editing() then return "" end
  local current = vim.api.nvim_buf_get_name(0)
  if current ~= filepath then
    M._from_browser = true
    vim.cmd("keepjumps edit " .. vim.fn.fnameescape(filepath))
  end

  -- Convert content-relative line to absolute line
  local fm_end = get_frontmatter_offset()
  local total = vim.api.nvim_buf_line_count(0)
  local target = math.min(math.max(1, line + fm_end), total)

  M._from_browser = true
  vim.cmd("keepjumps normal! " .. target .. "Gzt")
  vim.defer_fn(function() M._from_browser = false end, 500)
  return ""
end

-- Force sync current note + heading (ignores debounce)
function M.force_navigate()
  last_note_id = nil
  last_top_line = nil
  M.navigate()
end

-- Grimoire dev server management
local grimoire_job = nil
local grimoire_dir = vim.fn.getcwd() .. "/grimoire"

function M.toggle_server()
  if grimoire_job then
    vim.fn.jobstop(grimoire_job)
    grimoire_job = nil
    registered = false
    vim.notify("[grimoire] Server stopped")
  else
    grimoire_job = vim.fn.jobstart({ "pnpm", "dev" }, {
      cwd = grimoire_dir,
      on_exit = function()
        grimoire_job = nil
      end,
    })

    vim.defer_fn(function()
      vim.ui.open("http://localhost:4321")
    end, 3000)

    vim.notify("[grimoire] Starting dev server...")
  end
end

function M.clear_cache()
  if grimoire_job then
    vim.fn.jobstop(grimoire_job)
    grimoire_job = nil
    registered = false
  end

  vim.fn.jobstart({ "rm", "-rf", "dist", ".astro" }, {
    cwd = grimoire_dir,
    on_exit = function()
      vim.schedule(function()
        vim.notify("[grimoire] Cache cleared, server stopped")
      end)
    end,
  })
end

-- Set up autocmds and register with the Vite server
function M.setup(opts)
  opts = opts or {}
  if opts.url then
    base_url = opts.url
  end

  local group = vim.api.nvim_create_augroup("GrimoireSync", { clear = true })

  -- Navigate on buffer enter (deferred to let pickers/plugins position the cursor first)
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    pattern = "*/zettels/*.md",
    callback = function()
      if M._from_browser then return end
      last_top_line = nil
      vim.defer_fn(function()
        M.navigate()
      end, 50)
    end,
  })

  -- Update scroll position on cursor hold (normal mode)
  vim.api.nvim_create_autocmd("CursorHold", {
    group = group,
    pattern = "*/zettels/*.md",
    callback = function()
      if M._from_browser then return end
      M.navigate()
    end,
  })

  -- Throttled CursorMoved for visual mode and continuous movement
  local move_timer = nil
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    pattern = "*/zettels/*.md",
    callback = function()
      if M._from_browser then return end
      if move_timer then
        move_timer:stop()
      end
      move_timer = vim.defer_fn(function()
        M.navigate()
        move_timer = nil
      end, 300)
    end,
  })

  -- Register on startup (delayed to let Vite server start)
  vim.defer_fn(function()
    M.register()
  end, 2000)
end

return M
