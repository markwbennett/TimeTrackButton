cask "iacls-time-tracker" do
  version "1.3.2"
  sha256 "aac29efae5ff376b8acf55abd376653c17e7e43ffabd672e68f1396a18cb331c"

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