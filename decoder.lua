local decoder = {}

decoder.readlines = function(s)
  if s:sub(-1) ~= "\n" then s = s .. "\n" end
  return s:gmatch("(.-)\n")
end

return decoder