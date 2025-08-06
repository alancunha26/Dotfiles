local M = {}

function M.hsl_color()
  return {
    pattern = 'hsl%(%d+,? %d+,? %d+%)',
    group = function(_, match)
      local utils = require('modules.utils.colors')
      local h, s, l = match:match('hsl%((%d+),? (%d+),? (%d+)%)')
      h, s, l = tonumber(h), tonumber(s), tonumber(l)
      local hex_color = utils.hsl_to_hex(h, s, l)
      print(hex_color)
      return MiniHipatterns.compute_hex_color_group(hex_color, 'bg')
    end,
  }
end

function M.hex_color_short()
  return {
    pattern = '#%x%x%x%f[%X]',
    -- extmark_opts = M.extmark_opts_inline,
    group = function(_, match)
      local r, g, b = match:sub(2, 2), match:sub(3, 3), match:sub(4, 4)
      local hex = string.format('#%s%s%s%s%s%s', r, r, g, g, b, b)
      return MiniHipatterns.compute_hex_color_group(hex, 'bg')
    end,
  }
end

function M.rgb_color()
  return {
    pattern = 'rgb%(%d+,? %d+,? %d+%)',
    group = function(_, match)
      local utils = require('modules.utils.colors')
      local r, g, b = match:match('rgb%((%d+),? (%d+),? (%d+)%)')
      local hex_color = utils.rgb_to_hex(r, g, b)
      return MiniHipatterns.compute_hex_color_group(hex_color, 'bg')
    end,
  }
end

function M.rgba_color()
  return {
    pattern = 'rgba%(%d+, ?%d+, ?%d+, ?%d*%.?%d*%)',
    group = function(_, match)
      local r, g, b, a = match:match('rgba%((%d+), ?(%d+), ?(%d+), ?(%d*%.?%d*)%)')
      a = tonumber(a)
      if a == nil or a < 0 or a > 1 then
        return false
      end
      local hex = string.format('#%02x%02x%02x', r * a, g * a, b * a)
      return MiniHipatterns.compute_hex_color_group(hex, 'bg')
    end,
  }
end

return M
