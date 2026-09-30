.pragma library

function hasMetadata(player) {
  return !!(player && (player.isPlaying || player.trackTitle || player.trackArtist))
}

function hasTrackMetadata(player) {
  return !!(player && (player.trackTitle || player.trackArtist))
}

function keyFor(player) {
  return player ? String(player.dbusName || player.identity || player.desktopEntry || "") : ""
}

function playerDisplayName(player) {
  if (!player) return ""
  if (player.identity && player.identity !== "") return player.identity
  var entry = String(player.desktopEntry || "").trim()
  if (entry) {
    return entry.charAt(0).toUpperCase() + entry.slice(1)
  }
  var dbus = String(player.dbusName || "")
  dbus = dbus.replace(/^org\.mpris\.MediaPlayer2\./, "")
  dbus = dbus.replace(/\.instance[0-9]+$/, "")
  if (dbus) {
    return dbus.charAt(0).toUpperCase() + dbus.slice(1)
  }
  return "Player"
}

function selectActivePlayer(players, lastActiveAt, preferredKey) {
  if (!players || players.length === 0) return null

  if (preferredKey) {
    for (var k = 0; k < players.length; k++) {
      if (keyFor(players[k]) === preferredKey && hasMetadata(players[k])) {
        return players[k]
      }
    }
  }

  var bestPlaying = null, bestPlayingOrder = -1
  var bestAny = null, bestAnyOrder = -1

  for (var i = 0; i < players.length; i++) {
    var p = players[i]
    if (!hasMetadata(p)) continue
    var key = keyFor(p)
    var order = (lastActiveAt && lastActiveAt[key]) || 0
    if (order > bestAnyOrder) {
      bestAny = p
      bestAnyOrder = order
    }
    if (p.isPlaying && order > bestPlayingOrder) {
      bestPlaying = p
      bestPlayingOrder = order
    }
  }
  return bestPlaying || bestAny
}

function filterSourcePlayers(players) {
  if (!players || players.length === 0) return []
  var list = []
  for (var i = 0; i < players.length; i++) {
    var p = players[i]
    if (hasMetadata(p)) list.push(p)
  }
  return list
}

function cleanTitle(title) {
  if (!title || typeof title !== "string") return ""
  var cleaned = title
    .replace(/\s*\([^)]*\)/g, "")
    .replace(/\s*\[[^\]]*\]/g, "")
    .replace(/\s+/g, " ")
    .trim()
  return cleaned !== "" ? cleaned : title.trim()
}

function formatTitle(title) {
  return cleanTitle(title)
}

function normalizeArtist(artist) {
  if (artist === null || artist === undefined) return ""
  var text = Array.isArray(artist) ? artist.join(", ") : String(artist)
  return text.replace(/\s*;\s*/g, ", ").replace(/\s+/g, " ").trim()
}

function trackIdentity(title, artist, playerKey) {
  return String(playerKey || "") + "::" + cleanTitle(title || "").toLowerCase() + "::" + normalizeArtist(artist).toLowerCase()
}

function formatTime(seconds) {
  if (!seconds || isNaN(seconds) || seconds < 0) return "0:00"
  var total = Math.floor(seconds)
  var hrs = Math.floor(total / 3600)
  var mins = Math.floor((total % 3600) / 60)
  var secs = total % 60
  var secsStr = secs < 10 ? "0" + secs : String(secs)
  if (hrs > 0) {
    var minsStr = mins < 10 ? "0" + mins : String(mins)
    return hrs + ":" + minsStr + ":" + secsStr
  }
  return mins + ":" + secsStr
}

function updateTrackHistory(historyList, currentTrack, maxItems) {
  if (!currentTrack || (!currentTrack.title && !currentTrack.artist)) {
    return Array.isArray(historyList) ? historyList : []
  }
  var list = Array.isArray(historyList) ? historyList.slice() : []
  var max = typeof maxItems === "number" && maxItems > 0 ? maxItems : 25
  var title = cleanTitle(currentTrack.title || "")
  var artist = normalizeArtist(currentTrack.artist)
  var album = String(currentTrack.album || "").trim()
  var playerKey = String(currentTrack.playerKey || "")

  if (!title && !artist) return list

  var identity = trackIdentity(title, artist, playerKey)
  var knownIdentity = function(item) {
    return trackIdentity(item.title || "", item.artist || "", item.playerKey || "")
  }

  // Check if first item in list matches current track
  if (list.length > 0 && knownIdentity(list[0]) === identity) {
    var updatedFirst = Object.assign({}, list[0], {
      isCurrent: true,
      artUrl: currentTrack.artUrl || list[0].artUrl,
      length: currentTrack.length || list[0].length,
      isPlaying: !!currentTrack.isPlaying
    })
    list[0] = updatedFirst
    for (var i = 1; i < list.length; i++) {
      if (list[i].isCurrent) {
        list[i] = Object.assign({}, list[i], { isCurrent: false, isPlaying: false })
      }
    }
    return list
  }

  // Drop deeper duplicates of the same track and mark previous items as not current
  var filtered = []
  for (var j = 0; j < list.length; j++) {
    if (knownIdentity(list[j]) === identity) continue
    if (list[j].isCurrent) {
      list[j] = Object.assign({}, list[j], { isCurrent: false, isPlaying: false })
    }
    filtered.push(list[j])
  }
  list = filtered

  var newItem = {
    id: playerKey + ":" + title + ":" + artist + ":" + Date.now(),
    title: title,
    artist: artist,
    album: album,
    artUrl: currentTrack.artUrl || "",
    length: currentTrack.length || 0,
    playerKey: playerKey,
    isCurrent: true,
    isPlaying: !!currentTrack.isPlaying,
    timestamp: Date.now()
  }

  list.unshift(newItem)
  if (list.length > max) list.pop()
  return list
}

function unwrapBusctlValue(obj) {
  if (obj === null || obj === undefined) return obj
  if (typeof obj !== "object") return obj
  if (Array.isArray(obj)) {
    return obj.map(unwrapBusctlValue)
  }
  if (Object.prototype.hasOwnProperty.call(obj, "type") && Object.prototype.hasOwnProperty.call(obj, "data")) {
    return unwrapBusctlValue(obj.data)
  }
  var res = {}
  for (var k in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, k)) {
      res[k] = unwrapBusctlValue(obj[k])
    }
  }
  return res
}

function parseBusctlTracksMetadata(jsonStr, currentTrackId, playerKey, currentTitle) {
  if (!jsonStr || typeof jsonStr !== "string") return []
  try {
    var parsed = JSON.parse(jsonStr)
    var unwrapped = unwrapBusctlValue(parsed)
    if (Array.isArray(unwrapped)) {
      if (unwrapped.length === 1 && Array.isArray(unwrapped[0])) {
        unwrapped = unwrapped[0]
      }
      return parseNativeTrackList(unwrapped, currentTrackId, playerKey, currentTitle)
    }
  } catch (e) {
    return []
  }
  return []
}

function parseNativeTrackList(metadataArray, currentTrackId, playerKey, currentTitle) {
  if (!Array.isArray(metadataArray) || metadataArray.length === 0) return []
  var list = []
  for (var i = 0; i < metadataArray.length; i++) {
    var item = metadataArray[i]
    if (!item) continue
    var trackId = String(item["mpris:trackid"] || item.trackid || item.id || "")
    var title = cleanTitle(String(item["xesam:title"] || item.title || item.trackTitle || ""))
    var artist = normalizeArtist(item["xesam:artist"] || item.artist || item.trackArtist || "")
    var album = String(item["xesam:album"] || item.album || "")
    var artUrl = String(item["mpris:artUrl"] || item.artUrl || "")
    var length = Number(item["mpris:length"] || item.length || 0)
    if (length > 1000000) length = length / 1000000

    if (!title && !artist) continue

    var isCurrent = false
    if (currentTrackId && trackId) {
      isCurrent = (trackId === currentTrackId)
    } else if (currentTitle) {
      isCurrent = (cleanTitle(title) === cleanTitle(currentTitle))
    }

    list.push({
      id: trackId || (playerKey + ":" + title + ":" + i),
      trackId: trackId,
      title: title,
      artist: artist,
      album: album,
      artUrl: artUrl,
      length: length,
      playerKey: playerKey || "",
      isCurrent: isCurrent,
      isNative: true
    })
  }
  return list
}

function extractUpcomingTracks(trackList, currentTrackId, currentTitle) {
  if (!Array.isArray(trackList) || trackList.length === 0) return []
  var currentIndex = -1
  for (var i = 0; i < trackList.length; i++) {
    var item = trackList[i]
    if (item.isCurrent) {
      currentIndex = i
      break
    }
    if (currentTrackId && item.trackId === currentTrackId) {
      currentIndex = i
      break
    }
    if (currentTitle && cleanTitle(item.title) === cleanTitle(currentTitle)) {
      currentIndex = i
      break
    }
  }

  if (currentIndex >= 0) {
    var upcoming = []
    for (var j = currentIndex + 1; j < trackList.length; j++) {
      var track = Object.assign({}, trackList[j], {
        queueIndex: j - currentIndex,
        isUpcoming: true,
        isCurrent: false
      })
      upcoming.push(track)
    }
    return upcoming
  }

  return []
}





