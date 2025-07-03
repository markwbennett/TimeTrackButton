cask "iacls-time-tracker" do
  version "1.3.6"
  sha256 :no_check

  url "https://github.com/markwbennett/TimeTrackButton/raw/main/releases/TimeTracker_CPP_Latest.app.tar.gz"
  name "IACLS Time Tracker"
  desc "Floating button time tracker for lawyers"
  homepage "https://github.com/markwbennett/TimeTrackButton"

  app "Time Tracker.app", target: "IACLS Time Tracker.app"

  zap trash: [
    "~/Documents/TimeTracker",
    "~/Library/Preferences/com.iacls.timetracker.plist",
  ]
end 