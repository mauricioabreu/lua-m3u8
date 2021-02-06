local text = {}

text.trim = function(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

return text