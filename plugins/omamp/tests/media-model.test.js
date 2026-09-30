import { test, describe } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";

function loadMediaModel() {
  const filePath = path.resolve(process.cwd(), "src/MediaModel.js");
  const content = fs.readFileSync(filePath, "utf8").replace(".pragma library", "");
  const context = {};
  vm.createContext(context);
  vm.runInContext(content, context);
  return context;
}

const MediaModel = loadMediaModel();

describe("MediaModel.cleanTitle", () => {
  test("removes parenthetical features and credits", () => {
    assert.equal(MediaModel.cleanTitle("Starboy (feat. Daft Punk)"), "Starboy");
    assert.equal(MediaModel.cleanTitle("Song Title (ft. Drake)"), "Song Title");
    assert.equal(MediaModel.cleanTitle("Track (with Beyoncé)"), "Track");
  });

  test("removes bracketed content like remixes and remasters", () => {
    assert.equal(MediaModel.cleanTitle("Song Title [2024 Remaster]"), "Song Title");
    assert.equal(MediaModel.cleanTitle("Track [Official Remix]"), "Track");
    assert.equal(MediaModel.cleanTitle("Track (feat. Artist) [Live]"), "Track");
  });

  test("preserves titles when trimming would result in an empty string", () => {
    assert.equal(MediaModel.cleanTitle("(Intro)"), "(Intro)");
    assert.equal(MediaModel.cleanTitle("[Untitled]"), "[Untitled]");
    assert.equal(MediaModel.cleanTitle("(Theme)"), "(Theme)");
  });

  test("normalizes multiple whitespace and handles empty or non-string inputs", () => {
    assert.equal(MediaModel.cleanTitle("  Song   Name  "), "Song Name");
    assert.equal(MediaModel.cleanTitle(""), "");
    assert.equal(MediaModel.cleanTitle(null), "");
    assert.equal(MediaModel.cleanTitle(undefined), "");
    assert.equal(MediaModel.cleanTitle(123), "");
  });
});

describe("MediaModel.formatTime", () => {
  test("formats seconds under one minute", () => {
    assert.equal(MediaModel.formatTime(0), "0:00");
    assert.equal(MediaModel.formatTime(5), "0:05");
    assert.equal(MediaModel.formatTime(42), "0:42");
  });

  test("formats minutes and seconds", () => {
    assert.equal(MediaModel.formatTime(60), "1:00");
    assert.equal(MediaModel.formatTime(75), "1:15");
    assert.equal(MediaModel.formatTime(630), "10:30");
  });

  test("formats hours when duration exceeds 60 minutes", () => {
    assert.equal(MediaModel.formatTime(3600), "1:00:00");
    assert.equal(MediaModel.formatTime(3665), "1:01:05");
    assert.equal(MediaModel.formatTime(7325), "2:02:05");
  });

  test("handles negative, invalid, or null values gracefully", () => {
    assert.equal(MediaModel.formatTime(-10), "0:00");
    assert.equal(MediaModel.formatTime(NaN), "0:00");
    assert.equal(MediaModel.formatTime(null), "0:00");
    assert.equal(MediaModel.formatTime(undefined), "0:00");
  });
});

describe("MediaModel.playerDisplayName", () => {
  test("prefers identity property", () => {
    assert.equal(MediaModel.playerDisplayName({ identity: "Spotify", desktopEntry: "spotify" }), "Spotify");
  });

  test("capitalizes desktopEntry when identity is missing", () => {
    assert.equal(MediaModel.playerDisplayName({ desktopEntry: "vlc" }), "Vlc");
    assert.equal(MediaModel.playerDisplayName({ desktopEntry: "firefox" }), "Firefox");
  });

  test("parses and capitalizes dbusName when identity and desktopEntry are missing", () => {
    assert.equal(
      MediaModel.playerDisplayName({ dbusName: "org.mpris.MediaPlayer2.spotify" }),
      "Spotify"
    );
    assert.equal(
      MediaModel.playerDisplayName({ dbusName: "org.mpris.MediaPlayer2.chromium.instance123" }),
      "Chromium"
    );
  });

  test("returns default when no identifiers are present", () => {
    assert.equal(MediaModel.playerDisplayName(null), "");
    assert.equal(MediaModel.playerDisplayName({}), "Player");
  });
});

describe("MediaModel.hasMetadata & hasTrackMetadata", () => {
  test("identifies players with actual track or playback activity", () => {
    assert.equal(MediaModel.hasMetadata({ trackTitle: "Song" }), true);
    assert.equal(MediaModel.hasMetadata({ trackArtist: "Artist" }), true);
    assert.equal(MediaModel.hasMetadata({ isPlaying: true }), true);
  });

  test("rejects idle players without media or track data", () => {
    assert.equal(MediaModel.hasMetadata({ desktopEntry: "spotify", isPlaying: false, trackTitle: "" }), false);
    assert.equal(MediaModel.hasMetadata(null), false);
    assert.equal(MediaModel.hasMetadata({}), false);
  });

  test("hasTrackMetadata strictly checks title and artist", () => {
    assert.equal(MediaModel.hasTrackMetadata({ trackTitle: "Song" }), true);
    assert.equal(MediaModel.hasTrackMetadata({ trackArtist: "Artist" }), true);
    assert.equal(MediaModel.hasTrackMetadata({ isPlaying: true }), false);
    assert.equal(MediaModel.hasTrackMetadata(null), false);
  });
});

describe("MediaModel.selectActivePlayer", () => {
  test("returns null when player list is empty or invalid", () => {
    assert.equal(MediaModel.selectActivePlayer([], {}), null);
    assert.equal(MediaModel.selectActivePlayer(null, {}), null);
  });

  test("prioritizes currently playing player", () => {
    const paused = { dbusName: "paused", isPlaying: false, trackTitle: "Song A" };
    const playing = { dbusName: "playing", isPlaying: true, trackTitle: "Song B" };
    assert.equal(MediaModel.selectActivePlayer([paused, playing], { paused: 10, playing: 5 }), playing);
  });

  test("selects most recently active paused player when none are playing", () => {
    const p1 = { dbusName: "p1", isPlaying: false, trackTitle: "Song 1" };
    const p2 = { dbusName: "p2", isPlaying: false, trackTitle: "Song 2" };
    assert.equal(MediaModel.selectActivePlayer([p1, p2], { p1: 1, p2: 5 }), p2);
  });

  test("respects preferredKey if specified and player has metadata", () => {
    const p1 = { dbusName: "p1", isPlaying: true, trackTitle: "Song 1" };
    const p2 = { dbusName: "p2", isPlaying: false, trackTitle: "Song 2" };
    assert.equal(MediaModel.selectActivePlayer([p1, p2], { p1: 10, p2: 5 }, "p2"), p2);
  });

  test("ignores idle players with empty metadata", () => {
    const idle = { dbusName: "idle", isPlaying: false, trackTitle: "" };
    assert.equal(MediaModel.selectActivePlayer([idle], {}), null);
  });
});

describe("MediaModel.filterSourcePlayers", () => {
  test("filters out idle players without media", () => {
    const active = { dbusName: "active", trackTitle: "Song", isPlaying: true };
    const idle = { dbusName: "idle", trackTitle: "", isPlaying: false };
    const list = MediaModel.filterSourcePlayers([active, idle]);
    assert.equal(list.length, 1);
    assert.equal(list[0], active);
  });
});

describe("MediaModel.updateTrackHistory", () => {
  test("adds initial track to empty history", () => {
    const track = { title: "Track A", artist: "Artist A", playerKey: "p1", isPlaying: true, length: 180 };
    const history = MediaModel.updateTrackHistory([], track, 10);
    assert.equal(history.length, 1);
    assert.equal(history[0].title, "Track A");
    assert.equal(history[0].isCurrent, true);
    assert.equal(history[0].isPlaying, true);
  });

  test("prepends new track and unmarks previous as current", () => {
    const track1 = { title: "Track A", artist: "Artist A", playerKey: "p1", isPlaying: false };
    const track2 = { title: "Track B (feat. X)", artist: "Artist B", playerKey: "p1", isPlaying: true };
    let history = MediaModel.updateTrackHistory([], track1, 10);
    history = MediaModel.updateTrackHistory(history, track2, 10);
    assert.equal(history.length, 2);
    assert.equal(history[0].title, "Track B"); // Cleaned
    assert.equal(history[0].isCurrent, true);
    assert.equal(history[1].title, "Track A");
    assert.equal(history[1].isCurrent, false);
  });

  test("updates current track without creating duplicates if identical", () => {
    const track1 = { title: "Track A", artist: "Artist A", playerKey: "p1", isPlaying: false };
    const track1Playing = { title: "Track A", artist: "Artist A", playerKey: "p1", isPlaying: true };
    let history = MediaModel.updateTrackHistory([], track1, 10);
    history = MediaModel.updateTrackHistory(history, track1Playing, 10);
    assert.equal(history.length, 1);
    assert.equal(history[0].isPlaying, true);
  });

  test("limits history to maxItems", () => {
    let history = [];
    for (let i = 1; i <= 10; i++) {
      history = MediaModel.updateTrackHistory(history, { title: "Track " + i, artist: "Artist", playerKey: "p1" }, 5);
    }
    assert.equal(history.length, 5);
    assert.equal(history[0].title, "Track 10");
  });

  test("returns original list for invalid or empty tracks", () => {
    const history = [{ title: "Existing", isCurrent: true }];
    assert.equal(MediaModel.updateTrackHistory(history, null).length, 1);
    assert.equal(MediaModel.updateTrackHistory(history, { title: "", artist: "" }).length, 1);
  });
});

describe("MediaModel.parseNativeTrackList", () => {
  test("parses array of MPRIS track metadata objects", () => {
    const raw = [
      {
        "mpris:trackid": "/org/mpris/MediaPlayer2/Track/1",
        "xesam:title": "Song 1 (feat. Artist)",
        "xesam:artist": ["Band Name"],
        "xesam:album": "Album 1",
        "mpris:length": 180000000
      },
      {
        "mpris:trackid": "/org/mpris/MediaPlayer2/Track/2",
        "xesam:title": "Song 2 [Live]",
        "xesam:artist": "Solo Artist",
        "xesam:album": "Album 2",
        "mpris:length": 210
      }
    ];

    const result = MediaModel.parseNativeTrackList(raw, "/org/mpris/MediaPlayer2/Track/1", "vlc");
    assert.equal(result.length, 2);
    assert.equal(result[0].title, "Song 1"); // Cleaned
    assert.equal(result[0].artist, "Band Name");
    assert.equal(result[0].length, 180); // Converted from microseconds
    assert.equal(result[0].isCurrent, true);
    assert.equal(result[0].isNative, true);

    assert.equal(result[1].title, "Song 2");
    assert.equal(result[1].artist, "Solo Artist");
    assert.equal(result[1].length, 210);
    assert.equal(result[1].isCurrent, false);
  });

  test("matches current track by title when trackId is not provided", () => {
    const raw = [
      { "xesam:title": "Song One (Remix)", "xesam:artist": "Artist 1" },
      { "xesam:title": "Song Two", "xesam:artist": "Artist 2" }
    ];
    const result = MediaModel.parseNativeTrackList(raw, null, "spotify", "Song One");
    assert.equal(result[0].isCurrent, true);
    assert.equal(result[1].isCurrent, false);
  });

  test("handles empty or invalid inputs", () => {
    assert.equal(MediaModel.parseNativeTrackList(null).length, 0);
    assert.equal(MediaModel.parseNativeTrackList([]).length, 0);
    assert.equal(MediaModel.parseNativeTrackList([{}, { title: "" }]).length, 0);
  });
});

describe("MediaModel.unwrapBusctlValue & parseBusctlTracksMetadata", () => {
  test("unwraps busctl typed dictionary responses", () => {
    const input = {
      type: "a{sv}",
      data: {
        title: { type: "s", data: "Hello World" },
        count: { type: "i", data: 42 },
        active: { type: "b", data: true },
        tags: { type: "as", data: ["a", "b"] }
      }
    };
    const unwrapped = JSON.parse(JSON.stringify(MediaModel.unwrapBusctlValue(input)));
    assert.deepEqual(unwrapped, {
      title: "Hello World",
      count: 42,
      active: true,
      tags: ["a", "b"]
    });
  });

  test("parses busctl JSON output into track list", () => {
    const busctlJson = JSON.stringify({
      type: "aa{sv}",
      data: [
        [
          {
            "mpris:trackid": { type: "o", data: "/org/mpris/MediaPlayer2/Track/1" },
            "xesam:title": { type: "s", data: "Busctl Track 1 (feat. Singer)" },
            "xesam:artist": { type: "as", data: ["Producer", "Singer"] },
            "xesam:album": { type: "s", data: "EP 1" },
            "mpris:length": { type: "t", data: 240000000 }
          },
          {
            "mpris:trackid": { type: "o", data: "/org/mpris/MediaPlayer2/Track/2" },
            "xesam:title": { type: "s", data: "Busctl Track 2" },
            "xesam:artist": { type: "s", data: "Producer" },
            "mpris:length": { type: "t", data: 180000000 }
          }
        ]
      ]
    });

    const list = MediaModel.parseBusctlTracksMetadata(busctlJson, "/org/mpris/MediaPlayer2/Track/1", "player1");
    assert.equal(list.length, 2);
    assert.equal(list[0].title, "Busctl Track 1");
    assert.equal(list[0].artist, "Producer, Singer");
    assert.equal(list[0].length, 240);
    assert.equal(list[0].isCurrent, true);
    assert.equal(list[0].isNative, true);

    assert.equal(list[1].title, "Busctl Track 2");
    assert.equal(list[1].isCurrent, false);
  });

  test("handles invalid JSON or empty input gracefully", () => {
    assert.equal(MediaModel.parseBusctlTracksMetadata("").length, 0);
    assert.equal(MediaModel.parseBusctlTracksMetadata(null).length, 0);
    assert.equal(MediaModel.parseBusctlTracksMetadata("{ invalid json").length, 0);
    assert.equal(MediaModel.parseBusctlTracksMetadata(JSON.stringify({ data: "not an array" })).length, 0);
  });
});

describe("MediaModel.extractUpcomingTracks", () => {
  test("extracts upcoming tracks strictly following current track", () => {
    const tracks = [
      { trackId: "/track/1", title: "Song 1", isCurrent: false },
      { trackId: "/track/2", title: "Song 2", isCurrent: true },
      { trackId: "/track/3", title: "Song 3", isCurrent: false },
      { trackId: "/track/4", title: "Song 4", isCurrent: false }
    ];

    const upcoming = MediaModel.extractUpcomingTracks(tracks, "/track/2", "Song 2");
    assert.equal(upcoming.length, 2);
    assert.equal(upcoming[0].title, "Song 3");
    assert.equal(upcoming[0].queueIndex, 1);
    assert.equal(upcoming[0].isUpcoming, true);
    assert.equal(upcoming[1].title, "Song 4");
    assert.equal(upcoming[1].queueIndex, 2);
  });

  test("returns empty array when current track is the last in the queue", () => {
    const tracks = [
      { trackId: "/track/1", title: "Song 1", isCurrent: false },
      { trackId: "/track/2", title: "Song 2", isCurrent: true }
    ];
    const upcoming = MediaModel.extractUpcomingTracks(tracks, "/track/2", "Song 2");
    assert.equal(upcoming.length, 0);
  });

  test("matches current track by title when trackId is absent", () => {
    const tracks = [
      { title: "Song A (Remix)" },
      { title: "Song B" }
    ];
    const upcoming = MediaModel.extractUpcomingTracks(tracks, "", "Song A");
    assert.equal(upcoming.length, 1);
    assert.equal(upcoming[0].title, "Song B");
  });

  test("handles empty or invalid lists", () => {
    assert.equal(MediaModel.extractUpcomingTracks(null).length, 0);
    assert.equal(MediaModel.extractUpcomingTracks([]).length, 0);
  });
});

describe("MediaModel.normalizeArtist", () => {
  test("joins artist arrays with commas", () => {
    assert.equal(MediaModel.normalizeArtist(["Band A", "Band B"]), "Band A, Band B");
  });

  test("converts semicolon separators to commas", () => {
    assert.equal(MediaModel.normalizeArtist("Artist A;Artist B"), "Artist A, Artist B");
  });

  test("collapses whitespace and trims", () => {
    assert.equal(MediaModel.normalizeArtist("  Artist   A  "), "Artist A");
  });

  test("handles empty or non-string inputs", () => {
    assert.equal(MediaModel.normalizeArtist(""), "");
    assert.equal(MediaModel.normalizeArtist(null), "");
    assert.equal(MediaModel.normalizeArtist(undefined), "");
  });
});

describe("MediaModel.trackIdentity", () => {
  test("matches tracks despite title noise and artist spacing", () => {
    const a = MediaModel.trackIdentity("Song X (feat. Y)", "Artist  A", "p1");
    const b = MediaModel.trackIdentity("Song X", "Artist A", "p1");
    assert.equal(a, b);
  });

  test("distinguishes different players", () => {
    const a = MediaModel.trackIdentity("Song", "Artist", "p1");
    const b = MediaModel.trackIdentity("Song", "Artist", "p2");
    assert.notEqual(a, b);
  });
});

describe("MediaModel.updateTrackHistory dedup", () => {
  test("removes deeper duplicate when track reappears", () => {
    const a = { title: "Track A", artist: "Artist A", playerKey: "p1" };
    const b = { title: "Track B", artist: "Artist B", playerKey: "p1" };
    let history = MediaModel.updateTrackHistory([], a, 10);
    history = MediaModel.updateTrackHistory(history, b, 10);
    history = MediaModel.updateTrackHistory(history, { title: "Track A (Remix Cut)", artist: "Artist A", playerKey: "p1", isPlaying: true }, 10);
    assert.equal(history.length, 2);
    assert.equal(history[0].title, "Track A");
    assert.equal(history[0].isCurrent, true);
    assert.equal(history[1].title, "Track B");
  });

  test("normalizes semicolon artists in stored items", () => {
    const history = MediaModel.updateTrackHistory([], { title: "T", artist: "A;B", playerKey: "p1" }, 10);
    assert.equal(history[0].artist, "A, B");
  });
});

describe("MediaModel.parseNativeTrackList artist", () => {
  test("normalizes array and semicolon artists", () => {
    const raw = [
      { "mpris:trackid": "/t/1", "xesam:title": "S1", "xesam:artist": ["A", "B"] },
      { "mpris:trackid": "/t/2", "xesam:title": "S2", "xesam:artist": "C;D" }
    ];
    const result = MediaModel.parseNativeTrackList(raw, null, "vlc", null);
    assert.equal(result[0].artist, "A, B");
    assert.equal(result[1].artist, "C, D");
  });
});




