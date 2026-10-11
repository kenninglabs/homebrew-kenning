class Kenning < Formula
  desc "Per-hub code-graph and knowledge index with MCP server and web UI"
  homepage "https://github.com/kenninglabs/homebrew-kenning"
  version "0.1.0"
  license :cannot_represent

  url "https://github.com/kenninglabs/homebrew-kenning/releases/download/v0.1.0/kenning-0.1.0-aarch64-apple-darwin.tar.gz"
  sha256 "b7578d8faa228b7da4ca2deb2037f180734c70e7d3aa42d43a0c08d4d10a08bd"

  def install
    bin.install "kenning"
    doc.install "LICENSE"
    doc.install "THIRD-PARTY-NOTICES" if File.exist?("THIRD-PARTY-NOTICES")
  end

  test do
    assert_match "kenning", shell_output("#{bin}/kenning --version")
  end
end