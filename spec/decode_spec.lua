local decoder = require "decoder"

describe("playlist reader", function()
  it("should read text line by line", function()
    local text = "foo\nbar\n\n\nbaz"
    local line_reader = decoder.readlines(text)
    local lines = {}
    for line in line_reader do
      table.insert(lines, line)
    end
    assert.are.same(#lines, 5)
  end)
end)