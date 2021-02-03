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
  it("should parse attributes list", function()
    local line = "PROGRAM-ID=1,BANDWIDTH=346000,RESOLUTION=384x216"
    local attributes = decoder.parse_attributes(line)
    assert.are.same(attributes["PROGRAM-ID"], "1")
    assert.are.same(attributes["BANDWIDTH"], "346000")
    assert.are.same(attributes["RESOLUTION"], "384x216")
  end)

  it("should decode a master playlist", function()
    local playlist = decoder.decode(read_playlist("spec/samples/master.m3u8"))
    assert.are.same(playlist.version, 3)
  end)
end)