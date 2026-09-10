cask "miclock" do
  arch arm: "arm64", intel: "x86_64"

  version "1.0.0"
  sha256 arm:   "a8479b98a0f67d278e125afcd1f8278415384e86c61c8b7e255be0c041362944",
         intel: "2fc558bb03ee41d24be0f3d9473a54a8ec955e82f8b931b22f3235fc3322545d"

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
