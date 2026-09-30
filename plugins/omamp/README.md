# MediaPlayer

MediaPlayer is a native MPRIS bar widget and popup panel plugin for the Omarchy desktop shell. It provides a clean, transparent topbar icon matching system typography and colors, alongside an interactive media panel with album artwork, clean track metadata (automatically stripped of parenthetical/bracketed noise), live time progress seeking, and playback controls.

The plugin communicates directly with MPRIS services via Quickshell, automatically tracking active audio or video sessions across browsers, Spotify, VLC, and other media players without requiring background daemons.

## Installation

### Local Development Installation

Link the repository to the Omarchy plugins directory, enable the plugin identifier, add the widget to the desired bar section, and reload the shell.

```bash
mkdir -p ~/.config/omarchy/plugins
ln -sfn "$(pwd)" ~/.config/omarchy/plugins/krosci.omamp
omarchy plugin enable krosci.omamp
omarchy bar add krosci.omamp --section right
omarchy restart shell
```

### Git Repository Installation

Install the plugin directly from the remote Git repository into the Omarchy configuration. The source below is the one declared in the project plugin catalog.

```bash
omarchy plugin add https://github.com/omaconf/omamp.git --enable --yes
omarchy bar move krosci.omamp --after omarchy.clock
omarchy restart shell
```

### Uninstallation

Remove the plugin and reload the shell.

```bash
omarchy plugin remove krosci.omamp --yes
omarchy restart shell
```

## Bar Widget Behavior

The topbar widget displays a clean icon using standard Omarchy typography without background boxes or colored highlights. When audio is actively playing, the icon displays the pause symbol (`󰏤`), switching to the play symbol (`󰐊`) when playback is paused. When no media track is active or loaded, the widget automatically collapses and hides from the bar.

Left clicking the bar icon toggles the popup card. Right clicking toggles playback state directly. Middle clicking advances to the next track. Scrolling the mouse wheel over the icon navigates between previous and next tracks. Hovering reveals track title and artist in the system tooltip.

## Media Panel Features

The popup card features masked album artwork with smooth rounded corners, falling back to a musical glyph when art is unavailable. Track titles, artist, and album subtitles are rendered cleanly with system typography.

An interactive time seek bar displays elapsed track time, total duration, and a draggable slider that allows immediate track positioning on supported players.

The control row contains previous track, play and pause toggle, and next track buttons, with optional shuffle and loop controls when supported by the active media application.

An upcoming queue section lists the next tracks in the active player's MPRIS TrackList (when exposed), allowing instant jumping to any upcoming track on supported applications.

An interactive queue and session history view tracks recently played songs, allowing instant review of track titles, artists, and playback durations.

When multiple media applications are active simultaneously, a source selection area appears at the bottom of the card, allowing instant switching between audio streams with a single click.

## Architecture

The project is organized in modular QML and JavaScript files inside the source directory.

BarWidget handles the topbar button, mouse events, and MPRIS bindings. MediaPopup defines the complete popup card layout, queue view, and source switcher. TimeSlider manages track position updates and seeking interactions. AlbumArt renders masked artwork using hardware-accelerated shaders. MediaModel contains helper routines for player selection, timestamp formatting, title cleaning, and track queue management.

## Testing

Run the automated test suite covering metadata parsing, title cleaning, time formatting, player selection, manifest validation, and QML component integrity:

```bash
npm test
```

## License

This project is licensed under the MIT License. See the LICENSE file for complete terms.

