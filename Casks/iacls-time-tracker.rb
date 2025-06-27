cask "iacls-time-tracker" do
  version "1.1.1"
  sha256 "a30a15dbed83145f291db6b45e48902f3a2ba92b26e0333e2c7347a5cf545ac7"

  url "https://github.com/markwbennett/TimeTrackButton/raw/f455c8e08565b2254683ed0d4caa5806f6f6e1cd/TimeTracker_CPP.app.tar.gz"
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