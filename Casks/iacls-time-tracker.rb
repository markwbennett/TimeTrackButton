cask "iacls-time-tracker" do
  version "1.3.3"
  sha256 "2b8f73019a955f88ef40d3389479ad68c1afa6b9feefaf8e912359fce4220654"

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