#include <QtWidgets/QApplication>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QWidget>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QDialog>
#include <QtWidgets/QDialogButtonBox>
#include <QtCore/QTimer>
#include <QtCore/QStandardPaths>
#include <QtCore/QDir>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QLockFile>
#include <QtGui/QPainter>
#include <QtGui/QPen>
#include <QtGui/QColor>
#include <QtMultimedia/QMediaPlayer>
#include <QtMultimedia/QAudioOutput>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlError>
#include <QDateTime>
#include <QFile>
#include <QTextStream>
#include <QFileInfo>
#include <QMouseEvent>
#include <QScreen>
#include <QGuiApplication>
#include <QSettings>
#include <cmath>
#include <unistd.h>
#include <fcntl.h>
#include <QtWidgets/QLabel>
#include <QtWidgets/QMenuBar>
#include <QtWidgets/QMenu>
#include <QtWidgets/QScrollArea>
#include <QtGui/QAction>
#include <QtWidgets/QSlider>
#include <QtWidgets/QListWidget>
#include <QtWidgets/QTabWidget>
#include <QtWidgets/QGroupBox>
#include <QtWidgets/QSpinBox>
#include <QtWidgets/QInputDialog>
#include <QtWidgets/QFileDialog>
#include <QtWidgets/QMessageBox>

class StateManager {
public:
    explicit StateManager(const QString& dataFolder) 
        : dataFolder(dataFolder) {
        stateFile = dataFolder + "/.app_state.json";
        lockFile = dataFolder + "/.app_state.lock";
        dbFile = dataFolder + "/.timetrack.db";
    }
    
    bool acquireLock(int timeoutSecs = 5) {
        lockFd = open(lockFile.toLocal8Bit().constData(), O_WRONLY | O_CREAT, 0644);
        if (lockFd == -1) return false;
        
        struct flock fl;
        fl.l_type = F_WRLCK;
        fl.l_whence = SEEK_SET;
        fl.l_start = 0;
        fl.l_len = 0;
        
        int attempts = timeoutSecs * 10;
        for (int i = 0; i < attempts; i++) {
            if (fcntl(lockFd, F_SETLK, &fl) == 0) {
                return true;
            }
            usleep(100000); // 0.1 seconds
        }
        
        ::close(lockFd);
        lockFd = -1;
        return false;
    }
    
    void releaseLock() {
        if (lockFd != -1) {
            ::close(lockFd);
            lockFd = -1;
        }
    }
    
    QJsonObject getCurrentState() {
        QSqlDatabase db = QSqlDatabase::database();
        if (!db.isOpen()) {
            db = QSqlDatabase::addDatabase("QSQLITE", "state_connection");
            db.setDatabaseName(dbFile);
            if (!db.open()) {
                return QJsonObject();
            }
        }
        
        QSqlQuery query(db);
        query.exec("SELECT project, activity, start_time FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1");
        
        QJsonObject state;
        if (query.next()) {
            state["is_tracking"] = true;
            state["project"] = query.value(0).toString();
            state["activity"] = query.value(1).toString();
            state["start_time"] = query.value(2).toLongLong();
        } else {
            state["is_tracking"] = false;
            state["project"] = QJsonValue();
            state["activity"] = QJsonValue();
            state["start_time"] = QJsonValue();
        }
        state["last_updated"] = QDateTime::currentSecsSinceEpoch();
        
        return state;
    }
    
    bool saveState(const QJsonObject& state) {
        if (!acquireLock()) return false;
        
        QJsonObject stateWithTime = state;
        stateWithTime["last_updated"] = QDateTime::currentSecsSinceEpoch();
        
        QFile file(stateFile);
        bool success = false;
        if (file.open(QIODevice::WriteOnly)) {
            QJsonDocument doc(stateWithTime);
            file.write(doc.toJson());
            success = true;
        }
        
        releaseLock();
        return success;
    }
    
    QJsonObject loadState() {
        if (!acquireLock()) return QJsonObject();
        
        QJsonObject state;
        QFile file(stateFile);
        if (file.exists() && file.open(QIODevice::ReadOnly)) {
            QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
            state = doc.object();
        }
        
        releaseLock();
        return state;
    }
    
    QJsonObject syncWithDatabase() {
        QJsonObject dbState = getCurrentState();
        if (!dbState.isEmpty()) {
            saveState(dbState);
        }
        return dbState;
    }

private:
    QString dataFolder;
    QString stateFile;
    QString lockFile;
    QString dbFile;
    int lockFd = -1;
};

class ProjectDialog : public QDialog {
public:
    explicit ProjectDialog(const QStringList& projects, QWidget* parent = nullptr)
        : QDialog(parent) {
        setWindowTitle("Select Project");
        setModal(true);
        
        auto* layout = new QVBoxLayout(this);
        
        combo = new QComboBox(this);
        combo->addItem("New Project");
        combo->addItems(projects);
        combo->setEditable(true);
        layout->addWidget(combo);
        
        newProjectInput = new QLineEdit(this);
        newProjectInput->setPlaceholderText("Enter new project name");
        newProjectInput->setVisible(false);
        layout->addWidget(newProjectInput);
        
        connect(combo, QOverload<const QString&>::of(&QComboBox::currentTextChanged),
                [this](const QString& text) {
                    newProjectInput->setVisible(text == "New Project");
                });
        
        auto* buttons = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel, this);
        connect(buttons, &QDialogButtonBox::accepted, this, &ProjectDialog::validateAndAccept);
        connect(buttons, &QDialogButtonBox::rejected, this, &QDialog::reject);
        layout->addWidget(buttons);
    }
    
    QString getSelectedProject() const {
        if (combo->currentText() == "New Project") {
            return newProjectInput->text().trimmed();
        }
        return combo->currentText();
    }

private slots:
    void validateAndAccept() {
        if (combo->currentText() == "New Project") {
            QString projectName = newProjectInput->text().trimmed();
            if (projectName.isEmpty()) {
                QMessageBox::warning(this, "Invalid Project Name", 
                    "Please enter a name for the new project.");
                newProjectInput->setFocus();
                return;
            }
        }
        accept();
    }

private:
    QComboBox* combo;
    QLineEdit* newProjectInput;
};

class ActivityDialog : public QDialog {
public:
    explicit ActivityDialog(QWidget* parent = nullptr) : QDialog(parent) {
        setWindowTitle("Select Activity Type");
        setModal(true);
        
        auto* layout = new QVBoxLayout(this);
        
        QStringList baseActivities = {
            "Legal research", "Investigation", "Discovery Review",
            "File Review", "Client Communication"
        };
        
        auto customActivities = loadCustomActivities();
        QStringList allActivities = baseActivities + customActivities + QStringList{"Other"};
        
        combo = new QComboBox(this);
        combo->addItems(allActivities);
        combo->setEditable(false);
        layout->addWidget(combo);
        
        customInput = new QLineEdit(this);
        customInput->setPlaceholderText("Enter custom activity type");
        customInput->setVisible(false);
        layout->addWidget(customInput);
        
        connect(combo, QOverload<const QString&>::of(&QComboBox::currentTextChanged),
                [this](const QString& text) {
                    customInput->setVisible(text == "Other");
                    if (text == "Other") {
                        customInput->setFocus();
                    }
                });
        
        auto* buttons = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel, this);
        connect(buttons, &QDialogButtonBox::accepted, this, &QDialog::accept);
        connect(buttons, &QDialogButtonBox::rejected, this, &QDialog::reject);
        layout->addWidget(buttons);
    }
    
    QString getActivity() {
        QString selected = combo->currentText();
        if (selected == "Other") {
            QString customActivity = customInput->text().trimmed();
            if (!customActivity.isEmpty()) {
                saveCustomActivity(customActivity);
                return customActivity;
            }
            return "";
        }
        return selected;
    }

private:
    QStringList loadCustomActivities() {
        QStringList activities;
        QSqlDatabase db = QSqlDatabase::database();
        if (db.isValid()) {
            QSqlQuery query("SELECT name FROM activities WHERE is_custom = 1 ORDER BY name");
            while (query.next()) {
                activities.append(query.value(0).toString());
            }
        }
        return activities;
    }
    
    void saveCustomActivity(const QString& activity) {
        QSqlDatabase db = QSqlDatabase::database();
        if (db.isValid() && !activity.isEmpty()) {
            QSqlQuery query;
            query.prepare("INSERT OR IGNORE INTO activities (name, is_custom) VALUES (?, 1)");
            query.addBindValue(activity);
            query.exec();
        }
    }

    QComboBox* combo;
    QLineEdit* customInput;
};

class TrackingMenuDialog : public QDialog {
public:
    explicit TrackingMenuDialog(QWidget* parent = nullptr) : QDialog(parent) {
        setWindowTitle("Tracking Options");
        setModal(true);
        
        auto* layout = new QVBoxLayout(this);
        
        auto* changeActivityBtn = new QPushButton("Change Activity", this);
        auto* changeProjectBtn = new QPushButton("Change Project", this);
        auto* stopTrackingBtn = new QPushButton("Stop Tracking", this);
        auto* cancelBtn = new QPushButton("Cancel", this);
        
        connect(changeActivityBtn, &QPushButton::clicked, [this]() { selectAction("change_activity"); });
        connect(changeProjectBtn, &QPushButton::clicked, [this]() { selectAction("change_project"); });
        connect(stopTrackingBtn, &QPushButton::clicked, [this]() { selectAction("stop_tracking"); });
        connect(cancelBtn, &QPushButton::clicked, this, &QDialog::reject);
        
        layout->addWidget(changeActivityBtn);
        layout->addWidget(changeProjectBtn);
        layout->addWidget(stopTrackingBtn);
        layout->addWidget(cancelBtn);
    }
    
    QString getSelectedAction() const { return selectedAction; }

private:
    void selectAction(const QString& action) {
        selectedAction = action;
        accept();
    }
    
    QString selectedAction;
};

class FloatingButton : public QPushButton {
public:
    explicit FloatingButton(QWidget* parent = nullptr) : QPushButton(parent) {
        setFixedSize(60, 60);  // Start with smaller size for "not tracking"
        setAttribute(Qt::WA_TranslucentBackground);
        
        isTracking = false;
        lastKnownSessionStart = 0;
        
        // Setup data folder and state manager
        dataFolder = getDataFolder();
        stateManager = new StateManager(dataFolder);
        
        setupDatabase();
        setupSound();
        
        // Setup timers first
        chimeTimer = new QTimer(this);
        connect(chimeTimer, &QTimer::timeout, [this]() { checkChimeTime(); });
        chimeTimer->setInterval(1000);
        
        // State sync timer - check for external changes every 2 seconds
        syncTimer = new QTimer(this);
        connect(syncTimer, &QTimer::timeout, [this]() { syncState(); });
        syncTimer->start(2000);
        
        // Display update timer - update time display every second when tracking
        displayTimer = new QTimer(this);
        connect(displayTimer, &QTimer::timeout, [this]() { updateAppearance(); });
        displayTimer->start(1000);
        
        // Load initial state from database/state file after timers are set up
        syncState();
        updateAppearance();
    }

protected:
    void mousePressEvent(QMouseEvent* event) override {
        QRect buttonRect = rect();
        QPoint clickPos = event->pos();
        
        QPoint buttonCenter = buttonRect.center();
        double clickDistance = std::sqrt(std::pow(clickPos.x() - buttonCenter.x(), 2) + 
                                       std::pow(clickPos.y() - buttonCenter.y(), 2));
        
        double innerRadius = (buttonRect.width() / 2.0) - 4;
        
        if (clickDistance <= innerRadius) {
            event->accept();
        } else {
            event->ignore();
        }
    }
    
    void mouseMoveEvent(QMouseEvent* event) override {
        event->ignore();
    }
    
    void mouseReleaseEvent(QMouseEvent* event) override {
        QRect buttonRect = rect();
        QPoint clickPos = event->pos();
        
        QPoint buttonCenter = buttonRect.center();
        double clickDistance = std::sqrt(std::pow(clickPos.x() - buttonCenter.x(), 2) + 
                                       std::pow(clickPos.y() - buttonCenter.y(), 2));
        
        double innerRadius = (buttonRect.width() / 2.0) - 4;
        
        if (clickDistance <= innerRadius) {
            if (!isTracking) {
                auto* dialog = new ProjectDialog(getProjects(), this);
                if (dialog->exec() == QDialog::Accepted) {
                    QString project = dialog->getSelectedProject();
                    if (!project.isEmpty()) {
                        auto* activityDialog = new ActivityDialog(this);
                        if (activityDialog->exec() == QDialog::Accepted) {
                            QString activity = activityDialog->getActivity();
                            startTracking(project, activity);
                        }
                    }
                }
            } else {
                showTrackingMenu();
            }
        }
    }

private:
    QString getDataFolder() {
        static QString cachedDataFolder;
        static bool hasPrompted = false;
        
        // Return cached value if already determined
        if (!cachedDataFolder.isEmpty()) {
            return cachedDataFolder;
        }
        
        QString configFile = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/.config/timetracker/config";
        QFileInfo configInfo(configFile);
        
        QString dataFolder;
        if (configInfo.exists()) {
            QFile file(configFile);
            if (file.open(QIODevice::ReadOnly)) {
                dataFolder = file.readAll().trimmed();
            }
        } else if (!hasPrompted) {
            // First run - prompt user to select data folder (only once)
            hasPrompted = true;
            
            QMessageBox msgBox;
            msgBox.setWindowTitle("IACLS Time Tracker - First Run Setup");
            msgBox.setText("Welcome to IACLS Time Tracker!\n\nPlease choose a folder where your time tracking data will be saved.\n\nThis folder will contain:\n• Time tracking database\n• CSV exports\n• Configuration files");
            msgBox.setStandardButtons(QMessageBox::Ok);
            msgBox.exec();
            
            QString defaultLocation = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/TimeTracker";
            dataFolder = QFileDialog::getExistingDirectory(
                nullptr,
                "Select Data Folder for Time Tracker",
                QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation),
                QFileDialog::ShowDirsOnly | QFileDialog::DontResolveSymlinks
            );
            
            // If user cancelled, use default location
            if (dataFolder.isEmpty()) {
                dataFolder = defaultLocation;
                QMessageBox::information(
                    nullptr,
                    "Default Location Selected",
                    QString("Using default location:\n%1").arg(dataFolder)
                );
            } else {
                // Use selected directory directly
                QMessageBox::information(
                    nullptr,
                    "Data Folder Selected",
                    QString("Time tracking data will be saved to:\n%1").arg(dataFolder)
                );
            }
            
            // Create config directory and save choice
            QDir().mkpath(configInfo.absolutePath());
            QFile file(configFile);
            if (file.open(QIODevice::WriteOnly)) {
                file.write(dataFolder.toUtf8());
            }
        } else {
            // Fallback to default if prompting was skipped
            dataFolder = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/TimeTracker";
        }
        
        // Ensure data directory exists
        QDir().mkpath(dataFolder);
        
        // Cache the result
        cachedDataFolder = dataFolder;
        return dataFolder;
    }
    
    void syncState() {
        try {
            // Get current state from database
            QJsonObject dbState = stateManager->getCurrentState();
            if (dbState.isEmpty()) return;
            
            // Check if state has changed
            bool stateChanged = false;
            bool dbIsTracking = dbState["is_tracking"].toBool();
            QString dbProject = dbState["project"].toString();
            
            if (dbIsTracking != isTracking) {
                stateChanged = true;
            } else if (dbIsTracking && dbProject != currentProject) {
                stateChanged = true;
            }
            
            if (stateChanged) {
                // Check if we're starting tracking from external source
                bool wasTracking = isTracking;
                
                // Update our internal state
                isTracking = dbIsTracking;
                currentProject = dbProject;
                currentActivity = dbState["activity"].toString();
                if (!dbState["start_time"].isNull()) {
                    startTime = QDateTime::fromSecsSinceEpoch(dbState["start_time"].toInt());
                } else {
                    startTime = QDateTime();
                }
                
                // Update chime timer and play chimes for state changes
                if (isTracking && !wasTracking) {
                    // Check if this is a new session (different start time) or just app startup
                    qint64 sessionStartTime = dbState["start_time"].toInt();
                    if (lastKnownSessionStart != sessionStartTime) {
                        // This is a new tracking session - play chime and start timer
                        playChime();
                        lastKnownSessionStart = sessionStartTime;
                    }
                    // Always ensure timer is running when tracking
                    chimeTimer->start();
                } else if (!isTracking && wasTracking) {
                    // Stopped tracking externally - play chime and stop timer
                    playChime();
                    chimeTimer->stop();
                    lastKnownSessionStart = 0;
                } else if (isTracking && !chimeTimer->isActive()) {
                    // Already tracking but timer not active - start it (no chime)
                    chimeTimer->start();
                } else if (!isTracking && chimeTimer->isActive()) {
                    // Not tracking but timer still active - stop it
                    chimeTimer->stop();
                }
                
                // Update appearance
                updateAppearance();
            }
            
            // Save current state to state file
            stateManager->saveState(dbState);
            
        } catch (...) {
            // Handle any errors silently
        }
    }
    
    void checkChimeTime() {
        if (!isTracking || startTime.isNull()) return;
        
        qint64 elapsed = startTime.secsTo(QDateTime::currentDateTime());
        if (elapsed > 0 && elapsed % 360 == 0) {
            playChime();
        }
    }
    
    void updateAppearance() {
        QString color = isTracking ? "green" : "red";
        QString text;
        int buttonSize;
        int borderRadius;
        
        // Set size based on tracking state
        if (isTracking) {
            buttonSize = 120;  // Large size when tracking
            borderRadius = 60;
        } else {
            buttonSize = 60;   // Small size when not tracking
            borderRadius = 30;
        }
        
        // Update button size
        setFixedSize(buttonSize, buttonSize);
        
        if (isTracking && !currentProject.isEmpty()) {
            if (!startTime.isNull()) {
                qint64 elapsed = startTime.secsTo(QDateTime::currentDateTime());
                int hours = elapsed / 3600;
                int minutes = (elapsed % 3600) / 60;
                
                QString timeStr;
                if (hours > 0) {
                    timeStr = QString("%1:%2").arg(hours).arg(minutes, 2, 10, QChar('0'));
                } else {
                    timeStr = QString("%1m").arg(minutes);
                }
                
                QString projectName = currentProject.length() > 13 ? 
                                    currentProject.left(13) : currentProject;
                text = QString("%1\n%2").arg(projectName, timeStr);
            } else {
                QString projectName = currentProject.length() > 13 ? 
                                    currentProject.left(13) : currentProject;
                text = projectName;
            }
        } else {
            text = "Not\nTracking";
        }
        
        setStyleSheet(QString(
            "QPushButton {"
            "  background-color: %1;"
            "  border-radius: %2px;"
            "  border: 4px solid white;"
            "  color: white;"
            "  font-weight: bold;"
            "  text-align: center;"
            "}"
        ).arg(color).arg(borderRadius));
        
        setText(text);
    }

    void setupDatabase() {
        QString dbPath = dataFolder + "/.timetrack.db";
        csvPath = dataFolder + "/time_entries.csv";
        
        db = QSqlDatabase::addDatabase("QSQLITE");
        db.setDatabaseName(dbPath);
        
        if (!db.open()) {
            qWarning() << "Failed to open database:" << db.lastError().text();
            return;
        }
        
        QSqlQuery query;
        // Create time_entries table
        query.exec("CREATE TABLE IF NOT EXISTS time_entries ("
                  "id INTEGER PRIMARY KEY,"
                  "project TEXT,"
                  "activity TEXT,"
                  "start_time INTEGER,"
                  "end_time INTEGER"
                  ")");
        
        // Create projects table
        query.exec("CREATE TABLE IF NOT EXISTS projects ("
                  "id INTEGER PRIMARY KEY,"
                  "name TEXT UNIQUE,"
                  "created_at INTEGER DEFAULT (strftime('%s','now'))"
                  ")");
        
        // Create activities table  
        query.exec("CREATE TABLE IF NOT EXISTS activities ("
                  "id INTEGER PRIMARY KEY,"
                  "name TEXT UNIQUE,"
                  "is_custom INTEGER DEFAULT 1,"
                  "created_at INTEGER DEFAULT (strftime('%s','now'))"
                  ")");
        
        // Insert default activities if they don't exist
        QStringList defaultActivities = {
            "Legal research", "Investigation", "Discovery Review",
            "File Review", "Client Communication"
        };
        
        for (const QString& activity : defaultActivities) {
            query.prepare("INSERT OR IGNORE INTO activities (name, is_custom) VALUES (?, 0)");
            query.addBindValue(activity);
            query.exec();
        }
        
        // Add activity column to time_entries if it doesn't exist (for existing databases)
        query.exec("ALTER TABLE time_entries ADD COLUMN activity TEXT");
    }
    
    void setupSound() {
        player = new QMediaPlayer(this);
        audioOutput = new QAudioOutput(this);
        player->setAudioOutput(audioOutput);
        
        // Load volume setting from preferences
        int volumePercent = loadChimeVolume();
        audioOutput->setVolume(volumePercent / 100.0);  // Convert percentage to 0.0-1.0 range
        
        // Try to find the sound file in the project directory and data folder
        QStringList possiblePaths = {
            QFileInfo(QCoreApplication::applicationFilePath()).absolutePath() + "/bells-2-31725.mp3",
            dataFolder + "/bells-2-31725.mp3"
        };
        
        for (const QString& path : possiblePaths) {
            if (QFileInfo::exists(path)) {
                player->setSource(QUrl::fromLocalFile(path));
                break;
            }
        }
    }
    
    void playChime() {
        try {
            // Use a lock file to prevent multiple interfaces from chiming simultaneously
            QString lockFile = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/.config/timetracker/chime.lock";
            QFileInfo lockInfo(lockFile);
            QDir().mkpath(lockInfo.absolutePath());
            
            // Try to acquire lock (non-blocking)
            int lockFd = open(lockFile.toLocal8Bit().constData(), O_WRONLY | O_CREAT, 0644);
            if (lockFd != -1) {
                struct flock fl;
                fl.l_type = F_WRLCK;
                fl.l_whence = SEEK_SET;
                fl.l_start = 0;
                fl.l_len = 0;
                
                if (fcntl(lockFd, F_SETLK, &fl) == 0) {
                    // Got the lock - play chime
                    if (player) {
                        player->setPosition(0);
                        player->play();
                    }
                    
                    // Keep lock for 2 seconds to prevent immediate double chiming
                    sleep(2);
                }
                
                ::close(lockFd);
            }
        } catch (...) {
            // If locking fails, just play the chime anyway
            if (player) {
                player->setPosition(0);
                player->play();
            }
        }
    }
    
    QStringList getProjects() {
        QStringList projects;
        
        // Get projects from the projects table first
        QSqlQuery query("SELECT name FROM projects ORDER BY name");
        while (query.next()) {
            projects << query.value(0).toString();
        }
        
        // Also get any projects from time_entries that aren't in projects table
        query.exec("SELECT DISTINCT project FROM time_entries WHERE project NOT LIKE '[HIDDEN]%' AND project NOT IN (SELECT name FROM projects) ORDER BY project");
        while (query.next()) {
            QString project = query.value(0).toString();
            if (!project.isEmpty()) {
                projects << project;
                // Add to projects table for future reference
                QSqlQuery insertQuery;
                insertQuery.prepare("INSERT OR IGNORE INTO projects (name) VALUES (?)");
                insertQuery.addBindValue(project);
                insertQuery.exec();
            }
        }
        
        projects.removeDuplicates();
        return projects;
    }
    
    void startTracking(const QString& project, const QString& activity) {
        try {
            currentProject = project;
            currentActivity = activity;
            isTracking = true;
            startTime = QDateTime::currentDateTime();
            
            // Add project to projects table if it doesn't exist
            QSqlQuery query;
            query.prepare("INSERT OR IGNORE INTO projects (name) VALUES (?)");
            query.addBindValue(project);
            query.exec();
            
            // Add activity to activities table if it doesn't exist (as custom)
            if (activity != "Other") {
                QStringList defaultActivities = {
                    "Legal research", "Investigation", "Discovery Review",
                    "File Review", "Client Communication"
                };
                
                if (!defaultActivities.contains(activity)) {
                    query.prepare("INSERT OR IGNORE INTO activities (name, is_custom) VALUES (?, 1)");
                    query.addBindValue(activity);
                    query.exec();
                }
            }
            
            // Insert into time_entries
            query.prepare("INSERT INTO time_entries (project, activity, start_time) VALUES (?, ?, ?)");
            query.addBindValue(project);
            query.addBindValue(activity);
            query.addBindValue(startTime.toSecsSinceEpoch());
            query.exec();
            
            // Update state file
            QJsonObject state;
            state["is_tracking"] = true;
            state["project"] = project;
            state["activity"] = activity;
            state["start_time"] = startTime.toSecsSinceEpoch();
            stateManager->saveState(state);
            
            // Play initial chime and start 6-minute chime timer
            playChime();
            chimeTimer->start();  // Will chime every 6 minutes
            lastKnownSessionStart = startTime.toSecsSinceEpoch();
            
            updateAppearance();
            
        } catch (...) {
            // Handle errors silently
        }
    }
    
    void stopTracking() {
        try {
            if (!isTracking) return;
                
            QDateTime endTime = QDateTime::currentDateTime();
            
            // Update database
            QSqlQuery query;
            query.prepare("UPDATE time_entries SET end_time = ? WHERE end_time IS NULL");
            query.addBindValue(endTime.toSecsSinceEpoch());
            query.exec();
            
            // Export to CSV
            exportToCsv();
            
            // Update state
            isTracking = false;
            currentProject.clear();
            currentActivity.clear();
            startTime = QDateTime();
            lastKnownSessionStart = 0;
            
            // Update state file
            QJsonObject state;
            state["is_tracking"] = false;
            state["project"] = QJsonValue();
            state["activity"] = QJsonValue();
            state["start_time"] = QJsonValue();
            stateManager->saveState(state);
            
            // Play final chime and stop chime timer
            playChime();
            chimeTimer->stop();
            
            updateAppearance();
            
        } catch (...) {
            // Handle errors silently
        }
    }
    
    void changeActivity() {
        auto* activityDialog = new ActivityDialog(this);
        if (activityDialog->exec() == QDialog::Accepted) {
            QString newActivity = activityDialog->getActivity();
            if (!newActivity.isEmpty()) {
                // Update the current activity in the database
                QSqlQuery query;
                query.prepare("UPDATE time_entries SET activity = ? WHERE end_time IS NULL");
                query.addBindValue(newActivity);
                query.exec();
                
                // Update internal state
                currentActivity = newActivity;
                
                // Update state file
                QJsonObject state;
                state["is_tracking"] = true;
                state["project"] = currentProject;
                state["activity"] = newActivity;
                state["start_time"] = startTime.toSecsSinceEpoch();
                stateManager->saveState(state);
                
                // Regenerate CSV
                exportToCsv();
                
                updateAppearance();
            }
        }
    }
    
    void changeProject() {
        auto* dialog = new ProjectDialog(getProjects(), this);
        if (dialog->exec() == QDialog::Accepted) {
            QString newProject = dialog->getSelectedProject();
            if (!newProject.isEmpty()) {
                // Also prompt for activity when changing project
                auto* activityDialog = new ActivityDialog(this);
                if (activityDialog->exec() == QDialog::Accepted) {
                    QString newActivity = activityDialog->getActivity();
                    if (!newActivity.isEmpty()) {
                        // End current session and start new one (restart timer)
                        QDateTime endTime = QDateTime::currentDateTime();
                        
                        // Update current session with end time
                        QSqlQuery query;
                        query.prepare("UPDATE time_entries SET end_time = ? WHERE end_time IS NULL");
                        query.addBindValue(endTime.toSecsSinceEpoch());
                        query.exec();
                        
                        // Start new session with new project and activity
                        startTime = QDateTime::currentDateTime();
                        currentProject = newProject;
                        currentActivity = newActivity;
                        
                        // Insert new entry
                        query.prepare("INSERT INTO time_entries (project, activity, start_time) VALUES (?, ?, ?)");
                        query.addBindValue(newProject);
                        query.addBindValue(newActivity);
                        query.addBindValue(startTime.toSecsSinceEpoch());
                        query.exec();
                        
                        // Update state file with new start time
                        QJsonObject state;
                        state["is_tracking"] = true;
                        state["project"] = newProject;
                        state["activity"] = newActivity;
                        state["start_time"] = startTime.toSecsSinceEpoch();
                        stateManager->saveState(state);
                        
                        // Reset chime timer for new session
                        lastKnownSessionStart = startTime.toSecsSinceEpoch();
                        
                        // Regenerate CSV
                        exportToCsv();
                        
                        updateAppearance();
                    }
                }
            }
        }
    }
    
    void showTrackingMenu() {
        auto* menu = new TrackingMenuDialog(this);
        if (menu->exec() == QDialog::Accepted) {
            QString action = menu->getSelectedAction();
            if (action == "change_activity") {
                changeActivity();
            } else if (action == "change_project") {
                changeProject();
            } else if (action == "stop_tracking") {
                stopTracking();
            }
        }
    }
    
    void exportToCsv() {
        QFile file(csvPath);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) return;
        
        QTextStream out(&file);
        out << "ID,Project,Activity,Start Time,End Time,Duration,Hours\n";
        
        QSqlQuery query("SELECT id, project, activity, start_time, end_time FROM time_entries");
        while (query.next()) {
            int id = query.value(0).toInt();
            QString project = query.value(1).toString();
            QString activity = query.value(2).toString();
            qint64 startTimestamp = query.value(3).toLongLong();
            qint64 endTimestamp = query.value(4).toLongLong();
            
            QDateTime startDt = QDateTime::fromSecsSinceEpoch(startTimestamp);
            QDateTime endDt = endTimestamp > 0 ? QDateTime::fromSecsSinceEpoch(endTimestamp) : QDateTime();
            
            QString startStr = startDt.toString("yyyy-MM-dd hh:mm:ss");
            QString endStr = endDt.isValid() ? endDt.toString("yyyy-MM-dd hh:mm:ss") : "";
            
            QString durationStr;
            double decimalHours = 0.0;
            
            if (endDt.isValid()) {
                qint64 duration = startDt.secsTo(endDt);
                int hours = duration / 3600;
                int minutes = (duration % 3600) / 60;
                int seconds = duration % 60;
                durationStr = QString("%1:%2:%3").arg(hours, 2, 10, QChar('0'))
                                                 .arg(minutes, 2, 10, QChar('0'))
                                                 .arg(seconds, 2, 10, QChar('0'));
                decimalHours = std::ceil((duration / 3600.0) * 10) / 10.0;
            }
            
            // Fixed CSV output - properly format the decimal hours
            out << QString("%1,%2,%3,%4,%5,%6,%7\n")
                   .arg(id)
                   .arg(project)
                   .arg(activity)
                   .arg(startStr)
                   .arg(endStr)
                   .arg(durationStr)
                   .arg(decimalHours, 0, 'f', 1);
        }
    }
    
    int loadChimeVolume() {
        QString configFile = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/.config/timetracker/volume";
        QFile file(configFile);
        if (file.exists() && file.open(QIODevice::ReadOnly)) {
            return file.readAll().trimmed().toInt();
        }
        return 100; // Default volume
    }

public:
    void updateChimeVolume() {
        if (audioOutput) {
            int volumePercent = loadChimeVolume();
            audioOutput->setVolume(volumePercent / 100.0);
        }
    }
    
    QString getCurrentDataFolder() const {
        return dataFolder;
    }

private:
    
    bool isTracking;
    QString currentProject;
    QString currentActivity;
    QDateTime startTime;
    QString csvPath;
    QString dataFolder;
    qint64 lastKnownSessionStart;
    
    QSqlDatabase db;
    QMediaPlayer* player;
    QAudioOutput* audioOutput;
    QTimer* chimeTimer;
    QTimer* syncTimer;
    QTimer* displayTimer;
    StateManager* stateManager;
};

class DraggableHandle : public QWidget {
public:
    explicit DraggableHandle(QWidget* parent = nullptr) : QWidget(parent) {
        setFixedSize(140, 140);
        setWindowFlags(Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint);
        setAttribute(Qt::WA_TranslucentBackground);
        
        auto* layout = new QHBoxLayout(this);
        layout->setContentsMargins(10, 10, 10, 10);
        
        button = new FloatingButton(this);
        layout->addWidget(button);
        
        setDefaultPosition();
        loadPosition();
    }
    
    FloatingButton* getFloatingButton() { return button; }

protected:
    void paintEvent(QPaintEvent*) override {
        QPainter painter(this);
        painter.setRenderHint(QPainter::Antialiasing);
        
        QPen pen(QColor(0, 0, 0, 255));
        pen.setWidth(4);
        painter.setPen(pen);
        painter.setBrush(QColor(0, 0, 0, 0));
        
        QRect buttonRect = button->geometry();
        QRect borderRect = buttonRect.adjusted(-2, -2, 2, 2);
        painter.drawEllipse(borderRect);
    }
    
    void mousePressEvent(QMouseEvent* event) override {
        QRect buttonRect = button->geometry();
        QPoint clickPos = event->pos();
        
        QPoint buttonCenter = buttonRect.center();
        double clickDistance = std::sqrt(std::pow(clickPos.x() - buttonCenter.x(), 2) + 
                                       std::pow(clickPos.y() - buttonCenter.y(), 2));
        
        double innerRadius = (buttonRect.width() / 2.0) - 4;
        
        if (clickDistance <= innerRadius) {
            oldPos = QPoint();
        } else {
            oldPos = event->globalPosition().toPoint();
        }
    }
    
    void mouseMoveEvent(QMouseEvent* event) override {
        if (!oldPos.isNull()) {
            QPoint delta = event->globalPosition().toPoint() - oldPos;
            move(x() + delta.x(), y() + delta.y());
            oldPos = event->globalPosition().toPoint();
        }
    }
    
    void mouseReleaseEvent(QMouseEvent*) override {
        if (!oldPos.isNull()) {
            savePosition();
        }
        oldPos = QPoint();
    }

private:
    void setDefaultPosition() {
        QScreen* screen = QGuiApplication::primaryScreen();
        QRect screenGeometry = screen->availableGeometry();
        
        int margin = 36; // Half inch
        int x = screenGeometry.width() - width() - margin;
        int y = margin;
        
        move(x, y);
    }
    
    void savePosition() {
        try {
            QString configFile = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/.config/timetracker/position";
            QFileInfo configInfo(configFile);
            QDir().mkpath(configInfo.absolutePath());
            
            QFile file(configFile);
            if (file.open(QIODevice::WriteOnly)) {
                QPoint pos = this->pos();
                file.write(QString("%1,%2").arg(pos.x()).arg(pos.y()).toUtf8());
            }
        } catch (...) {
            // Handle errors silently
        }
    }
    
    void loadPosition() {
        try {
            QString configFile = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/.config/timetracker/position";
            QFile file(configFile);
            if (file.exists() && file.open(QIODevice::ReadOnly)) {
                QString content = file.readAll().trimmed();
                QStringList coords = content.split(',');
                if (coords.size() == 2) {
                    int x = coords[0].toInt();
                    int y = coords[1].toInt();
                    move(x, y);
                }
            }
        } catch (...) {
            // Keep default position if loading fails
        }
    }
    
    FloatingButton* button;
    QPoint oldPos;
};

class AboutDialog : public QDialog {
public:
    explicit AboutDialog(QWidget* parent = nullptr) : QDialog(parent) {
        setWindowTitle("About IACLS Time Tracker");
        setModal(true);
        setFixedSize(400, 250);
        auto* layout = new QVBoxLayout(this);
        auto* label = new QLabel(
            "<h2>IACLS Time Tracker</h2>"
            "<p>This app helps you track your time for legal and professional work."
            "<br>If you find this app useful, please consider contributing to the Institute for Advanced Criminal Law Studies at <a href=\"https://iacls.org/donate\">iacls.org/donate</a>.</p>",
            this);
        label->setOpenExternalLinks(true);
        label->setWordWrap(true);
        layout->addWidget(label);
        auto* ok = new QPushButton("OK", this);
        connect(ok, &QPushButton::clicked, this, &QDialog::accept);
        layout->addWidget(ok, 0, Qt::AlignCenter);
    }
};

class PreferencesDialog : public QDialog {
public:
    explicit PreferencesDialog(FloatingButton* floatingButton, QWidget* parent = nullptr) 
        : QDialog(parent), floatingButton(floatingButton) {
        setWindowTitle("Preferences");
        setModal(true);
        setFixedSize(500, 400);
        
        auto* layout = new QVBoxLayout(this);
        auto* tabs = new QTabWidget(this);
        
        // Audio tab
        auto* audioTab = new QWidget();
        auto* audioLayout = new QVBoxLayout(audioTab);
        
        auto* volumeGroup = new QGroupBox("Chime Volume", audioTab);
        auto* volumeLayout = new QVBoxLayout(volumeGroup);
        
        volumeSlider = new QSlider(Qt::Horizontal, volumeGroup);
        volumeSlider->setRange(0, 100);
        volumeSlider->setValue(loadChimeVolume());
        
        auto* volumeLabel = new QLabel(QString("Volume: %1%").arg(volumeSlider->value()), volumeGroup);
        connect(volumeSlider, &QSlider::valueChanged, [volumeLabel](int value) {
            volumeLabel->setText(QString("Volume: %1%").arg(value));
        });
        
        volumeLayout->addWidget(volumeLabel);
        volumeLayout->addWidget(volumeSlider);
        audioLayout->addWidget(volumeGroup);
        audioLayout->addStretch();
        
        tabs->addTab(audioTab, "Audio");
        
        // Projects tab
        auto* projectsTab = new QWidget();
        auto* projectsLayout = new QVBoxLayout(projectsTab);
        
        auto* projectsGroup = new QGroupBox("Projects", projectsTab);
        auto* projectsGroupLayout = new QVBoxLayout(projectsGroup);
        
        projectsList = new QListWidget(projectsGroup);
        projectsList->setDragDropMode(QAbstractItemView::InternalMove);
        loadProjects();
        
        auto* projectsButtonLayout = new QHBoxLayout();
        auto* addProjectBtn = new QPushButton("Add", projectsGroup);
        auto* editProjectBtn = new QPushButton("Edit", projectsGroup);
        auto* deleteProjectBtn = new QPushButton("Delete", projectsGroup);
        
        connect(addProjectBtn, &QPushButton::clicked, this, &PreferencesDialog::addProject);
        connect(editProjectBtn, &QPushButton::clicked, this, &PreferencesDialog::editProject);
        connect(deleteProjectBtn, &QPushButton::clicked, this, &PreferencesDialog::deleteProject);
        
        projectsButtonLayout->addWidget(addProjectBtn);
        projectsButtonLayout->addWidget(editProjectBtn);
        projectsButtonLayout->addWidget(deleteProjectBtn);
        projectsButtonLayout->addStretch();
        
        projectsGroupLayout->addWidget(projectsList);
        projectsGroupLayout->addLayout(projectsButtonLayout);
        projectsLayout->addWidget(projectsGroup);
        
        tabs->addTab(projectsTab, "Projects");
        
        // Activities tab
        auto* activitiesTab = new QWidget();
        auto* activitiesLayout = new QVBoxLayout(activitiesTab);
        
        auto* activitiesGroup = new QGroupBox("Activities", activitiesTab);
        auto* activitiesGroupLayout = new QVBoxLayout(activitiesGroup);
        
        activitiesList = new QListWidget(activitiesGroup);
        activitiesList->setDragDropMode(QAbstractItemView::InternalMove);
        loadActivities();
        
        auto* activitiesButtonLayout = new QHBoxLayout();
        auto* addActivityBtn = new QPushButton("Add", activitiesGroup);
        auto* editActivityBtn = new QPushButton("Edit", activitiesGroup);
        auto* deleteActivityBtn = new QPushButton("Delete", activitiesGroup);
        
        connect(addActivityBtn, &QPushButton::clicked, this, &PreferencesDialog::addActivity);
        connect(editActivityBtn, &QPushButton::clicked, this, &PreferencesDialog::editActivity);
        connect(deleteActivityBtn, &QPushButton::clicked, this, &PreferencesDialog::deleteActivity);
        
        activitiesButtonLayout->addWidget(addActivityBtn);
        activitiesButtonLayout->addWidget(editActivityBtn);
        activitiesButtonLayout->addWidget(deleteActivityBtn);
        activitiesButtonLayout->addStretch();
        
        activitiesGroupLayout->addWidget(activitiesList);
        activitiesGroupLayout->addLayout(activitiesButtonLayout);
        activitiesLayout->addWidget(activitiesGroup);
        
        tabs->addTab(activitiesTab, "Activities");
        
        // Data Folder tab
        auto* dataTab = new QWidget();
        auto* dataLayout = new QVBoxLayout(dataTab);
        
        auto* dataGroup = new QGroupBox("Data Storage Location", dataTab);
        auto* dataGroupLayout = new QVBoxLayout(dataGroup);
        
        auto* currentFolderLabel = new QLabel("Current data folder:", dataGroup);
        currentFolderPath = new QLabel(floatingButton->getCurrentDataFolder(), dataGroup);
        currentFolderPath->setWordWrap(true);
        currentFolderPath->setStyleSheet("QLabel { background-color: #f0f0f0; padding: 8px; border: 1px solid #ccc; border-radius: 4px; }");
        
        auto* changeFolderBtn = new QPushButton("Change Data Folder...", dataGroup);
        connect(changeFolderBtn, &QPushButton::clicked, this, &PreferencesDialog::changeDataFolder);
        
        auto* infoLabel = new QLabel("Note: Changing the data folder will require restarting the application. Your existing data will remain in the old location.", dataGroup);
        infoLabel->setWordWrap(true);
        infoLabel->setStyleSheet("color: #666; font-size: 11px;");
        
        dataGroupLayout->addWidget(currentFolderLabel);
        dataGroupLayout->addWidget(currentFolderPath);
        dataGroupLayout->addWidget(changeFolderBtn);
        dataGroupLayout->addWidget(infoLabel);
        dataLayout->addWidget(dataGroup);
        dataLayout->addStretch();
        
        tabs->addTab(dataTab, "Data Folder");
        
        layout->addWidget(tabs);
        
        // Dialog buttons
        auto* buttonBox = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel, this);
        connect(buttonBox, &QDialogButtonBox::accepted, this, &PreferencesDialog::saveAndAccept);
        connect(buttonBox, &QDialogButtonBox::rejected, this, &QDialog::reject);
        layout->addWidget(buttonBox);
    }

private slots:
    void saveAndAccept() {
        saveChimeVolume(volumeSlider->value());
        saveProjects();
        saveActivities();
        
        // Update the floating button's volume
        if (floatingButton) {
            floatingButton->updateChimeVolume();
        }
        
        accept();
    }
    
    void addProject() {
        bool ok;
        QString text = QInputDialog::getText(this, "Add Project", "Project name:", QLineEdit::Normal, "", &ok);
        if (ok && !text.isEmpty()) {
            projectsList->addItem(text);
        }
    }
    
    void editProject() {
        auto* item = projectsList->currentItem();
        if (item) {
            bool ok;
            QString text = QInputDialog::getText(this, "Edit Project", "Project name:", QLineEdit::Normal, item->text(), &ok);
            if (ok && !text.isEmpty()) {
                item->setText(text);
            }
        }
    }
    
    void deleteProject() {
        auto* item = projectsList->currentItem();
        if (item) {
            delete projectsList->takeItem(projectsList->row(item));
        }
    }
    
    void addActivity() {
        bool ok;
        QString text = QInputDialog::getText(this, "Add Activity", "Activity name:", QLineEdit::Normal, "", &ok);
        if (ok && !text.isEmpty()) {
            activitiesList->addItem(text);
        }
    }
    
    void editActivity() {
        auto* item = activitiesList->currentItem();
        if (item) {
            bool ok;
            QString text = QInputDialog::getText(this, "Edit Activity", "Activity name:", QLineEdit::Normal, item->text(), &ok);
            if (ok && !text.isEmpty()) {
                item->setText(text);
            }
        }
    }
    
    void deleteActivity() {
        auto* item = activitiesList->currentItem();
        if (item) {
            delete activitiesList->takeItem(activitiesList->row(item));
        }
    }
    
    void changeDataFolder() {
        QString currentFolder = floatingButton->getCurrentDataFolder();
        QString parentFolder = QFileInfo(currentFolder).absolutePath();
        
        QString newFolder = QFileDialog::getExistingDirectory(
            this,
            "Select New Data Folder",
            parentFolder,
            QFileDialog::ShowDirsOnly | QFileDialog::DontResolveSymlinks
        );
        
        if (!newFolder.isEmpty() && newFolder != currentFolder) {
            // Use selected directory directly
            
            // Update the config file
            QString configFile = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/.config/timetracker/config";
            QFileInfo configInfo(configFile);
            QDir().mkpath(configInfo.absolutePath());
            
            QFile file(configFile);
            if (file.open(QIODevice::WriteOnly)) {
                file.write(newFolder.toUtf8());
                
                // Update the display
                currentFolderPath->setText(newFolder);
                
                // Show confirmation
                QMessageBox::information(
                    this,
                    "Data Folder Changed",
                    QString("Data folder has been changed to:\n%1\n\nPlease restart the application for the change to take effect.").arg(newFolder)
                );
            } else {
                QMessageBox::warning(
                    this,
                    "Error",
                    "Failed to save the new data folder location."
                );
            }
        }
    }
    
    void loadProjects() {
        // Load projects from database
        QSqlDatabase db = QSqlDatabase::database();
        if (db.isValid()) {
            // Get projects from the projects table
            QSqlQuery query("SELECT name FROM projects ORDER BY name");
            while (query.next()) {
                projectsList->addItem(query.value(0).toString());
            }
            
            // Also get any projects from time_entries that aren't in projects table
            query.exec("SELECT DISTINCT project FROM time_entries WHERE project NOT LIKE '[HIDDEN]%' AND project NOT IN (SELECT name FROM projects) ORDER BY project");
            while (query.next()) {
                QString project = query.value(0).toString();
                if (!project.isEmpty()) {
                    projectsList->addItem(project);
                    // Add to projects table for future reference
                    QSqlQuery insertQuery;
                    insertQuery.prepare("INSERT OR IGNORE INTO projects (name) VALUES (?)");
                    insertQuery.addBindValue(project);
                    insertQuery.exec();
                }
            }
        }
    }
    
    void saveProjects() {
        // Clear existing projects and re-add from the list
        QSqlDatabase db = QSqlDatabase::database();
        if (db.isValid()) {
            QSqlQuery query;
            
            // Clear all projects (they'll be re-added from the list)
            query.exec("DELETE FROM projects");
            
            // Add all projects from the list
            for (int i = 0; i < projectsList->count(); ++i) {
                QString project = projectsList->item(i)->text();
                if (!project.isEmpty()) {
                    query.prepare("INSERT INTO projects (name) VALUES (?)");
                    query.addBindValue(project);
                    query.exec();
                }
            }
        }
    }
    
    void loadActivities() {
        // Load all activities from database (default and custom)
        QSqlDatabase db = QSqlDatabase::database();
        if (db.isValid()) {
            QSqlQuery query("SELECT name FROM activities ORDER BY is_custom, name");
            while (query.next()) {
                activitiesList->addItem(query.value(0).toString());
            }
        }
        
        // Add "Other" at the end
        activitiesList->addItem("Other");
    }
    
    void saveActivities() {
        // Save all activities to database (preserving default vs custom)
        QSqlDatabase db = QSqlDatabase::database();
        if (db.isValid()) {
            QStringList defaultActivities = {
                "Legal research", "Investigation", "Discovery Review",
                "File Review", "Client Communication"
            };
            
            QSqlQuery query;
            
            // Clear custom activities only (keep defaults)
            query.exec("DELETE FROM activities WHERE is_custom = 1");
            
            // Add all activities from the list (skipping "Other" and defaults)
            for (int i = 0; i < activitiesList->count(); ++i) {
                QString activity = activitiesList->item(i)->text();
                if (!activity.isEmpty() && activity != "Other" && !defaultActivities.contains(activity)) {
                    query.prepare("INSERT OR IGNORE INTO activities (name, is_custom) VALUES (?, 1)");
                    query.addBindValue(activity);
                    query.exec();
                }
            }
        }
    }
    
    int loadChimeVolume() {
        QString configFile = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/.config/timetracker/volume";
        QFile file(configFile);
        if (file.exists() && file.open(QIODevice::ReadOnly)) {
            return file.readAll().trimmed().toInt();
        }
        return 100; // Default volume
    }
    
    void saveChimeVolume(int volume) {
        QString configFile = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/.config/timetracker/volume";
        QFileInfo configInfo(configFile);
        QDir().mkpath(configInfo.absolutePath());
        
        QFile file(configFile);
        if (file.open(QIODevice::WriteOnly)) {
            file.write(QString::number(volume).toUtf8());
        }
    }

private:
    QSlider* volumeSlider;
    QListWidget* projectsList;
    QListWidget* activitiesList;
    QLabel* currentFolderPath;
    FloatingButton* floatingButton;
};

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    app.setQuitOnLastWindowClosed(false);
    
    // Set application properties for QSettings
    app.setOrganizationName("IACLS");
    app.setApplicationName("TimeTracker");
    
    // Create menu bar and add About action
    QMenuBar* menuBar = new QMenuBar();
    QMenu* appMenu = menuBar->addMenu("TimeTracker");
    
    DraggableHandle handle;
    
    QAction* aboutAction = new QAction("About IACLS Time Tracker", appMenu);
    appMenu->addAction(aboutAction);
    QObject::connect(aboutAction, &QAction::triggered, [&]() {
        AboutDialog aboutDialog;
        aboutDialog.exec();
    });
    
    appMenu->addSeparator();
    
    QAction* preferencesAction = new QAction("Preferences...", appMenu);
    appMenu->addAction(preferencesAction);
    QObject::connect(preferencesAction, &QAction::triggered, [&handle]() {
        PreferencesDialog preferencesDialog(handle.getFloatingButton());
        preferencesDialog.exec();
    });
    handle.show();
    
    return app.exec();
} 