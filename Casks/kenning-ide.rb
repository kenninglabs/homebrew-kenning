cask "kenning-ide" do
  version "0.1.0"
  sha256 "8f823ab7a53bb6ec28a5b9cf9807624a6222d5ae92ed02f00754ba2014edd5b8"

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