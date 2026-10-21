//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import Quickshell
import "theme"
import "services"
import "bar"
import "panels"
import "desktop"
import "notifications"

ShellRoot {
    id: root

    // Instantiate Desktop Wallpaper on all detected screens
    Variants {
        model: Quickshell.screens

        DesktopWallpaper {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    // Instantiate TopBar on all detected screens
    Variants {
        model: Quickshell.screens

        TopBar {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    // Instantiate Desktop Clock on all detected screens
    Variants {
        model: Quickshell.screens

        DesktopClock {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    // Instantiate Desktop Antigravity Usage Widget on all detected screens
    Variants {
        model: Quickshell.screens

        AntigravityWidget {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    // Instantiate Desktop Pull Requests Widget on all detected screens
    Variants {
        model: Quickshell.screens

        PullRequestsWidget {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    // Centered & Dropdown Overlays
    AntigravityPanel {}
    Launcher {}
    ClipboardManager {}
    SessionDialog {}
    ControlCenter {}
    NotificationToasts {}
}
