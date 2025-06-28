cmake_minimum_required(VERSION 3.16)
project(TimeTracker)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Qt6
find_package(Qt6 REQUIRED COMPONENTS Core Widgets Sql Multimedia)

# Enable automatic MOC
set(CMAKE_AUTOMOC ON)

# Add executable
add_executable(TimeTracker main.cpp)

# Try to link Qt6 libraries with preference for static
target_link_libraries(TimeTracker 
    Qt6::Core 
    Qt6::Widgets 
    Qt6::Sql 
    Qt6::Multimedia
)

# Set app bundle properties
set_target_properties(TimeTracker PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_BUNDLE_NAME "TimeTracker"
    MACOSX_BUNDLE_GUI_IDENTIFIER "org.iacls.timetracker"
    MACOSX_BUNDLE_ICON_FILE "icon.icns"
)

# Copy icon to bundle
set_source_files_properties(icon.icns PROPERTIES
    MACOSX_PACKAGE_LOCATION "Resources"
)
target_sources(TimeTracker PRIVATE icon.icns)

# Copy audio file to bundle
set_source_files_properties(../assets/bells-2-31725.mp3 PROPERTIES
    MACOSX_PACKAGE_LOCATION "Resources"
)
target_sources(TimeTracker PRIVATE ../assets/bells-2-31725.mp3)

# Release optimizations for smaller binary
set(CMAKE_BUILD_TYPE Release)
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG -flto -ffunction-sections -fdata-sections")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "-flto -Wl,-dead_strip -Wl,-x") 