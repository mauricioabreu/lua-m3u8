package.path = package.path .. ';spec/?.lua'

local file = require "file"
local parser = require "parser"

describe("playlist parser", function()
  it("should parse attributes list", function()
    local line = "PROGRAM-ID=1,BANDWIDTH=346000,RESOLUTION=384x216"
    local attributes = parser.parse_attributes(line)
    assert.are.same(attributes["PROGRAM-ID"], "1")
    assert.are.same(attributes["BANDWIDTH"], "346000")
    assert.are.same(attributes["RESOLUTION"], "384x216")
  end)

  it("should parse a master playlist", function()
    local playlist = parser.parse(file.read("spec/samples/master.m3u8"))
    assert.are.same(playlist.version, 3)
    assert.are.same(#playlist.variants, 5)
    assert.are.same(playlist.independent_segments, false)
    local expected_variants = {
      {
        ["URI"] = "http://example.com/low/index.m3u8",
        ["BANDWIDTH"] = 150000,
        ["RESOLUTION"] = "416x234",
        ["CODECS"] = "avc1.42e00a,mp4a.40.2"
      },
      {
        ["URI"] = "http://example.com/lo_mid/index.m3u8",
        ["BANDWIDTH"] = 240000,
        ["RESOLUTION"] = "416x234",
        ["CODECS"] = "avc1.42e00a,mp4a.40.2"},
      {
        ["URI"] = "http://example.com/hi_mid/index.m3u8",
        ["BANDWIDTH"] = 440000,
        ["RESOLUTION"] = "416x234",
        ["CODECS"] = "avc1.42e00a,mp4a.40.2"
      },
      {
        ["URI"] = "http://example.com/high/index.m3u8",
        ["BANDWIDTH"] = 640000,
        ["RESOLUTION"] = "640x360",
        ["CODECS"] = "avc1.42e00a,mp4a.40.2"
      },
      {
        ["URI"] = "http://example.com/audio/index.m3u8",
        ["BANDWIDTH"] = 64000,
        ["CODECS"] = "mp4a.40.5"
      },
    }
    assert.are.same(playlist.variants, expected_variants)
  end)

  it("should parse a master playlist with iframes", function()
    local playlist = parser.parse(file.read("spec/samples/master_with_iframes.m3u8"))
    local expected_iframes = {
      {
        ["URI"] = "low/iframe.m3u8",
        ["BANDWIDTH"] = 86000,
        ["PROGRAM-ID"] = 1,
        ["CODECS"] = "c1",
        ["RESOLUTION"] = "1x1",
        ["VIDEO"] = "1"
      },
      {
        ["URI"] = "mid/iframe.m3u8",
        ["BANDWIDTH"] = 150000,
        ["PROGRAM-ID"] = 1,
        ["CODECS"] = "c2",
        ["RESOLUTION"] = "2x2",
        ["VIDEO"] = "2"
      },
      {
        ["URI"] = "hi/iframe.m3u8",
        ["BANDWIDTH"] = 550000,
        ["PROGRAM-ID"] = 1,
        ["CODECS"] = "c2",
        ["RESOLUTION"] = "2x2",
        ["VIDEO"] = "2"
      },
      {
        ["URI"] = "hi/iframe.m3u8",
        ["BANDWIDTH"] = 86000,
        ["PROGRAM-ID"] = 1,
        ["CODECS"] = "c2",
        ["RESOLUTION"] = "2x2",
        ["VIDEO"] = "2"
      }
    }
    assert.are.same(playlist.iframes, expected_iframes)
  end)

  it("should parse a master playlist with alternatives", function()
    local playlist = parser.parse(file.read("spec/samples/master_with_alternatives.m3u8"))
    assert.are.same(#playlist.variants[1]["ALTERNATIVES"], 3)
    assert.are.same(#playlist.variants[2]["ALTERNATIVES"], 3)
    assert.are.same(#playlist.variants[3]["ALTERNATIVES"], 3)
    assert.are.same(playlist.variants[4]["ALTERNATIVES"], nil) -- this one is an audio playlist without alternatives
  end)

  it("should parse a master playlsit with independent segments", function()
    local playlist = parser.parse(file.read("spec/samples/master_with_independent_segments.m3u8"))
    assert.are.same(playlist.independent_segments, true)
  end)
end)