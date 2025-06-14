cask "iacls-time-tracker" do
  version "1.0.0"
  sha256 "039249e396e957f2bec58bff2121bb8db7e6b1f73d464052b0fcdd778a034ccc"

  url "https://github.com/markwbennett/TimeTrackButton/raw/main/TimeTracker_CPP.app.tar.gz"
  name "IACLS Time Tracker"
  desc "Time tracking application for legal and professional work"
  homepage "https://github.com/markwbennett/TimeTrackButton"

  app "TimeTracker_CPP.app", target: "IACLS Time Tracker.app"

  zap trash: [
    "~/Documents/TimeTracker",
    "~/.config/timetracker",
  ]
end 