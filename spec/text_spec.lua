local text = require "text"

describe("trim text", function()
  it("should remove empty spaces from string", function()
    assert.are.same(text.trim("  foo  "), "foo")
    assert.are.same(text.trim("foo  "), "foo")
    assert.are.same(text.trim("  foo"), "foo")
    assert.are.same(text.trim("     "), "")
  end)
end)