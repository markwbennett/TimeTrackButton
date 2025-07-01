cask "iacls-time-tracker" do
  version "1.3.4"
  sha256 "ffced9a29d0f6b8e201e25f0f5a73e732148e681ef424bee4da5b8b46279179f"

  url "https://github.com/markwbennett/TimeTrackButton/raw/main/releases/TimeTracker_CPP_Latest.app.tar.gz"
  name "IACLS Time Tracker"
  desc "Floating button time tracker for lawyers"
  homepage "https://github.com/markwbennett/TimeTrackButton"

  app "TimeTracker_CPP.app", target: "IACLS Time Tracker.app"

  zap trash: [
    "~/Documents/TimeTracker",
    "~/Library/Preferences/com.iacls.timetracker.plist",
  ]
end 