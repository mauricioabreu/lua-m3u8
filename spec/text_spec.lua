local text = require "text"

describe("trim text", function()
  it("should remove empty spaces from string", function()
    assert.are.same(text.trim("  foo  "), "foo")
    assert.are.same(text.trim("foo  "), "foo")
    assert.are.same(text.trim("  foo"), "foo")
    assert.are.same(text.trim("     "), "")
  end)
end)

describe("readlines", function()
  it("should read text line by line", function()
    local s = "foo\nbar\n\n\nbaz"
    local line_reader = text.readlines(s)
    local lines = {}
    for line in line_reader do
      table.insert(lines, line)
    end
    assert.are.same(#lines, 5)
  end)
end)