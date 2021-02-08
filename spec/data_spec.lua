local data = require "data"

describe("ordered table", function()
  it("should create a table with ordered items", function()
    local otable = data.ordered_table()
    otable["a"] = "1"
    otable["ab"] = "2"
    otable["abc"] = "3"
    otable[1] = 4
    otable[2] = 5
    otable[3] = 6

    local expected_table = {}

    -- build a new table with ordered items to compare
    for k, v in otable:opairs() do
      expected_table[k] = v
    end

    assert.are.same(expected_table, otable)
  end)
end)