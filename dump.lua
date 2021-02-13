local dump = {}

local function quote(s)
  return '"' .. s .. '"'
end

local variant_formats = {
  ["CODECS"] = quote,
  ["VIDEO"] = quote,
}

local iframe_formats = {
  ["CODECS"] = quote,
  ["URI"] = quote,
  ["RESOLUTION"] = quote,
  ["VIDEO"] = quote,
}

local alternative_formats = {
  ["URI"] = quote,
  ["NAME"] = quote,
  ["GROUP-ID"] = quote,
}

local function dump_variant(variant)
  local o = ""
  if variant["ALTERNATIVES"] ~= nil then
    for _, a in pairs(variant["ALTERNATIVES"]) do
      o = o .. "#EXT-X-MEDIA:"
      for k, v in a:opairs() do
        if alternative_formats[k] then
          v = alternative_formats[k](v)
        end
        o = o .. k .. "=" .. v .. ","
      end
      o = string.sub(o, 1, #o - 1) .. "\n"
    end
  end

  o = o .. "#EXT-X-STREAM-INF:"
  for k, v in variant:opairs() do
    if k ~= "URI" and k ~= "ALTERNATIVES" then
      if variant_formats[k] then
        v = variant_formats[k](v)
      end
      o = o .. k .. "=" .. v .. ","
    end
  end
  return string.sub(o, 1, #o - 1) .. "\n" .. variant["URI"] .. "\n"
end

local function dump_iframe(iframe)
  local o = "#EXT-X-I-FRAME-STREAM-INF:"
  for k, v in iframe:opairs() do
    if iframe_formats[k] then
      v = iframe_formats[k](v)
    end
    o = o .. k .. "=" .. v .. ","
  end
  return string.sub(o, 1, #o - 1) .. "\n"
end

dump.dump = function(playlist)
  local o = "#EXTM3U" .. "\n"
  o = o .. "#EXT-X-VERSION:" .. playlist.version .. "\n"
  for _, v in pairs(playlist.variants) do
    o = o .. dump_variant(v)
  end

  for _, i in pairs(playlist.iframes) do
    o = o .. dump_iframe(i)
  end
  return o
end

return dump