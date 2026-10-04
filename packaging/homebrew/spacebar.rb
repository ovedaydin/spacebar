# Copy to Casks/spacebar.rb in a repo named <you>/homebrew-tap.
# Users install with:  brew install --cask <you>/tap/spacebar
cask "spacebar" do
  version "0.1.0"
  sha256 "REPLACE_WITH_SHA256_OF_ZIP"

  url "https://github.com/ovedaydin/spacebar/releases/download/v#{version}/Spacebar-#{version}.zip"
  name "Spacebar"
  desc "Free, open-source disk space analyzer and cleaner"
  homepage "https://github.com/ovedaydin/spacebar"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: :ventura

  app "Spacebar.app"
  # The app's own binary doubles as the command-line tool: `spacebar help`.
  binary "#{appdir}/Spacebar.app/Contents/MacOS/Spacebar", target: "spacebar"

  # The app is self-signed, not notarized, so strip quarantine after install.
  # Remove this block if you switch to Developer ID + notarization.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/Spacebar.app"]
  end

  uninstall quit: "io.github.ovedaydin.spacebar"

  zap trash: [
    "~/Library/Caches/io.github.ovedaydin.spacebar",
    "~/Library/Preferences/io.github.ovedaydin.spacebar.plist",
    "~/Library/Saved Application State/io.github.ovedaydin.spacebar.savedState",
  ]
end
