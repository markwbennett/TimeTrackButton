# IACLS Time Tracker macOS App

A floating button time tracker that syncs with SketchyBar and other IACLS Time Tracker interfaces.

## Quick Start

1. **Install dependencies:**
   ```bash
   ./setup_timetracker.sh
   ```

2. **Launch the app:**
   ```bash
   open "IACLS Time Tracker.app"
   ```
   Or double-click `IACLS Time Tracker.app` in Finder

## Features

- **Floating Button**: Draggable time tracking button that stays on top
- **State Synchronization**: Automatically syncs with SketchyBar and other IACLS Time Tracker apps
- **File Locking**: Prevents conflicts between multiple running instances
- **Real-time Updates**: Shows current project and elapsed time
- **Sound Feedback**: Audio chimes during tracking sessions

## Usage

- **Click** the inner button to start/stop tracking
- **Drag** the border area (white or black) to move the button around the screen
- **Red button**: Not tracking
- **Green button**: Currently tracking (shows project name and time)

## Requirements

- macOS 10.15+
- Python 3.8+
- PyQt6 and pandas packages

## Troubleshooting

If the app won't launch:

1. **Check Python installation:**
   ```bash
   python3 --version
   ```

2. **Install missing packages:**
   ```bash
   pip3 install PyQt6 pandas
   ```

3. **Check launch log:**
   ```bash
   cat /tmp/timetracker_launch.log
   ```

## Data Storage

The app uses the same data folder as other IACLS Time Tracker interfaces:
- Configuration: `~/.config/timetracker/config`
- Database: `[chosen_folder]/TimeTracker/timetrack.db`
- State file: `[chosen_folder]/TimeTracker/app_state.json`
- Lock file: `[chosen_folder]/TimeTracker/app_state.lock` 