cask "iacls-time-tracker" do
  version "1.3.5"
  sha256 "4d6d87be4a99e792ccaf3a6372180bc164a1f6274f7407ff698abc21f185b561"

  url "https://github.com/markwbennett/TimeTrackButton/raw/main/releases/TimeTracker_CPP_Latest.app.tar.gz"
  name "IACLS Time Tracker"
  desc "Floating button time tracker for lawyers"
  homepage "https://github.com/markwbennett/TimeTrackButton"

  app "TimeTracker_Universal.app", target: "IACLS Time Tracker.app"

  zap trash: [
    "~/Documents/TimeTracker",
    "~/Library/Preferences/com.iacls.timetracker.plist",
  ]
end 