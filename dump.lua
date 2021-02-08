local dump = {}

local function quote(s)
  return '"' .. s .. '"'
end

local formats = {
  ["CODECS"] = quote
}

local function dump_variant(variant)
  local o = "#EXT-X-STREAM-INF:"
  for k, v in variant:opairs() do
    if k ~= "URI" then
      if formats[k] then
        v = formats[k](v)
      end
      o = o .. k .. "=" .. v .. ","
    end
  end
  return string.sub(o, 1, #o - 1) .. "\n" .. variant["URI"] .. "\n"
end

dump.dump = function(playlist)
  local o = "#EXTM3U" .. "\n"
  o = o .. "#EXT-X-VERSION:" .. playlist.version .. "\n"
  for _, v in pairs(playlist.variants) do
    o = o .. dump_variant(v)
  end
  return o
end

return dump