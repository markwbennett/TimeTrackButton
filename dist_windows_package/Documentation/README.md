# IACLS Time Tracker

A macOS time tracking application that integrates with SketchyBar to provide a simple, elegant time tracking solution with project management and automatic chiming.

## Features

- **SketchyBar Integration**: Time tracker appears in your menu bar
- **Visual Status**: Green background when tracking, red icon when idle
- **Project Management**: Create, select, and manage projects with dropdown interface
- **Automatic Chiming**: 6-minute interval chimes (0.1 hours) during tracking sessions
- **Data Export**: Automatic CSV export of time entries
- **Project Organization**: Hide or delete projects, ordered by most recent use
- **Sound Feedback**: Audio confirmation when starting/stopping tracking

## Installation

### Prerequisites

- macOS with SketchyBar installed
- Homebrew (recommended for dependencies)

### Quick Install with Homebrew (Recommended)

```bash
# Add the IACLS tap
brew tap markwbennett/iacls

# Install the app and dependencies
brew install --cask iacls-time-tracker

# Follow the post-install instructions to configure SketchyBar
```

### Manual Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/markwbennett/TimeTrackButton.git
   cd TimeTrackButton
   ```

2. **Create SketchyBar plugins directory (if it doesn't exist):**
   ```bash
   mkdir -p ~/.config/sketchybar/plugins
   ```

3. **Create symlinks to the plugins:**
   ```bash
   ln -sf "$(pwd)/plugins/time_tracker.sh" ~/.config/sketchybar/plugins/
   ln -sf "$(pwd)/plugins/time_tracker_click.sh" ~/.config/sketchybar/plugins/
   ```

4. **Add to your SketchyBar configuration:**
   Add this line to your `~/.config/sketchybar/sketchybarrc`:
   ```bash
   sketchybar --add item time_tracker right \
              --set time_tracker update_freq=10 script="$PLUGIN_DIR/time_tracker.sh" click_script="$PLUGIN_DIR/time_tracker_click.sh"
   ```
   
   *See `example_sketchybarrc` for a complete example configuration.*

5. **Reload SketchyBar:**
   ```bash
   sketchybar --reload
   ```

### Floating Button App Setup

1. **Install Python dependencies:**
   ```bash
   ./setup_timetracker.sh
   ```
   Or manually:
   ```bash
   pip3 install PyQt6 pandas
   ```

2. **Launch the app:**
   ```bash
   open "IACLS Time Tracker.app"
   ```
   Or double-click `IACLS Time Tracker.app` in Finder

### Python Script Usage

Run the floating button directly:
```bash
python3 floating_button.py
```

## Usage

### First Run Setup

On your first use of the time tracker, you'll be prompted to choose a folder where your time tracking data will be stored. This dialog will appear when you first click the time tracker icon:

- **Choose a folder** where you want to store your time tracking data
- **Default location** is your Documents folder if you cancel the dialog
- **TimeTracker subfolder** will be created automatically in your chosen location
- **Configuration saved** to `~/.config/timetracker/config` for future use

### Starting/Stopping Tracking

**SketchyBar Integration:**
- **Click the time tracker icon** in your menu bar to start/stop tracking
- **When idle**: Shows red ⏱ icon
- **When tracking**: Shows green background with project name and elapsed time

**Floating Button App:**
- **Click the floating button** to start/stop tracking
- **When idle**: Shows red button with "Not Tracking"
- **When tracking**: Shows green button with project name and elapsed time
- **Draggable**: Move the button anywhere on screen by dragging the outer circle

**State Synchronization:**
- All interfaces automatically sync when you start/stop tracking in any app
- Changes appear in real-time across SketchyBar and floating button
- File locking prevents conflicts between multiple running instances

### Project Selection

When starting tracking, you'll see a dialog with:
- **Existing projects** (ordered by most recent use)
- **[New Project]** - Create a new project
- **[Manage Projects]** - Manage existing projects

### Project Management

In the Manage Projects dialog:
- **Select multiple projects** to manage
- **Remove from list only** - Hide projects from future selections (default)
- **Delete all time entries** - Permanently remove project and all its data
- **Close** - Return to project selection

### Chiming System

- **Automatic start**: Chiming begins when you start tracking
- **6-minute intervals**: Chimes every 0.1 hours during tracking
- **Volume**: Set to 0.1 (quiet) to avoid disruption
- **Stops automatically**: When you stop tracking

## Data Storage

- **First Run**: On first use, you'll be prompted to choose a folder for data storage
- **Database**: `[chosen_folder]/TimeTracker/.timetrack.db` (SQLite, hidden)
- **CSV Export**: `[chosen_folder]/TimeTracker/time_entries.csv` (auto-updated)
- **Configuration**: `~/.config/timetracker/config` stores your chosen data folder
- **Default Location**: Documents folder if no selection is made

## File Structure

```
TimeTrackButton/
├── plugins/
│   ├── time_tracker.sh          # Display script (runs every 10 seconds)
│   └── time_tracker_click.sh    # Click handler script
├── IACLS Time Tracker.app/      # macOS app bundle for floating button
│   ├── Contents/
│   │   ├── Info.plist          # App metadata
│   │   ├── MacOS/IACLS Time Tracker   # Launch script
│   │   └── Resources/          # App resources
│   │       ├── floating_button.py
│   │       ├── bells-2-31725.mp3
│   │       └── TimeTracker.icns
├── bells-2-31725.mp3            # Chime sound file
├── floating_button.py           # PyQt6 floating button with state sync
├── setup_timetracker.sh         # Setup script for dependencies
├── install_dependencies.sh      # Alternative dependency installer
├── example_sketchybarrc         # Sample SketchyBar configuration
└── README.md                    # This file
```

## Multiple Interface Options

IACLS Time Tracker offers three ways to use the time tracking system:

1. **SketchyBar Integration** - Menu bar integration (original)
2. **Floating Button App** - Standalone macOS app with draggable floating button
3. **Python Script** - Direct command line usage

All interfaces share the same data and stay synchronized through:
- **Shared Database**: All apps use the same SQLite database
- **State Synchronization**: Real-time state sharing with file locking
- **Automatic Updates**: Changes in one interface immediately reflect in others

## Configuration

### Custom Sound

Replace `bells-2-31725.mp3` with your preferred chime sound. The scripts reference the file by relative path.

### Chime Volume

To change chime volume, edit the `-v` parameter in the scripts:
```bash
afplay -v 0.1  # Current volume (0.0 to 1.0)
```

### Update Frequency

The display updates every 10 seconds by default. To change:
```bash
--set time_tracker update_freq=5  # Update every 5 seconds
```

### Change Data Folder

To change where data is stored:
1. **Stop tracking** if currently active
2. **Remove config file:**
   ```bash
   rm ~/.config/timetracker/config
   ```
3. **Click the time tracker** - you'll be prompted to choose a new folder
4. **Move existing data** (optional):
   ```bash
   mv [old_location]/TimeTracker/* [new_location]/TimeTracker/
   ```

## Troubleshooting

### Scripts Not Executing

1. **Check permissions:**
   ```bash
   chmod +x plugins/time_tracker.sh plugins/time_tracker_click.sh
   ```

2. **Verify symlinks:**
   ```bash
   ls -la ~/.config/sketchybar/plugins/time_tracker*
   ```

### Database Issues

1. **Check database location:**
   ```bash
   # Check your configured data folder
   cat ~/.config/timetracker/config
   # Then check that location
   ls -la [your_data_folder]/TimeTracker/
   ```

2. **View debug logs:**
   ```bash
   tail -f /tmp/time_tracker_click_debug.log
   ```

### Audio Not Playing

1. **Check sound file exists:**
   ```bash
   ls -la bells-2-31725.mp3
   ```

2. **Test audio manually:**
   ```bash
   afplay -v 0.1 bells-2-31725.mp3
   ```

## Development

### Debug Mode

Debug information is logged to `/tmp/time_tracker_click_debug.log`. Monitor with:
```bash
tail -f /tmp/time_tracker_click_debug.log
```

### Database Schema

```sql
CREATE TABLE time_entries (
    id INTEGER PRIMARY KEY,
    project TEXT,
    activity TEXT,
    start_time TIMESTAMP,
    end_time TIMESTAMP
);
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is open source under the MIT License. See the LICENSE file for details.

## Acknowledgments

- Built for SketchyBar by Felix Kratz
- Uses SQLite for data storage
- AppleScript for macOS dialog integration
- Developed for IACLS (iacls.org) 