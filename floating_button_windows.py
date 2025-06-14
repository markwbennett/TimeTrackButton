#!/usr/bin/env python3
"""
IACLS Time Tracker - Windows Version
A cross-platform time tracking application with project management.
"""

import sys
import sqlite3
import json
import fcntl
from datetime import datetime
from pathlib import Path
import pandas as pd
from PyQt6.QtWidgets import (QApplication, QWidget, QPushButton, QVBoxLayout, 
                            QHBoxLayout, QDialog, QComboBox, QLineEdit, 
                            QDialogButtonBox, QLabel, QMessageBox)
from PyQt6.QtCore import Qt, QTimer, QUrl
from PyQt6.QtGui import QPainter, QColor, QPen
from PyQt6.QtMultimedia import QMediaPlayer, QAudioOutput

class StateManager:
    """Manages application state with file locking for cross-platform compatibility"""
    
    def __init__(self, data_folder):
        self.data_folder = Path(data_folder)
        self.state_file = self.data_folder / ".app_state.json"
        self.lock_file = self.data_folder / ".app_state.lock"
        self.lock_handle = None
        
    def acquire_lock(self, timeout=5):
        """Acquire file lock for state management"""
        try:
            self.lock_handle = open(self.lock_file, 'w')
            if sys.platform == "win32":
                # Windows file locking
                import msvcrt
                msvcrt.locking(self.lock_handle.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                # Unix-style file locking
                fcntl.flock(self.lock_handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            return True
        except (IOError, OSError):
            if self.lock_handle:
                self.lock_handle.close()
                self.lock_handle = None
            return False
    
    def release_lock(self):
        """Release file lock"""
        if self.lock_handle:
            try:
                if sys.platform == "win32":
                    import msvcrt
                    msvcrt.locking(self.lock_handle.fileno(), msvcrt.LK_UNLCK, 1)
                else:
                    fcntl.flock(self.lock_handle.fileno(), fcntl.LOCK_UN)
            except:
                pass
            finally:
                self.lock_handle.close()
                self.lock_handle = None
    
    def save_state(self, state):
        """Save application state to file"""
        if self.acquire_lock():
            try:
                with open(self.state_file, 'w') as f:
                    json.dump(state, f)
            finally:
                self.release_lock()
    
    def load_state(self):
        """Load application state from file"""
        if self.state_file.exists():
            try:
                with open(self.state_file, 'r') as f:
                    return json.load(f)
            except:
                pass
        return {}

class DraggableHandle(QWidget):
    """Draggable container for the floating button"""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowFlags(Qt.WindowType.FramelessWindowHint | Qt.WindowType.WindowStaysOnTopHint)
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.setFixedSize(140, 140)
        
        # Create the floating button
        self.button = FloatingButton()
        
        # Layout
        layout = QVBoxLayout()
        layout.setContentsMargins(10, 10, 10, 10)
        layout.addWidget(self.button)
        self.setLayout(layout)
        
        # Dragging state
        self.dragging = False
        self.drag_start_position = None
        
        # Set default position and load saved position
        self.set_default_position()
        self.load_position()
    
    def set_default_position(self):
        """Set default position in top-right corner"""
        screen = QApplication.primaryScreen().geometry()
        x = screen.width() - self.width() - 36  # 36px from right edge
        y = 36  # 36px from top
        self.move(x, y)
    
    def save_position(self):
        """Save current position to config file"""
        try:
            config_dir = Path.home() / ".config" / "timetracker"
            config_dir.mkdir(parents=True, exist_ok=True)
            position_file = config_dir / "position"
            with open(position_file, 'w') as f:
                f.write(f"{self.x()},{self.y()}")
        except Exception as e:
            print(f"Error saving position: {e}")
    
    def load_position(self):
        """Load saved position from config file"""
        try:
            position_file = Path.home() / ".config" / "timetracker" / "position"
            if position_file.exists():
                with open(position_file, 'r') as f:
                    x, y = map(int, f.read().strip().split(','))
                    self.move(x, y)
        except Exception as e:
            print(f"Error loading position: {e}")
    
    def mousePressEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton:
            # Check if click is in the border area (drag handle)
            button_rect = self.button.geometry()
            click_pos = event.position().toPoint()
            
            # Calculate distance from button center
            button_center = button_rect.center()
            click_distance = ((click_pos.x() - button_center.x()) ** 2 + (click_pos.y() - button_center.y()) ** 2) ** 0.5
            
            # If click is outside the inner button area, start dragging
            inner_radius = (button_rect.width() / 2) - 4  # Exclude border
            if click_distance > inner_radius:
                self.dragging = True
                self.drag_start_position = event.globalPosition().toPoint() - self.pos()
                event.accept()
            else:
                event.ignore()  # Let button handle the click
    
    def mouseMoveEvent(self, event):
        if self.dragging and event.buttons() == Qt.MouseButton.LeftButton:
            self.move(event.globalPosition().toPoint() - self.drag_start_position)
            event.accept()
    
    def mouseReleaseEvent(self, event):
        if self.dragging:
            self.dragging = False
            self.save_position()
            event.accept()

class ProjectDialog(QDialog):
    """Dialog for selecting or creating projects"""
    
    def __init__(self, projects, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Select Project")
        self.setModal(True)
        
        layout = QVBoxLayout()
        
        # Project selection
        layout.addWidget(QLabel("Select or create a project:"))
        self.combo = QComboBox()
        self.combo.setEditable(True)
        
        # Add existing projects
        for project in projects:
            self.combo.addItem(project)
        
        # Add management options
        self.combo.addItem("[New Project]")
        self.combo.addItem("[Manage Projects]")
        
        layout.addWidget(self.combo)
        
        # Buttons
        buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)
        
        self.setLayout(layout)
    
    def get_selected_project(self):
        return self.combo.currentText()

class ActivityDialog(QDialog):
    """Dialog for selecting activity type"""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Select Activity Type")
        layout = QVBoxLayout()
        
        # Base legal work activity types
        base_activities = [
            "Legal research", "Investigation", "Discovery Review", 
            "File Review", "Client Communication"
        ]
        
        # Load custom activities
        custom_activities = self.load_custom_activities()
        all_activities = base_activities + custom_activities + ["Other"]
        
        self.combo = QComboBox()
        self.combo.addItems(all_activities)
        layout.addWidget(self.combo)
        
        # Custom input (hidden initially)
        self.custom_input = QLineEdit()
        self.custom_input.setPlaceholderText("Enter custom activity type")
        self.custom_input.setVisible(False)
        layout.addWidget(self.custom_input)
        
        self.combo.currentTextChanged.connect(self.on_activity_changed)
        
        buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)
        
        self.setLayout(layout)
    
    def on_activity_changed(self, text):
        self.custom_input.setVisible(text == "Other")
        if text == "Other":
            self.custom_input.setFocus()
    
    def load_custom_activities(self):
        try:
            config_file = Path.home() / ".config" / "timetracker" / "custom_activities"
            if config_file.exists():
                with open(config_file, 'r') as f:
                    return [line.strip() for line in f.readlines() if line.strip()]
            return []
        except:
            return []
    
    def save_custom_activity(self, activity):
        try:
            config_file = Path.home() / ".config" / "timetracker" / "custom_activities"
            config_file.parent.mkdir(parents=True, exist_ok=True)
            
            existing = self.load_custom_activities()
            if activity not in existing:
                existing.append(activity)
                with open(config_file, 'w') as f:
                    for act in existing:
                        f.write(f"{act}\n")
        except Exception as e:
            print(f"Error saving custom activity: {e}")
    
    def get_activity(self):
        selected = self.combo.currentText()
        if selected == "Other":
            custom_activity = self.custom_input.text().strip()
            if custom_activity:
                self.save_custom_activity(custom_activity)
                return custom_activity
            else:
                return ""
        return selected

class TrackingMenuDialog(QDialog):
    """Dialog for tracking options menu"""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Tracking Options")
        self.selected_action = None
        
        layout = QVBoxLayout()
        
        change_activity_btn = QPushButton("Change Activity")
        change_project_btn = QPushButton("Change Project")
        stop_tracking_btn = QPushButton("Stop Tracking")
        
        change_activity_btn.clicked.connect(lambda: self.select_action("change_activity"))
        change_project_btn.clicked.connect(lambda: self.select_action("change_project"))
        stop_tracking_btn.clicked.connect(lambda: self.select_action("stop_tracking"))
        
        layout.addWidget(change_activity_btn)
        layout.addWidget(change_project_btn)
        layout.addWidget(stop_tracking_btn)
        
        cancel_btn = QPushButton("Cancel")
        cancel_btn.clicked.connect(self.reject)
        layout.addWidget(cancel_btn)
        
        self.setLayout(layout)
    
    def select_action(self, action):
        self.selected_action = action
        self.accept()
    
    def get_selected_action(self):
        return self.selected_action

class FloatingButton(QPushButton):
    """Main floating button widget"""
    
    def __init__(self):
        super().__init__()
        self.setFixedSize(120, 120)
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.is_tracking = False
        self.current_project = None
        self.current_activity = None
        self.start_time = None
        
        # Setup data folder and state manager
        self.data_folder = self.get_data_folder()
        self.state_manager = StateManager(self.data_folder)
        
        self.setup_database()
        self.setup_sound()
        
        # Load initial state
        self.sync_state()
        self.update_appearance()
        
        # Setup timers
        self.sync_timer = QTimer()
        self.sync_timer.timeout.connect(self.sync_state)
        self.sync_timer.start(2000)  # 2 seconds
        
        self.display_timer = QTimer()
        self.display_timer.timeout.connect(self.update_appearance)
        self.display_timer.start(1000)  # 1 second
        
        # CSV export timer - ensure CSV is updated regularly
        self.csv_timer = QTimer()
        self.csv_timer.timeout.connect(self.export_to_csv)
        self.csv_timer.start(30000)  # 30 seconds
    
    def get_data_folder(self):
        """Get or prompt for data folder"""
        config_file = Path.home() / ".config" / "timetracker" / "config"
        
        if config_file.exists():
            data_folder = config_file.read_text().strip()
        else:
            # Default to Documents/TimeTracker on Windows
            if sys.platform == "win32":
                data_folder = str(Path.home() / "Documents" / "TimeTracker")
            else:
                data_folder = str(Path.home() / "Documents" / "TimeTracker")
            
            config_file.parent.mkdir(parents=True, exist_ok=True)
            config_file.write_text(data_folder)
        
        Path(data_folder).mkdir(parents=True, exist_ok=True)
        return data_folder
    
    def setup_sound(self):
        """Setup audio player (simplified for cross-platform)"""
        try:
            self.player = QMediaPlayer()
            self.audio_output = QAudioOutput()
            self.player.setAudioOutput(self.audio_output)
            self.audio_output.setVolume(0.1)
            
            # Try to find sound file
            sound_path = Path(__file__).parent / "bells-2-31725.mp3"
            if sound_path.exists():
                self.player.setSource(QUrl.fromLocalFile(str(sound_path)))
        except Exception as e:
            print(f"Audio setup failed: {e}")
            self.player = None
    
    def play_chime(self):
        """Play chime sound"""
        if self.player:
            try:
                self.player.play()
            except Exception as e:
                print(f"Error playing chime: {e}")
    
    def setup_database(self):
        """Setup SQLite database"""
        self.db_path = Path(self.data_folder) / ".timetrack.db"
        self.csv_path = Path(self.data_folder) / "time_entries.csv"
        
        self.conn = sqlite3.connect(str(self.db_path))
        self.cursor = self.conn.cursor()
        
        # Create table
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS time_entries (
                id INTEGER PRIMARY KEY,
                project TEXT,
                activity TEXT,
                start_time TIMESTAMP,
                end_time TIMESTAMP
            )
        ''')
        
        # Add activity column if it doesn't exist
        try:
            self.cursor.execute('ALTER TABLE time_entries ADD COLUMN activity TEXT')
        except sqlite3.OperationalError:
            pass  # Column already exists
        
        self.conn.commit()
    
    def sync_state(self):
        """Sync state with other instances"""
        try:
            # Check database for current tracking state
            self.cursor.execute('SELECT project, activity, start_time FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1')
            result = self.cursor.fetchone()
            
            if result:
                project, activity, start_time = result
                if not self.is_tracking or self.current_project != project:
                    self.is_tracking = True
                    self.current_project = project
                    self.current_activity = activity or "Legal research"
                    self.start_time = datetime.fromtimestamp(start_time) if start_time else datetime.now()
                    # Export CSV when state changes
                    self.export_to_csv()
            else:
                if self.is_tracking:
                    self.is_tracking = False
                    self.current_project = None
                    self.current_activity = None
                    self.start_time = None
                    # Export CSV when state changes
                    self.export_to_csv()
        except Exception as e:
            print(f"Error syncing state: {e}")
    
    def get_projects(self):
        """Get list of existing projects"""
        self.cursor.execute('SELECT DISTINCT project FROM time_entries WHERE project NOT LIKE "[HIDDEN]%" ORDER BY MAX(start_time) DESC')
        return [row[0] for row in self.cursor.fetchall() if row[0]]
    
    def update_appearance(self):
        """Update button appearance"""
        if self.is_tracking and self.current_project:
            # Calculate elapsed time
            elapsed = datetime.now() - self.start_time if self.start_time else datetime.now()
            hours = int(elapsed.total_seconds() // 3600)
            minutes = int((elapsed.total_seconds() % 3600) // 60)
            seconds = int(elapsed.total_seconds() % 60)
            
            # Truncate project name to 13 characters
            project_display = self.current_project[:13]
            if len(self.current_project) > 13:
                project_display = project_display[:-1] + "…"
            
            text = f"{project_display}\n{hours:02d}:{minutes:02d}:{seconds:02d}"
            color = "#4CAF50"  # Green
        else:
            text = "Not\nTracking"
            color = "#F44336"  # Red
        
        # Update button style
        self.setStyleSheet(f"""
            QPushButton {{
                background-color: {color};
                border-radius: 60px;
                border: 4px solid white;
                color: white;
                font-weight: bold;
                text-align: center;
            }}
        """)
        self.setText(text)
    
    def mousePressEvent(self, event):
        # Only accept clicks in the inner circle
        button_rect = self.rect()
        click_pos = event.position().toPoint()
        
        button_center = button_rect.center()
        click_distance = ((click_pos.x() - button_center.x()) ** 2 + (click_pos.y() - button_center.y()) ** 2) ** 0.5
        inner_radius = (button_rect.width() / 2) - 4
        
        if click_distance <= inner_radius:
            event.accept()
        else:
            event.ignore()
    
    def mouseReleaseEvent(self, event):
        button_rect = self.rect()
        click_pos = event.position().toPoint()
        
        button_center = button_rect.center()
        click_distance = ((click_pos.x() - button_center.x()) ** 2 + (click_pos.y() - button_center.y()) ** 2) ** 0.5
        inner_radius = (button_rect.width() / 2) - 4
        
        if click_distance <= inner_radius:
            if not self.is_tracking:
                self.start_new_tracking()
            else:
                self.show_tracking_menu()
    
    def start_new_tracking(self):
        """Start new tracking session"""
        dialog = ProjectDialog(self.get_projects(), self)
        if dialog.exec() == QDialog.DialogCode.Accepted:
            project = dialog.get_selected_project()
            if project and project not in ["[New Project]", "[Manage Projects]"]:
                activity_dialog = ActivityDialog(self)
                if activity_dialog.exec() == QDialog.DialogCode.Accepted:
                    activity = activity_dialog.get_activity()
                    if activity:
                        self.start_tracking(project, activity)
    
    def show_tracking_menu(self):
        """Show tracking options menu"""
        menu_dialog = TrackingMenuDialog(self)
        if menu_dialog.exec() == QDialog.DialogCode.Accepted:
            action = menu_dialog.get_selected_action()
            if action == "change_activity":
                self.change_activity()
            elif action == "change_project":
                self.change_project()
            elif action == "stop_tracking":
                self.stop_tracking()
    
    def change_activity(self):
        """Change current activity"""
        activity_dialog = ActivityDialog(self)
        if activity_dialog.exec() == QDialog.DialogCode.Accepted:
            new_activity = activity_dialog.get_activity()
            if new_activity:
                self.cursor.execute('UPDATE time_entries SET activity = ? WHERE end_time IS NULL', (new_activity,))
                self.conn.commit()
                self.current_activity = new_activity
                self.export_to_csv()
                self.update_appearance()
    
    def change_project(self):
        """Change current project and activity"""
        dialog = ProjectDialog(self.get_projects(), self)
        if dialog.exec() == QDialog.DialogCode.Accepted:
            new_project = dialog.get_selected_project()
            if new_project and new_project not in ["[New Project]", "[Manage Projects]"]:
                activity_dialog = ActivityDialog(self)
                if activity_dialog.exec() == QDialog.DialogCode.Accepted:
                    new_activity = activity_dialog.get_activity()
                    if new_activity:
                        self.cursor.execute('UPDATE time_entries SET project = ?, activity = ? WHERE end_time IS NULL', 
                                          (new_project, new_activity))
                        self.conn.commit()
                        self.current_project = new_project
                        self.current_activity = new_activity
                        self.export_to_csv()
                        self.update_appearance()
    
    def start_tracking(self, project, activity):
        """Start tracking a project"""
        try:
            self.current_project = project
            self.current_activity = activity
            self.is_tracking = True
            self.start_time = datetime.now()
            
            self.cursor.execute('INSERT INTO time_entries (project, activity, start_time) VALUES (?, ?, ?)',
                              (project, activity, int(self.start_time.timestamp())))
            self.conn.commit()
            
            # Save state
            state = {
                'is_tracking': True,
                'project': project,
                'activity': activity,
                'start_time': int(self.start_time.timestamp())
            }
            self.state_manager.save_state(state)
            
            self.play_chime()
            self.update_appearance()
        except Exception as e:
            print(f"Error starting tracking: {e}")
    
    def stop_tracking(self):
        """Stop tracking"""
        try:
            if not self.is_tracking:
                return
            
            end_time = datetime.now()
            self.cursor.execute('UPDATE time_entries SET end_time = ? WHERE end_time IS NULL',
                              (int(end_time.timestamp()),))
            self.conn.commit()
            
            self.export_to_csv()
            
            self.is_tracking = False
            self.current_project = None
            self.current_activity = None
            self.start_time = None
            
            # Save state
            state = {
                'is_tracking': False,
                'project': None,
                'activity': None,
                'start_time': None
            }
            self.state_manager.save_state(state)
            
            self.play_chime()
            self.update_appearance()
        except Exception as e:
            print(f"Error stopping tracking: {e}")
    
    def export_to_csv(self):
        """Export data to CSV"""
        try:
            self.cursor.execute('SELECT id, project, activity, start_time, end_time FROM time_entries')
            rows = self.cursor.fetchall()
            
            csv_data = []
            for row in rows:
                id_val, project, activity, start_time, end_time = row
                
                # Handle mixed timestamp formats (Unix timestamps vs datetime strings)
                start_dt = None
                end_dt = None
                
                # Convert start_time
                if start_time:
                    try:
                        if isinstance(start_time, (int, float)):
                            # Unix timestamp
                            start_dt = datetime.fromtimestamp(start_time)
                        else:
                            # String datetime
                            start_dt = datetime.fromisoformat(str(start_time).replace(' ', 'T'))
                    except (ValueError, TypeError, OSError) as e:
                        print(f"Error parsing start_time {start_time}: {e}")
                        continue
                
                # Convert end_time
                if end_time:
                    try:
                        if isinstance(end_time, (int, float)):
                            # Unix timestamp
                            end_dt = datetime.fromtimestamp(end_time)
                        else:
                            # String datetime
                            end_dt = datetime.fromisoformat(str(end_time).replace(' ', 'T'))
                    except (ValueError, TypeError, OSError) as e:
                        print(f"Error parsing end_time {end_time}: {e}")
                        # If end_time is invalid but start_time is valid, treat as ongoing
                        pass
                
                start_str = start_dt.strftime('%Y-%m-%d %H:%M:%S') if start_dt else ''
                end_str = end_dt.strftime('%Y-%m-%d %H:%M:%S') if end_dt else ''
                
                duration_str = ''
                if start_dt and end_dt:
                    duration = end_dt - start_dt
                    total_seconds = int(duration.total_seconds())
                    hours = total_seconds // 3600
                    minutes = (total_seconds % 3600) // 60
                    seconds = total_seconds % 60
                    duration_str = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
                elif start_dt and not end_dt:
                    duration = datetime.now() - start_dt
                    total_seconds = int(duration.total_seconds())
                    hours = total_seconds // 3600
                    minutes = (total_seconds % 3600) // 60
                    seconds = total_seconds % 60
                    duration_str = f"{hours:02d}:{minutes:02d}:{seconds:02d} (ongoing)"
                
                csv_data.append({
                    'ID': id_val,
                    'Project': project or '',
                    'Activity': activity or '',
                    'Start Time': start_str,
                    'End Time': end_str,
                    'Duration': duration_str
                })
            
            df = pd.DataFrame(csv_data)
            df.to_csv(self.csv_path, index=False)
            print(f"CSV exported successfully to {self.csv_path} with {len(csv_data)} entries")
        except Exception as e:
            print(f"Error exporting CSV: {e}")
            import traceback
            traceback.print_exc()

def main():
    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)
    
    handle = DraggableHandle()
    handle.show()
    
    sys.exit(app.exec())

if __name__ == "__main__":
    main() 