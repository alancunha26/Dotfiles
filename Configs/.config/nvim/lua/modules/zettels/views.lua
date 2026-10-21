local config = require('modules.zettels.config')
local notes_path = vim.fn.expand(config.notes_path)

local M = {}

-- Marker patterns
-- Single-line: <!-- zk-view: +tag --sort=title -->
-- Multiline open: <!-- zk-view:
-- Multiline close (of the opening comment): -->
-- Content close: <!-- /zk-view -->
local MARKER_SINGLE = '<!%-%- zk%-view: (.+) %-%->'
local MARKER_MULTI_START = '<!%-%- zk%-view:(.*)$'
local MARKER_COMMENT_END = '%-%->%s*$'
local MARKER_CLOSE = '<!%-%- /zk%-view %-%->'

--- Parse a zk-view query string into zk list arguments.
--- Supports:
---   +tag              include tag (AND)
---   -tag              exclude tag
---   --tagless         notes with no tags
---   --sort=TERM       sort order (created, modified, path, title, random, word-count)
---   --group=letter    group results by first letter of title
---   --group=year      group results by year read from the date frontmatter
---   --level=N         heading level for groups (default: 3, producing ###)
---   --links-to=PATH  notes that link to the given file (use "self" for current file)
---   --linked-by=PATH notes linked by the given file (use "self" for current file)
---   --heading=TEXT    heading prefix for groups (must appear last)
---
--- Both single-line and multiline markers are supported:
---   <!-- zk-view: +space/alenyr +object/character -->
---
---   <!-- zk-view:
---     +space/alenyr
---     +object/character
---     --heading=Characters
---   -->
local function parse_query(query)
  local include_tags = {}
  local exclude_tags = {}
  local tagless = false
  local sort = nil
  local group = nil
  local heading = nil
  local level = 3
  local links_to = nil
  local linked_by = nil

  -- Extract --heading= first since its value may contain spaces.
  -- Must appear last in the query string.
  local heading_start = query:find('%-%-heading=')
  if heading_start then
    heading = vim.fn.trim(query:sub(heading_start + #'--heading='))
    query = vim.fn.trim(query:sub(1, heading_start - 1))
  end

  for token in query:gmatch('%S+') do
    if token:match('^%+(.+)') then
      table.insert(include_tags, token:match('^%+(.+)'))
    elseif token == '--tagless' then
      tagless = true
    elseif token:match('^%-%-sort=(.+)') then
      sort = token:match('^%-%-sort=(.+)')
    elseif token:match('^%-%-group=(.+)') then
      group = token:match('^%-%-group=(.+)')
    elseif token:match('^%-%-level=(%d+)') then
      level = tonumber(token:match('^%-%-level=(%d+)'))
    elseif token:match('^%-%-links%-to=(.+)') then
      links_to = token:match('^%-%-links%-to=(.+)')
    elseif token:match('^%-%-linked%-by=(.+)') then
      linked_by = token:match('^%-%-linked%-by=(.+)')
    elseif token:match('^%-(.+)') then
      table.insert(exclude_tags, token:match('^%-(.+)'))
    end
  end

  return {
    include_tags = include_tags,
    exclude_tags = exclude_tags,
    tagless = tagless,
    sort = sort,
    group = group,
    heading = heading,
    level = level,
    links_to = links_to,
    linked_by = linked_by,
  }
end

--- Build the zk list command from a parsed query.
local function build_command(parsed, current_file)
  local cmd = { 'zk', 'list', '--quiet', '--no-pager', '--format=- [{{title}}]({{filename}})' }

  if parsed.tagless then
    table.insert(cmd, '--tagless')
  end

  for _, tag in ipairs(parsed.include_tags) do
    table.insert(cmd, '--tag')
    table.insert(cmd, tag)
  end

  if parsed.sort then
    table.insert(cmd, '--sort')
    table.insert(cmd, parsed.sort)
  else
    table.insert(cmd, '--sort')
    table.insert(cmd, 'title')
  end

  -- Resolve "self" to the current file path for link queries
  if parsed.links_to then
    local path = parsed.links_to == 'self' and current_file or parsed.links_to
    if path then
      table.insert(cmd, '--link-to')
      table.insert(cmd, path)
    end
  end

  if parsed.linked_by then
    local path = parsed.linked_by == 'self' and current_file or parsed.linked_by
    if path then
      table.insert(cmd, '--linked-by')
      table.insert(cmd, path)
    end
  end

  -- Exclude the current file to avoid self-referencing
  if current_file then
    table.insert(cmd, '--exclude')
    table.insert(cmd, current_file)
  end

  return cmd
end

--- Split a string into alternating text and number chunks for natural sorting.
--- e.g. "NEX-10" -> {"nex-", 10}
local function natural_key(s)
  local parts = {}
  local i = 1
  while i <= #s do
    local num_start, num_end = s:find('%d+', i)
    if num_start == i then
      table.insert(parts, tonumber(s:sub(num_start, num_end)))
      i = num_end + 1
    elseif num_start then
      table.insert(parts, s:sub(i, num_start - 1):lower())
      i = num_start
    else
      table.insert(parts, s:sub(i):lower())
      break
    end
  end
  return parts
end

--- Natural (human-friendly) string comparison: "NEX-2" < "NEX-10".
local function natural_compare(a, b)
  local ka, kb = natural_key(a), natural_key(b)
  for i = 1, math.max(#ka, #kb) do
    local pa, pb = ka[i], kb[i]
    if pa == nil then return true end
    if pb == nil then return false end
    if type(pa) ~= type(pb) then
      -- Numeric chunks sort before text chunks at the same position
      return type(pa) == 'number'
    end
    if pa ~= pb then
      return pa < pb
    end
  end
  return false
end

--- Run a zk list command and return filtered results.
local function run_query(parsed, current_file)
  local cmd = build_command(parsed, current_file)

  local result = vim.system(cmd, { cwd = vim.fn.getcwd(), text = true }):wait()

  if result.code ~= 0 then
    return {}
  end

  local lines = {}
  for line in result.stdout:gmatch('[^\n]+') do
    table.insert(lines, line)
  end

  -- Post-filter: exclude tags (zk doesn't support tag negation natively)
  if #parsed.exclude_tags > 0 then
    local filtered = {}
    for _, line in ipairs(lines) do
      -- Extract the file path from the markdown link: - [Title](path.md)
      local path = line:match('%[.-%]%((.-)%)')
      if path then
        local abs_path = notes_path .. '/' .. path
        local file_content = table.concat(vim.fn.readfile(abs_path, '', 20), '\n')

        local excluded = false
        for _, tag in ipairs(parsed.exclude_tags) do
          if file_content:find(tag, 1, true) then
            excluded = true
            break
          end
        end

        if not excluded then
          table.insert(filtered, line)
        end
      end
    end
    lines = filtered
  end

  -- zk's --sort=title is lexicographic, so "NEX-10" beats "NEX-2". Re-sort
  -- naturally when sorting by title (the default).
  if not parsed.sort or parsed.sort == 'title' then
    table.sort(lines, function(a, b)
      local ta = a:match('^%- %[(.-)%]') or a
      local tb = b:match('^%- %[(.-)%]') or b
      return natural_compare(ta, tb)
    end)
  end

  return lines
end

--- Group result lines by first letter of title into formatted sections.
local function group_by_letter(lines, heading_prefix, level)
  local groups = {}
  local order = {}

  for _, line in ipairs(lines) do
    local title = line:match('^%- %[(.-)%]')
    if title then
      local letter = title:sub(1, 1):upper()
      if not groups[letter] then
        groups[letter] = {}
        table.insert(order, letter)
      end
      table.insert(groups[letter], line)
    end
  end

  table.sort(order)

  local prefix = string.rep('#', level) .. ' '
  local output = {}
  for i, letter in ipairs(order) do
    if i > 1 then
      table.insert(output, '')
    end

    if heading_prefix then
      table.insert(output, prefix .. heading_prefix .. ' (' .. letter .. ')')
    else
      table.insert(output, prefix .. letter)
    end

    table.insert(output, '')
    for _, line in ipairs(groups[letter]) do
      table.insert(output, line)
    end
  end

  return output
end

--- Read the `date` field from a note's YAML frontmatter.
--- Returns the date string (e.g. "2026-05-07") or nil if not found.
local function read_frontmatter_date(rel_path)
  local abs_path = notes_path .. '/' .. rel_path
  local ok, lines = pcall(vim.fn.readfile, abs_path, '', 20)
  if not ok or not lines then
    return nil
  end
  for _, line in ipairs(lines) do
    local date = line:match('^date:%s*"?([%d%-]+)')
    if date then
      return date
    end
  end
  return nil
end

--- Group result lines by year read from the `date` frontmatter field.
--- Years are listed most-recent first; entries within a year are sorted by
--- date descending (so the latest entry appears at the top of each year).
--- Notes without a parseable date are dropped.
local function group_by_year(lines, heading_prefix, level)
  local groups = {}
  local order = {}

  for _, line in ipairs(lines) do
    local path = line:match('%]%((.-)%)')
    local date = path and read_frontmatter_date(path)
    if date then
      local year = date:sub(1, 4)
      if not groups[year] then
        groups[year] = {}
        table.insert(order, year)
      end
      table.insert(groups[year], { line = line, date = date })
    end
  end

  table.sort(order, function(a, b) return a > b end)

  local prefix = string.rep('#', level) .. ' '
  local output = {}
  for i, year in ipairs(order) do
    if i > 1 then
      table.insert(output, '')
    end

    if heading_prefix then
      table.insert(output, prefix .. heading_prefix .. ' (' .. year .. ')')
    else
      table.insert(output, prefix .. year)
    end

    table.sort(groups[year], function(a, b) return a.date > b.date end)

    table.insert(output, '')
    for _, item in ipairs(groups[year]) do
      table.insert(output, item.line)
    end
  end

  return output
end

--- Run a query and return formatted output lines (flat or grouped).
local function query_to_lines(parsed, current_file)
  local results = run_query(parsed, current_file)

  if parsed.group == 'letter' then
    return group_by_letter(results, parsed.heading, parsed.level)
  elseif parsed.group == 'year' then
    return group_by_year(results, parsed.heading, parsed.level)
  end

  return results
end

--- Try to match a view block starting at line i.
--- Returns query string, the marker lines to preserve, and the index after the
--- closing comment tag (-->), or nil if line i is not a view marker.
local function match_view_open(lines, i)
  -- Single-line: <!-- zk-view: ... -->
  local query = lines[i]:match(MARKER_SINGLE)
  if query then
    return query, { lines[i] }, i
  end

  -- Multiline: <!-- zk-view:\n  ...\n  -->
  local first_part = lines[i]:match(MARKER_MULTI_START)
  if first_part then
    local marker_lines = { lines[i] }
    local parts = { first_part }
    local j = i + 1

    while j <= #lines do
      table.insert(marker_lines, lines[j])

      if lines[j]:match(MARKER_COMMENT_END) then
        -- Strip the closing --> and collect any query text on this line
        local line_content = lines[j]:gsub('%-%->', '')
        table.insert(parts, line_content)
        local full_query = vim.fn.trim(table.concat(parts, ' '))
        return full_query, marker_lines, j
      end

      table.insert(parts, lines[j])
      j = j + 1
    end
  end

  return nil
end

--- Rewrite every zk-view block in `lines`, returning the new lines and the
--- number of views updated.
local function process_lines(lines, rel_path)
  local new_lines = {}
  local i = 1
  local updated = 0

  while i <= #lines do
    local query, marker_lines, marker_end = match_view_open(lines, i)

    if query then
      -- Keep the original opening marker lines (single or multiline)
      for _, ml in ipairs(marker_lines) do
        table.insert(new_lines, ml)
      end

      -- Skip old content until closing marker
      i = marker_end + 1
      while i <= #lines and not lines[i]:match(MARKER_CLOSE) do
        i = i + 1
      end

      -- Run the query and insert new content
      local parsed = parse_query(query)
      local results = query_to_lines(parsed, rel_path)

      table.insert(new_lines, '')
      for _, result_line in ipairs(results) do
        table.insert(new_lines, result_line)
      end
      table.insert(new_lines, '')

      -- Keep the closing marker
      if i <= #lines then
        table.insert(new_lines, lines[i])
      end

      updated = updated + 1
    else
      table.insert(new_lines, lines[i])
    end

    i = i + 1
  end

  return new_lines, updated
end

--- Update all zk-view blocks in the current buffer.
function M.update()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local rel_path = vim.fn.fnamemodify(filepath, ':.')

  local new_lines, updated = process_lines(lines, rel_path)

  if updated > 0 then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
    vim.notify('Updated ' .. updated .. ' view(s)', vim.log.levels.INFO)
  else
    vim.notify('No zk-view blocks found', vim.log.levels.WARN)
  end
end

--- Update zk-view blocks in every markdown file under the notebook.
--- Uses ripgrep to find files with view markers, then processes one file per
--- event-loop tick so the UI stays responsive. Files with unsaved buffer
--- changes are skipped.
function M.update_all()
  local rg_cmd = {
    'rg',
    '--files-with-matches',
    '--no-messages',
    '--fixed-strings',
    '-g',
    '*.md',
    '-g',
    '!.zk/',
    '<!-- zk-view:',
    notes_path,
  }

  vim.system(rg_cmd, { text = true }, function(result)
    vim.schedule(function()
      local files = {}
      for line in (result.stdout or ''):gmatch('[^\n]+') do
        table.insert(files, line)
      end

      local total = #files
      if total == 0 then
        vim.notify('No zk-view blocks found in notebook', vim.log.levels.INFO)
        return
      end

      local files_updated = 0
      local views_updated = 0
      local skipped_unsaved = 0
      local index = 1
      local started_at = (vim.uv or vim.loop).hrtime()

      vim.notify('Updating zk-views in ' .. total .. ' file(s)...', vim.log.levels.INFO)

      local function step()
        if index > total then
          local elapsed_ms = ((vim.uv or vim.loop).hrtime() - started_at) / 1e6
          local msg = string.format(
            'zk-views: updated %d view(s) in %d file(s) (%.0fms)',
            views_updated,
            files_updated,
            elapsed_ms
          )
          if skipped_unsaved > 0 then
            msg = msg .. ' — skipped ' .. skipped_unsaved .. ' unsaved buffer(s)'
          end
          vim.notify(msg, vim.log.levels.INFO)
          return
        end

        local file = files[index]
        index = index + 1

        local bufnr = vim.fn.bufnr(file)
        local loaded = bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr)
        local modified = loaded and vim.bo[bufnr].modified

        if modified then
          skipped_unsaved = skipped_unsaved + 1
          vim.schedule(step)
          return
        end

        local ok, lines = pcall(vim.fn.readfile, file)
        if not ok or not lines then
          vim.schedule(step)
          return
        end

        local rel_path = vim.fn.fnamemodify(file, ':.')
        local new_lines, updated = process_lines(lines, rel_path)

        if updated > 0 then
          local write_ok = pcall(vim.fn.writefile, new_lines, file)
          if write_ok then
            files_updated = files_updated + 1
            views_updated = views_updated + updated

            -- Reload the buffer from disk if it's currently loaded and unmodified
            if loaded then
              vim.api.nvim_buf_call(bufnr, function()
                vim.cmd('checktime')
              end)
            end
          end
        end

        vim.schedule(step)
      end

      vim.schedule(step)
    end)
  end)
end

--- Insert a new zk-view block at the cursor position.
function M.insert()
  vim.ui.input({ prompt = 'View query: ' }, function(query)
    if not query or query == '' then
      return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1]
    local filepath = vim.api.nvim_buf_get_name(bufnr)
    local rel_path = vim.fn.fnamemodify(filepath, ':.')

    -- Run the query
    local parsed = parse_query(query)
    local results = query_to_lines(parsed, rel_path)

    -- Build the block
    local block = {
      '<!-- zk-view: ' .. query .. ' -->',
      '',
    }
    for _, line in ipairs(results) do
      table.insert(block, line)
    end
    table.insert(block, '')
    table.insert(block, '<!-- /zk-view -->')

    -- Insert at cursor
    vim.api.nvim_buf_set_lines(bufnr, row, row, false, block)
  end)
end

return M
