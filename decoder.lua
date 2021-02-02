local decoder = {}

decoder.readlines = function(s)
  if s:sub(-1) ~= "\n" then s = s .. "\n" end
  return s:gmatch("(.-)\n")
end

decoder.decode = function(content)
  local playlist = {}
  for line in decoder.readlines(content) do
    if line:match("#EXT%-X%-VERSION:%d") then
      playlist.version = tonumber(line:match("%d"))
    end
  end
  return playlist
end

return decoder