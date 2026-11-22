cask "kenning-ide" do
  version "0.1.0"
  sha256 "85833b44a838aba1a585abeba14a9115caf4d1015283de5b7cba3d3b662df3d7"

  url "https://github.com/kenninglabs/homebrew-kenning/releases/download/v0.1.0/Kenning-0.1.0.zip"
  name "Kenning"
  desc "Native code editor with graph navigation and knowledge retrieval"
  homepage "https://github.com/kenninglabs/homebrew-kenning"

  app "Kenning.app"

  caveats <<~EOS
    Kenning.app is signed but not notarized by Apple, so macOS will refuse to
    open it on first launch. Clear the quarantine flag after installing:

      xattr -dr com.apple.quarantine /Applications/Kenning.app

    Or allow it once via System Settings > Privacy & Security > "Open Anyway".

    (--no-quarantine is not a valid `brew install` flag on current Homebrew
    versions, despite some older docs mentioning it — the xattr command above
    is the reliable fix.)

    The kenning command-line tool is unaffected by any of this:

      brew install kenning
  EOS
end
