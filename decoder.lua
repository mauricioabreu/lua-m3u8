local text = require "text"

local decoder = {}

decoder.readlines = function(s)
  if s:sub(-1) ~= "\n" then s = s .. "\n" end
  return s:gmatch("(.-)\n")
end

local function split_attributes(tag)
  local si, _ = string.find(tag, ":")
  return string.sub(tag, si + 1, #tag)
end

decoder.parse_attributes = function(line)
  local attributes = {}
  repeat
    local eq_index = string.find(line, "=")
    if eq_index == nil then
      return attributes
    end
    local key = string.sub(line, 1, eq_index - 1)
    if eq_index == #line -1 then
      return attributes
    end
    line = string.sub(line, eq_index + 1, #line)
    if string.sub(line, 1, 1) == '"' then
      if #line < 3 then
        return attributes
      end
      line = string.sub(line, 2, #line)
      local qt_index = string.find(line, '"')
      if qt_index == nil then
        return attributes
      end
      attributes[key] = string.sub(line, 1, qt_index - 1)
      if qt_index > #line - 3 then
        return attributes
      end
      line = string.sub(line, qt_index + 2, #line)
    else
      local cm_index = string.find(line, ",")
      if cm_index == nil then
        cm_index = #line + 1
      end
      attributes[key] = string.sub(line, 1, cm_index - 1)
      if cm_index > #line - 2 then
        return attributes
      end
      line = string.sub(line, cm_index+1, #line)
    end
  until line == ""
end

decoder.decode = function(content)
  local playlist = {
    ["variants"] = {},
    ["iframes"] = {},
    ["independent_segments"] = false,
  }
  local curr_tag = {}
  local variant = {}
  local alternatives = {}
  for line in decoder.readlines(content) do
    line = text.trim(line)

    if line:match("#EXT%-X%-VERSION:%d") then
      playlist.version = tonumber(line:match("%d"))
    end
    if line:match("#EXT%-X%-STREAM%-INF:.+") then
      curr_tag.stream_inf = true
      variant = decoder.parse_attributes(split_attributes(line))
      if #alternatives > 0 then
        variant["ALTERNATIVES"] = alternatives
        alternatives = {}
      end
    end
    if curr_tag.stream_inf and string.sub(line, 1, 1) ~= "#" then
      curr_tag.stream_inf = false
      variant["URI"] = line
      table.insert(playlist.variants, variant)
    end
    if line:match("#EXT%-X%-I%-FRAME%-STREAM%-INF:.+") then
      variant = decoder.parse_attributes(split_attributes(line))
      table.insert(playlist.iframes, variant)
    end
    if line:match("#EXT%-X%-MEDIA:.+") then
      local alternative = decoder.parse_attributes(split_attributes(line))
      table.insert(alternatives, alternative)
    end
    if line == "#EXT-X-INDEPENDENT-SEGMENTS" then
      playlist.independent_segments = true
    end
  end
  return playlist
end

return decoder