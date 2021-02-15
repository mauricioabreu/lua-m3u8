local data = {}

data.ordered_table = function(t)
  local mt = {}
  -- set methods
  mt.__index = {
    -- set key order table inside __index for faster lookup
    _korder = {},
    -- traversal of hidden values
    hidden = function() return pairs(mt.__index) end,
    -- traversal of table ordered: returning index, key
    ipairs = function(self) return ipairs(self._korder) end,
    -- traversal of table
    pairs = function(self) return pairs(self) end,
    -- traversal of table ordered: returning key,value
    opairs = function(self)
      local i = 0
      local function iter(s)
          i = i + 1
          local k = s._korder[i]
          if k then
            return k, s[k]
          end
      end
      return iter, self
    end,
    -- to be able to delete entries we must write a delete function
    del = function(self, key)
      if self[key] then
          self[key] = nil
          for i, k in ipairs(self._korder) do
            if k == key then
                table.remove(self._korder, i)
                return
            end
          end
      end
    end
  }
  -- set new index handling
  mt.__newindex = function(self, k, v)
    if k ~= "del" and v then
      rawset(self, k,  v)
      table.insert(self._korder, k)
    end
  end
  return setmetatable(t or {}, mt)
end

return data