package.path = package.path .. ';spec/?.lua'

local dump = require "dump"
local file = require "file"
local parser = require "parser"

describe("dump playlist", function()
  it("should dump a master playlist", function()
    local content = file.read("spec/samples/master.m3u8")
    local playlist = parser.parse(content)
    local output = dump.dump(playlist)
    assert.are.same(content, output)
  end)

  it("should dump a master playlist with iframes", function()
    local content = file.read("spec/samples/master_with_iframes.m3u8")
    local playlist = parser.parse(content)
    local output = dump.dump(playlist)
    assert.are.same(content, output)
  end)

  it("should dump a master playlist with alternatives", function()
    local content = file.read("spec/samples/master_with_alternatives.m3u8")
    local playlist = parser.parse(content)
    local output = dump.dump(playlist)
    assert.are.same(content, output)
  end)
end)