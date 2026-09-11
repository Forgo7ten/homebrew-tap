cask "miclock" do
  arch arm: "arm64", intel: "x86_64"

  version "1.1.1"
  sha256 arm:   "61c6424d16f884dde5b4e0d974a919eac45d23e194c9a19491dcbc2d5d566d2b",
         intel: "09f7b735f349d4d200d88362b7ebbece600016e9012f5e82ce082dd23c523a51"

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
