pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values

    readonly property MprisPlayer activePlayer: {
        if (!players || players.length === 0) return null;
        for (let i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing) {
                return players[i];
            }
        }
        return players[0];
    }

    readonly property bool hasMedia: activePlayer !== null && ((activePlayer.trackTitle && activePlayer.trackTitle.length > 0) || isPlaying)
    readonly property bool isPlaying: activePlayer !== null && activePlayer.playbackState === MprisPlaybackState.Playing
    readonly property string trackTitle: activePlayer ? (activePlayer.trackTitle || "Unknown Track") : ""
    readonly property string trackArtist: activePlayer ? (activePlayer.trackArtist || "Unknown Artist") : ""
    readonly property string trackAlbum: activePlayer ? (activePlayer.trackAlbum || "") : ""
    readonly property string trackArtUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""

    readonly property real position: activePlayer ? (activePlayer.position || 0) : 0
    readonly property real length: activePlayer ? (activePlayer.length || 0) : 0
    readonly property real progress: length > 0 ? Math.min(1.0, Math.max(0.0, position / length)) : 0.0

    readonly property bool canGoNext: activePlayer ? activePlayer.canGoNext : false
    readonly property bool canGoPrevious: activePlayer ? activePlayer.canGoPrevious : false
    readonly property bool canPlay: activePlayer ? activePlayer.canPlay : false
    readonly property bool canPause: activePlayer ? activePlayer.canPause : false

    function formatTime(seconds) {
        if (!seconds || isNaN(seconds) || seconds < 0) return "0:00";
        const totalSecs = Math.floor(seconds);
        const mins = Math.floor(totalSecs / 60);
        const secs = totalSecs % 60;
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    readonly property string positionStr: formatTime(position)
    readonly property string lengthStr: formatTime(length)

    Process {
        id: cmdProc
        running: false
    }

    function runCmd(args) {
        if (!cmdProc.running) {
            cmdProc.command = args;
            cmdProc.running = true;
        }
    }

    function playPause() {
        if (activePlayer) {
            try {
                if (typeof activePlayer.togglePlaying === "function") {
                    activePlayer.togglePlaying();
                    return;
                } else if (isPlaying && typeof activePlayer.pause === "function") {
                    activePlayer.pause();
                    return;
                } else if (!isPlaying && typeof activePlayer.play === "function") {
                    activePlayer.play();
                    return;
                }
            } catch (err) {
                console.warn("[MediaService] togglePlaying error, falling back to playerctl:", err);
            }
        }
        runCmd(["playerctl", "play-pause"]);
    }

    function next() {
        if (activePlayer) {
            try {
                if (typeof activePlayer.next === "function") {
                    activePlayer.next();
                    return;
                }
            } catch (err) {
                console.warn("[MediaService] next error, falling back to playerctl:", err);
            }
        }
        runCmd(["playerctl", "next"]);
    }

    function previous() {
        if (activePlayer) {
            try {
                if (typeof activePlayer.previous === "function") {
                    activePlayer.previous();
                    return;
                }
            } catch (err) {
                console.warn("[MediaService] previous error, falling back to playerctl:", err);
            }
        }
        runCmd(["playerctl", "previous"]);
    }

    function seekFraction(fraction) {
        if (length > 0) {
            const target = fraction * length;
            if (activePlayer) {
                try {
                    activePlayer.position = target;
                    return;
                } catch (e) {
                    // fallback
                }
            }
            runCmd(["playerctl", "position", target.toString()]);
        }
    }
}
