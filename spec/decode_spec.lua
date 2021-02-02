local decoder = require "decoder"

local function read_playlist(f)
  local file = assert(io.open(f, "rb"))
  local content = file:read("*all") -- read whole file
  file:close()
  return content
end

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

describe("playlist parser", function()
  it("should decode a master playlist", function()
    local playlist = decoder.decode(read_playlist("spec/samples/master.m3u8"))
    assert.are.same(playlist.version, 3)
  end)
end)