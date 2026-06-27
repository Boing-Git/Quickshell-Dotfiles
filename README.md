# 🐚 Quickshell Dotfiles

> A modular, hardware-accelerated desktop shell built on **Quickshell** (QtQuick / QML) tailored for Hyprland and NixOS.

![Quickshell](https://img.shields.io/badge/Shell-Quickshell-8B5CF6?style=flat-square)
![QML](https://img.shields.io/badge/UI-QML-41CD52?style=flat-square)
![Material You](https://img.shields.io/badge/Theming-Material_3-F59E0B?style=flat-square)

This repository contains my modular desktop shell configuration. It acts as a comprehensive replacement for traditional panels (like Waybar) by utilizing Qt-based declarative UI via QML. 

*(Note: You are currently viewing the `main` branch, which uses standard JavaScript-based color and geometry variables. For the dynamic Material 3 auto-theming pipeline, see the `stringy` branch.)*

---

## ✨ Features

- **Component Isolation**: Everything is modularized into separate QML files. No single massive configuration block.
- **Centralized Theming**: All layout geometries and colors are tracked cleanly in `Variables/variables.js` and `Variables/colors.js`.
- **Integrated Daemons**: Native implementation of volume OSDs, wallpaper switchers, system launchers, screenshot interfaces, and workspace trackers.
- **Fluid Layouts**: Built from the ground up for reactive window management and smooth layout scaling.

---

## 📂 Component Overview

| Component | Description |
|-----------|-------------|
| `shell.qml` | The root component orchestrating global contexts and loading modules. |
| `StatusBar.qml` | The top bar container that manages layout positioning. |
| `TopPills.qml` | Groups status elements (WiFi, Bluetooth, Clock, Workspaces) into stylish rounded pills. |
| `HyprWorkspaces.qml` | Custom module tracking active and occupied Hyprland workspaces. |
| `Bluetooth.qml` & `Wifi.qml` | Network status and quick toggles. |
| `Launcher.qml` | Lightweight system application launcher. |
| `ScreenShot.qml` | Native interface for snapping screenshots. |
| `WallpaperSwitcher.qml` | Visual picker for swapping desktop backgrounds. |
| `VolumeOsd.qml` | Smooth on-screen display overlay for audio level changes. |
| `StringOverlay.qml` | An overlay rendering visual physics string effects. |

### Theming Configuration

Unlike monolithic shells, this setup abstracts all aesthetics into global JS files:
- `Variables/colors.js`: Defines all base, surface, primary, and tertiary colors based on Material 3 guidelines.
- `Variables/variables.js`: Single source of truth for UI spacing, border radii, padding, and layout bounds.

---

## 🛠️ Installation & Usage

**Prerequisites:**
- [Quickshell](https://outfoxxed.me/quickshell/)
- Qt6 (QtQml, QtQuick, QtWaylandClient)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Boing-Git/Quickshell-Dotfiles ~/.config/quickshell
   ```
2. **Launch the shell:**
   ```bash
   quickshell -c ~/.config/quickshell/shell.qml
   ```

To customize the colors, simply edit `Variables/colors.js`. For automated Material You syncing with Hyprland, switch to the `stringy` branch!

---
*Developed with a focus on cohesive design, performant transitions, and expressive UI/UX.*
