import QtQuick
import "."
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property bool launcherVisible: false
    property bool screenshotVisible: false

    // IPC handler for your launcher menu toggle
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.launcherVisible = !root.launcherVisible;
        }
    }

    // IPC handler to trigger the screenshot window
    IpcHandler {
        target: "screenshot"
        function toggle(): void {
            root.screenshotVisible = !root.screenshotVisible;
        }
    }

    property bool wallpaperVisible: false // New state

    // Existing IPC handlers...
    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            root.wallpaperVisible = !root.wallpaperVisible;
        }
    }

    WallpaperSwitcher {
        visibleState: root.wallpaperVisible
    }

    ScreenShot {
        // Binding the internal visibility state to your root state variable
        visibleState: root.screenshotVisible

        onClosed: {
            root.screenshotVisible = false;
        }
    }

    Launcher {
        visibleState: root.launcherVisible

        onAppLaunched: {
            root.launcherVisible = false;
        }
    }
    VolumeOsd {}

    TopPills{}
}
