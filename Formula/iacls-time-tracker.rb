class IaclsTimeTracker < Formula
  desc "Time tracking application for legal and professional work"
  homepage "https://github.com/markwbennett/TimeTrackButton"
  url "https://github.com/markwbennett/TimeTrackButton/raw/main/TimeTracker_CPP.app.tar.gz"
  sha256 "039249e396e957f2bec58bff2121bb8db7e6b1f73d464052b0fcdd778a034ccc"
  version "1.0.0"

  def install
    prefix.install "TimeTracker_CPP.app"
  end

  def caveats
    <<~EOS
      To run IACLS Time Tracker:
        open #{prefix}/TimeTracker_CPP.app

      Or add an alias to your shell profile:
        alias timetracker="open #{prefix}/TimeTracker_CPP.app"

      The app will create a floating button for time tracking.
      Data is stored in ~/Documents/TimeTracker/
    EOS
  end

  test do
    assert_predicate prefix/"TimeTracker_CPP.app", :exist?
  end
end 