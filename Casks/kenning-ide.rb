cask "kenning-ide" do
  version "0.1.0"
  sha256 "92d89238a7981c5fc9970d8ed4f0a3c59229e97b040ccc894b781886768f8e52"

  url "https://github.com/kenninglabs/homebrew-kenning/releases/download/v0.1.0/Kenning-0.1.0.zip"
  name "Kenning"
  desc "Native code editor with graph navigation and knowledge retrieval"
  homepage "https://github.com/kenninglabs/homebrew-kenning"

  app "Kenning.app"

  caveats <<~EOS
    Kenning.app is signed but not notarized by Apple, so macOS will refuse to
    open it on first launch. The simplest fix is to install without the
    quarantine flag in the first place:

      brew install --cask --no-quarantine kenning-ide

    If it is already installed and macOS is blocking it:

      xattr -dr com.apple.quarantine /Applications/Kenning.app

    Or allow it once via System Settings > Privacy & Security > "Open Anyway".

    The kenning command-line tool is unaffected by any of this:

      brew install kenning
  EOS
end
