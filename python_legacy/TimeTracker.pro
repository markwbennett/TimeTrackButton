QT += core widgets sql multimedia
CONFIG += c++17

TARGET = TimeTracker
TEMPLATE = app

SOURCES += main.cpp

# macOS specific settings
macx {
    QMAKE_INFO_PLIST = Info.plist
    ICON = icon.icns
    
    # Create app bundle
    CONFIG += app_bundle
    
    # Copy sound file to app bundle
    QMAKE_POST_LINK += mkdir -p $$OUT_PWD/TimeTracker.app/Contents/Resources &&
    QMAKE_POST_LINK += cp $$PWD/bells-2-31725.mp3 $$OUT_PWD/TimeTracker.app/Contents/Resources/
}

# Windows specific settings  
win32 {
    RC_ICONS = icon.ico
    
    # Copy sound file to output directory
    QMAKE_POST_LINK += copy /Y $$shell_path($$PWD/bells-2-31725.mp3) $$shell_path($$OUT_PWD/)
}

# Linux specific settings
unix:!macx {
    # Copy sound file to output directory
    QMAKE_POST_LINK += cp $$PWD/bells-2-31725.mp3 $$OUT_PWD/
} 