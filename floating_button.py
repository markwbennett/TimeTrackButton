#!/usr/bin/env python3

import sys
import sqlite3
import pandas as pd
from datetime import datetime
import os
from pathlib import Path
from PyQt6.QtWidgets import QApplication, QPushButton, QComboBox, QDialog, QVBoxLayout, QLineEdit, QDialogButtonBox, QWidget, QHBoxLayout
from PyQt6.QtCore import Qt, QPoint, QTimer, QUrl
from PyQt6.QtGui import QColor, QPainter, QPen, QPainterPath
from PyQt6.QtMultimedia import QMediaPlayer, QAudioOutput

class DraggableHandle(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setFixedSize(170, 70)  # Larger than button to create handle area
        self.setWindowFlags(Qt.WindowType.FramelessWindowHint | Qt.WindowType.WindowStaysOnTopHint)
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.old_pos = None
        
        layout = QHBoxLayout()
        layout.setContentsMargins(10, 10, 10, 10)
        self.button = FloatingButton()
        layout.addWidget(self.button)
        self.setLayout(layout)

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        
        # Draw handle circle
        pen = QPen(QColor(100, 100, 100, 100))
        pen.setWidth(2)
        painter.setPen(pen)
        painter.drawEllipse(5, 5, self.width()-10, self.height()-10)

    def mousePressEvent(self, event):
        self.old_pos = event.globalPosition().toPoint()

    def mouseMoveEvent(self, event):
        if self.old_pos:
            delta = event.globalPosition().toPoint() - self.old_pos
            self.move(self.x() + delta.x(), self.y() + delta.y())
            self.old_pos = event.globalPosition().toPoint()

    def mouseReleaseEvent(self, event):
        self.old_pos = None

class ProjectDialog(QDialog):
    def __init__(self, projects, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Select Project")
        layout = QVBoxLayout()
        
        self.combo = QComboBox()
        self.combo.addItem("New Project")
        self.combo.addItems(projects)
        self.combo.setEditable(True)
        self.combo.setInsertPolicy(QComboBox.InsertPolicy.InsertAtBottom)
        layout.addWidget(self.combo)
        
        self.new_project_input = QLineEdit()
        self.new_project_input.setPlaceholderText("Enter new project name")
        self.new_project_input.setVisible(False)
        layout.addWidget(self.new_project_input)
        
        self.combo.currentTextChanged.connect(self.on_project_changed)
        
        buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)
        
        self.setLayout(layout)
    
    def on_project_changed(self, text):
        self.new_project_input.setVisible(text == "New Project")
    
    def get_selected_project(self):
        if self.combo.currentText() == "New Project":
            return self.new_project_input.text()
        return self.combo.currentText()

class FloatingButton(QPushButton):
    def __init__(self):
        super().__init__()
        self.setFixedSize(150, 50)
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.is_tracking = False
        self.current_project = None
        self.start_time = None
        self.setup_database()
        self.setup_sound()
        self.update_appearance()
        
        self.chime_timer = QTimer()
        self.chime_timer.timeout.connect(self.play_chime)
        self.chime_timer.setInterval(6 * 60 * 1000)  # 6 minutes in milliseconds

    def setup_sound(self):
        self.player = QMediaPlayer()
        self.audio_output = QAudioOutput()
        self.player.setAudioOutput(self.audio_output)
        self.audio_output.setVolume(0.5)
        sound_path = Path("/Users/markbennett/github/TimeTrackButton/bells-2-31725.mp3")
        self.player.setSource(QUrl.fromLocalFile(str(sound_path)))

    def play_chime(self):
        self.player.setPosition(0)
        self.player.play()

    def setup_database(self):
        self.conn = sqlite3.connect('timetrack.db')
        self.cursor = self.conn.cursor()
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS time_entries (
                id INTEGER PRIMARY KEY,
                project TEXT,
                start_time TIMESTAMP,
                end_time TIMESTAMP
            )
        ''')
        self.conn.commit()

    def get_projects(self):
        self.cursor.execute('SELECT DISTINCT project FROM time_entries ORDER BY project')
        projects = [row[0] for row in self.cursor.fetchall()]
        return projects

    def update_appearance(self):
        color = "red" if not self.is_tracking else "green"
        text = "Not Tracking" if not self.is_tracking else self.current_project
        self.setStyleSheet(f"""
            QPushButton {{
                background-color: {color};
                border-radius: 25px;
                border: 2px solid black;
                color: white;
                font-weight: bold;
            }}
        """)
        self.setText(text)

    def mousePressEvent(self, event):
        event.accept()  # Prevent event from reaching parent

    def mouseMoveEvent(self, event):
        event.accept()  # Prevent event from reaching parent

    def mouseReleaseEvent(self, event):
        if not self.is_tracking:
            dialog = ProjectDialog(self.get_projects(), self)
            if dialog.exec() == QDialog.DialogCode.Accepted:
                project = dialog.get_selected_project()
                if project:  # Only start tracking if a project name was provided
                    self.current_project = project
                    self.is_tracking = True
                    self.start_time = datetime.now()
                    self.update_appearance()
                    self.chime_timer.stop()
                    self.chime_timer.start()
                    self.play_chime()
        else:
            self.is_tracking = False
            self.chime_timer.stop()
            self.chime_timer.start()
            self.play_chime()
            end_time = datetime.now()
            self.cursor.execute('''
                INSERT INTO time_entries (project, start_time, end_time)
                VALUES (?, ?, ?)
            ''', (self.current_project, self.start_time, end_time))
            self.conn.commit()
            self.export_to_csv()
            self.current_project = None
            self.update_appearance()

    def export_to_csv(self):
        self.cursor.execute('SELECT * FROM time_entries')
        rows = self.cursor.fetchall()
        df = pd.DataFrame(rows, columns=['id', 'project', 'start_time', 'end_time'])
        df.to_csv('time_entries.csv', index=False)

def main():
    app = QApplication(sys.argv)
    handle = DraggableHandle()
    handle.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main() 