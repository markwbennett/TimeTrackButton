cask "iacls-time-tracker" do
  version "1.1.0"
  sha256 "a30a15dbed83145f291db6b45e48902f3a2ba92b26e0333e2c7347a5cf545ac7"

  url "https://github.com/markwbennett/TimeTrackButton/raw/ed2fb7afdd9f967733679217bc951be6b30139a4/TimeTracker_CPP.app.tar.gz"
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