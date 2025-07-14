# Detailed Tracking Implementation

## Overview

The time tracker has been enhanced with detailed tracking capabilities that collect comprehensive information about user activity during time tracking sessions. This provides granular insights into how time is spent across different applications and documents.

## Features Implemented

### 1. Database Schema Extension

A new `detailed_tracking` table has been added to the SQLite database:

```sql
CREATE TABLE detailed_tracking (
    id INTEGER PRIMARY KEY,
    time_entry_id INTEGER,
    timestamp INTEGER,
    active_app TEXT,
    document_url TEXT,
    idle_seconds INTEGER DEFAULT 0,
    is_locked INTEGER DEFAULT 0,
    FOREIGN KEY (time_entry_id) REFERENCES time_entries(id)
);
```

### 2. Activity Monitoring

The system now tracks:

- **Active Application**: Which application is currently in focus
- **Document/URL**: The specific document or URL being worked on (for supported applications)
- **Idle Time**: How long the user has been inactive
- **Lock Status**: Whether the computer screen is locked

### 3. Supported Applications

The detailed tracking system recognizes and extracts document information from:

- **Safari**: Current tab URL
- **Google Chrome**: Current tab URL
- **Microsoft Word**: Active document name
- **Pages**: Active document name
- **TextEdit**: Active document name
- **Finder**: Current folder path

### 4. Data Collection Frequency

- Detailed tracking data is collected every minute during active time tracking sessions
- Data collection starts automatically when time tracking begins
- Data collection stops when time tracking ends

### 5. CSV Export Enhancement

The CSV export functionality has been enhanced to include detailed tracking data:

- Standard CSV: `time_entries.csv` (existing format)
- Detailed CSV: `time_entries_detailed.csv` (new format with detailed tracking data)

## Technical Implementation

### Core Components

1. **DetailedTracker Class**: Handles all system-level data collection
2. **Database Integration**: Seamlessly integrates with existing time tracking database
3. **Timer Management**: Uses Qt timers for periodic data collection
4. **Cross-Platform Support**: macOS-specific implementation using native APIs

### macOS System Integration

The implementation uses several macOS frameworks:

- **CoreFoundation**: For system-level data access
- **ApplicationServices**: For application and window information
- **IOKit**: For idle time and lock status detection

### Data Flow

1. User starts time tracking
2. System creates a new time entry in the database
3. Detailed tracking timer starts (1-minute intervals)
4. Each timer tick:
   - Collects current application information
   - Determines active document/URL
   - Measures idle time
   - Checks lock status
   - Stores data in detailed_tracking table
5. User stops time tracking
6. Detailed tracking timer stops
7. Data is exported to CSV files

## Usage

### Starting Time Tracking

When you start time tracking, the system automatically:
- Creates a time entry record
- Begins collecting detailed tracking data
- Starts the 30-second collection timer

### Viewing Detailed Data

Detailed tracking data is available in:
- SQLite database: `~/.timetrack.db` (detailed_tracking table)
- CSV export: `~/time_entries_detailed.csv`

### CSV Format

The detailed CSV includes these columns:
- Time Entry ID
- Project
- Activity
- Timestamp
- Active App
- Document/URL
- Idle Seconds
- Is Locked

## Privacy Considerations

The detailed tracking system:
- Only collects data during active time tracking sessions
- Stores data locally in your home directory
- Does not transmit any data externally
- Can be disabled by not starting time tracking

## Benefits

1. **Productivity Analysis**: Understand which applications you spend the most time in
2. **Context Awareness**: Know exactly what documents/URLs you were working on
3. **Idle Time Tracking**: Identify periods of inactivity
4. **Comprehensive Reporting**: Export detailed data for analysis in external tools

## Future Enhancements

Potential future improvements could include:
- Configurable collection intervals
- Additional application support
- Data visualization tools
- Automatic idle time exclusion
- Privacy filters for sensitive applications

## Compatibility

- **macOS**: Full support with native system integration
- **Windows**: Database structure compatible (requires Windows-specific implementation)
- **Linux**: Database structure compatible (requires Linux-specific implementation)

The detailed tracking implementation maintains full backward compatibility with existing time tracking functionality while adding comprehensive activity monitoring capabilities. 