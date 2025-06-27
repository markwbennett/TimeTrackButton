cask "iacls-time-tracker" do
  version "1.1.0"
  sha256 "03a88df4006c39a73590c28a04bbf14d86ea2750a8b3ede1636c189b6b5deb6b"

  url "https://github.com/markwbennett/TimeTrackButton/raw/main/TimeTracker_CPP.app.tar.gz"
  name "IACLS Time Tracker"
  desc "Time tracking application for legal and professional work"
  homepage "https://github.com/markwbennett/TimeTrackButton"

  app "TimeTracker_CPP.app", target: "IACLS Time Tracker.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/IACLS Time Tracker.app"],
                   sudo: false
  end

  zap trash: [
    "~/Documents/TimeTracker",
    "~/.config/timetracker",
  ]
end 