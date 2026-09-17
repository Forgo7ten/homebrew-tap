cask "miclock" do
  arch arm: "arm64", intel: "x86_64"

  version "1.2.0"
  sha256 arm:   "589eb5e0658203ac76a96d64bb8f1eb5ab1f73cc5e3ebb6f1def4842a29eb72d",
         intel: "5a22b77ad52f7e1b7df60b37ec92bc6ae867851c4742760b83d8058c2158c970"

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
