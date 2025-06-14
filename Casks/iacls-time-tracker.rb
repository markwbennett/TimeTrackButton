cask "iacls-time-tracker" do
  version "1.1.0"
  sha256 "406a22a73e4b5fa708e15620afbb1a6b99b0c690081395b896acf661f0f7912f"

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