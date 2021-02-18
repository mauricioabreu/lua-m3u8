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

  it("should parse a master playlist with independent segments", function()
    local playlist = parser.parse(file.read("spec/samples/master_with_independent_segments.m3u8"))
    assert.are.same(playlist.independent_segments, true)
  end)

  it("should parse a media playlist", function()
    local playlist = parser.parse_media_playlist(file.read("spec/samples/media.m3u8"))
    assert.are.same(playlist.version, 3)
    assert.are.same(#playlist.segments, 4)
    assert.are.same(playlist.segments[1].uri, "ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb.ts")
    assert.are.same(playlist.segments[1].duration, 2.002)
    assert.are.same(playlist.segments[1].title, "338559")
    assert.are.same(playlist.target_duration, 3)
    assert.are.same(playlist.media_sequence, 22)
    assert.are.same(playlist.playlist_type, "EVENT")
    assert.are.same(playlist.discontinuity_sequence, 20)
  end)

  it("should parse a media playlist with encrypted keys", function()
    local playlist = parser.parse_media_playlist(file.read("spec/samples/media_with_keys.m3u8"))
    assert.are.same(#playlist.segments, 4)
    -- check first segment key
    assert.are.same(playlist.segments[1].key["METHOD"], "AES-128")
    assert.are.same(playlist.segments[1].key["URI"], "https://getkeys.com/key?id=123")
    assert.are.same(playlist.segments[1].key["IV"], "0X10ef8f758ca555115584bb5b3c687f52")
    -- next segment must have the same key
    assert.are.same(playlist.segments[2].key["METHOD"], "AES-128")
    assert.are.same(playlist.segments[2].key["URI"], "https://getkeys.com/key?id=123")
    assert.are.same(playlist.segments[2].key["IV"], "0X10ef8f758ca555115584bb5b3c687f52")
    -- check next new key
    assert.are.same(playlist.segments[3].key["METHOD"], "AES-128")
    assert.are.same(playlist.segments[3].key["URI"], "https://getkeys.com/key?id=123")
    assert.are.same(playlist.segments[3].key["IV"], "0Xcafe8f758ca555115584bb5b3c687f52")
  end)

  it("should define playlist as master", function()
    local playlist = file.read("spec/samples/master.m3u8")
    assert.are.same(parser.is_master_playlist(playlist), true)
  end)

  it("should define playlist not as master", function()
    local playlist = file.read("spec/samples/media.m3u8")
    assert.are.same(parser.is_master_playlist(playlist), false)
  end)
end)