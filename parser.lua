local data = require "data"
local text = require "text"

local parser = {}

local MASTER = "master"
local MEDIA = "media"

local identity_tags = {
  ["#EXT-X-STREAM-INF"] = MASTER,
  ["#EXT-X-I-FRAME-STREAM-INF"] = MASTER,
  ["#EXT-X-MEDIA-SEQUENCE"] = MEDIA,
  ["#EXT-X-SESSION-KEY"] = MASTER,
  ["#EXT-X-SESSION-DATA"] = MASTER,
  ["#EXT-X-MEDIA"] = MASTER,
  ["#EXT-X-TARGETDURATION"] = MEDIA,
  ["#EXT-X-DISCONTINUITY-SEQUENCE"] = MEDIA,
  ["#EXT-X-ENDLIST"] = MEDIA,
  ["#EXT-X-PLAYLIST-TYPE"] = MEDIA,
  ["#EXT-X-I-FRAMES-ONLY"] = MEDIA,
  ["#EXTINF"] = MEDIA,
  ["#EXT-X-BYTERANGE"] = MEDIA,
  ["#EXT-X-DISCONTINUITY"] = MEDIA,
  ["#EXT-X-KEY"] = MEDIA,
  ["#EXT-X-MAP"] = MEDIA,
  ["#EXT-X-PROGRAM-DATE-TIME"] = MEDIA,
  ["#EXT-X-DATERANGE"] = MEDIA,
}

local function is_master_tag(line)
  local tag = text.split(line, "[^:]*")[1]
  local found_tag = identity_tags[tag]
  if found_tag ~= nil then
    return found_tag == MASTER
  end
  return nil
end

local function has_master_tag(content)
  for line in text.readlines(content) do
    local is_master = is_master_tag(line)
    if is_master ~= nil then
      return is_master
    end
  end
  return nil -- tags may not be found
end

-- define if playlist is master or media
parser.is_master_playlist = function(content)
  return has_master_tag(content)
end

local function split_attributes(tag)
  local si, _ = string.find(tag, ":")
  return string.sub(tag, si + 1, #tag)
end

-- Certain tags have values that are attribute-list
-- an attribute list is a comma-separated list of attribute/value
-- pairs with no whitespace.
-- https://tools.ietf.org/html/rfc8216#section-4.2
parser.parse_attributes = function(line)
  local attributes = data.ordered_table()
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

local formats = {
  ["PROGRAM-ID"] = tonumber,
  ["BANDWIDTH"] = tonumber,
  ["AVERAGE-BANDWIDTH"] = tonumber,
  ["FRAME-RATE"] = tonumber,
}

local function formatter(tbl, fmts)
  for k, v in tbl:opairs() do
    local f = fmts[k]
    if f ~= nil then
      tbl[k] = f(v)
    else
      tbl[k] = v
    end
  end
  return tbl
end

local function format(tbl)
  return formatter(tbl, formats)
end

-- parse m3u8 playlist
-- parsed playlist could be a master or media playlist
-- playlist with an undefined type will result in errors
parser.parse = function(content)
  local is_master = parser.is_master_playlist(content)
  if  is_master == nil then
    return nil
  else
    if is_master then
      return parser.parse_master_playlist(content)
    else
      return parser.parse_media_playlist(content)
    end
  end
end

parser.parse_master_playlist = function(content)
  local playlist = {
    ["variants"] = {},
    ["iframes"] = {},
    ["independent_segments"] = false,
  }
  local curr_tag = {}
  local variant = {}
  local alternatives = {}
  for line in text.readlines(content) do
    line = text.trim(line)

    if line:match("#EXT%-X%-VERSION:%d") then
      playlist.version = tonumber(line:match("%d"))
    end
    if line:match("#EXT%-X%-STREAM%-INF:.+") then
      curr_tag.stream_inf = true
      variant = parser.parse_attributes(split_attributes(line))
      if #alternatives > 0 then
        variant["ALTERNATIVES"] = alternatives
        alternatives = {}
      end
    end
    if curr_tag.stream_inf and string.sub(line, 1, 1) ~= "#" then
      curr_tag.stream_inf = false
      variant["URI"] = line
      table.insert(playlist.variants, format(variant))
    end
    if line:match("#EXT%-X%-I%-FRAME%-STREAM%-INF:.+") then
      variant = parser.parse_attributes(split_attributes(line))
      table.insert(playlist.iframes, format(variant))
    end
    if line:match("#EXT%-X%-MEDIA:.+") then
      local alternative = parser.parse_attributes(split_attributes(line))
      table.insert(alternatives, format(alternative))
    end
    if line == "#EXT-X-INDEPENDENT-SEGMENTS" then
      playlist.independent_segments = true
    end
  end
  return playlist
end

parser.parse_media_playlist = function(content)
  local playlist = {["segments"] = {}}
  local curr_tag = {}
  local title = nil
  local segment = {}
  local key = {}
  for line in text.readlines(content) do
    line = text.trim(line)

    if line:match("#EXT%-X%-VERSION:%d") then
      playlist.version = tonumber(line:match("%d"))
    end
    if line:match("#EXTINF:.+") then
      curr_tag.extinf = true
      local si, _ = line:find(",")
      local duration = tonumber(string.sub(line, 9, si - 1))
      if #line > si then -- #EXTINF:2.002,338559 <duration>,<title>
        title = string.sub(line, si + 1, #line)
      end
      segment = {["duration"] = duration, ["title"] = title}
      -- append current key
      -- EXT-X-KEY tells the client to use the described key in the current
      -- segment and the next ones until a new EXT-X-KEY appears
      if key then
        segment.key = key
      end
    end
    if string.sub(line, 1, 1) ~= "#" then
      if curr_tag.extinf then
        segment["uri"] = line
        table.insert(playlist["segments"], segment)
        curr_tag.extinf = false
      end
      if curr_tag.key then
        playlist.segments[#playlist.segments].key = key
        curr_tag.key = false
      end
      if curr_tag.discontinuity then
        curr_tag.discontinuity = false
        playlist.segments[#playlist.segments].discontinuity = true
      end
    end
    if line:match("#EXT%-X%-TARGETDURATION:.+") then
      playlist.target_duration = tonumber(string.sub(line, 23, #line))
    end
    if line:match("#EXT%-X%-MEDIA%-SEQUENCE:.+") then
      playlist.media_sequence = tonumber(string.sub(line, 23, #line))
    end
    if line:match("#EXT%-X%-PLAYLIST%-TYPE:.+") then
      playlist.playlist_type = string.sub(line, 22, #line)
    end
    if line == "#EXT-X-DISCONTINUITY" then
      curr_tag.discontinuity = true
    end
    if line:match("#EXT%-X%-DISCONTINUITY%-SEQUENCE:.+") then
      playlist.discontinuity_sequence = tonumber(string.sub(line, 31, #line))
    end
    if line:match("#EXT%-X%-KEY:.+") then
      key = parser.parse_attributes(split_attributes(line))
      curr_tag.key = true
    end
  end
  return playlist
end

return parser