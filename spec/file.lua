local file = {}

file.read = function(filename)
  local f = assert(io.open(filename, "rb"))
  local content = f:read("*all") -- read whole file
  f:close()
  return content
end

return file