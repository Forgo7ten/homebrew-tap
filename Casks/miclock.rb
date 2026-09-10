cask "miclock" do
  arch arm: "arm64", intel: "x86_64"

  version "1.0.0"
  sha256 :no_check

  url "https://github.com/Forgo7ten/MicLock/releases/download/v#{version}/MicLock-v#{version}-#{arch}.zip"
  name "MicLock"
  desc "Protect the preferred audio input device"
  homepage "https://github.com/Forgo7ten/MicLock"

  livecheck do
    url "https://github.com/Forgo7ten/MicLock"
    strategy :github_latest
  end

  depends_on macos: :sonoma

  app "MicLock.app"

  uninstall quit:       "lee.miclock.app",
            login_item: "MicLock"

  zap trash: "~/Library/Preferences/lee.miclock.app.plist"
end
