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
    assert.are.same(#playlist.variants, 5)
    local expected_variants = {
      {["URI"] = "http://example.com/low/index.m3u8", ["BANDWIDTH"] = "150000", ["RESOLUTION"] = "416x234", ["CODECS"] = "avc1.42e00a,mp4a.40.2"},
      {["URI"] = "http://example.com/lo_mid/index.m3u8", ["BANDWIDTH"] = "240000", ["RESOLUTION"] = "416x234", ["CODECS"] = "avc1.42e00a,mp4a.40.2"},
      {["URI"] = "http://example.com/hi_mid/index.m3u8", ["BANDWIDTH"] = "440000", ["RESOLUTION"] = "416x234", ["CODECS"] = "avc1.42e00a,mp4a.40.2"},
      {["URI"] = "http://example.com/high/index.m3u8", ["BANDWIDTH"] = "640000", ["RESOLUTION"] = "640x360", ["CODECS"] = "avc1.42e00a,mp4a.40.2"},
      {["URI"] = "http://example.com/audio/index.m3u8", ["BANDWIDTH"] = "64000", ["CODECS"] = "mp4a.40.5"},
    }
    assert.are.same(playlist.variants, expected_variants)
  end)
end)