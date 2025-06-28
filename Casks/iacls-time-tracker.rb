cask "iacls-time-tracker" do
  version "1.1.6"
  sha256 "b02feff8e7326185431b7668bdd8d40ad7690f1085180dbe64c0b58bf3467768"

  url "https://github.com/markwbennett/TimeTrackButton/raw/a7c7bca/TimeTracker_CPP_Optimized_Signed.app.tar.gz"
  name "IACLS Time Tracker"
  desc "Simple time tracking application with floating button interface"
  homepage "https://github.com/markwbennett/TimeTrackButton"

  app "TimeTracker_CPP.app", target: "IACLS Time Tracker.app"

  zap trash: [
    "~/Documents/TimeTracker",
    "~/Library/Preferences/org.iacls.timetracker.plist",
  ]
end 