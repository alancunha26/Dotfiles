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

--- Run a query and return formatted output lines (flat or grouped).
local function query_to_lines(parsed, current_file)
  local results = run_query(parsed, current_file)

  if parsed.group == 'letter' then
    return group_by_letter(results, parsed.heading, parsed.level)
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

--- Update all zk-view blocks in the current buffer.
function M.update()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local rel_path = vim.fn.fnamemodify(filepath, ':.')

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

  if updated > 0 then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
    vim.notify('Updated ' .. updated .. ' view(s)', vim.log.levels.INFO)
  else
    vim.notify('No zk-view blocks found', vim.log.levels.WARN)
  end
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
