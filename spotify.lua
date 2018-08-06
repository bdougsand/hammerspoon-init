local emacs = {}

local lastVolume = hs.spotify.getVolume()
function spotify.toggleMute()
  local volume = hs.spotify.getVolume()
  if volume <= 5 then
    hs.spotify.setVolume(lastSpotifyVolume)
  else
    hs.spotify.setVolume(1)
    lastSpotifyVolume = volume
  end
end

function spotify.copySongDetails()
  local title = hs.spotify.getCurrentTrack()
  local artist = hs.spotify.getCurrentArtist()
  local album = hs.spotify.getCurrentAlbum()

  hs.pasteboard.setContents(
    "\"" .. title .. "\" by " .. artist .. " (from " .. album .. ")")
end

function spotify.replay()
  hs.spotify.setPosition(0)
end

hs.hotkey.bind({"shift"}, "F12", spotify.toggleMute)
hs.hotkey.bind({}, "F2", hs.spotify.displayCurrentTrack)
hs.hotkey.bind({"shift"}, "F2", spotify.copySongDetails)


return spotify
