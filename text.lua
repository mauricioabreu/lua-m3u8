local text = {}

text.trim = function(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

text.readlines = function(s)
  if s:sub(-1) ~= "\n" then s = s .. "\n" end
  return s:gmatch("(.-)\n")
end

-- split string based on pattern
text.split = function(s, p)
  local tbl = {}
  s:gsub(p, function(x) tbl[#tbl + 1] = x end)
  return tbl
end

return text