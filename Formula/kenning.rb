class Kenning < Formula
  desc "Per-hub code-graph and knowledge index with MCP server and web UI"
  homepage "https://github.com/kenninglabs/homebrew-kenning"
  version "0.1.0"
  license :cannot_represent

  url "https://github.com/kenninglabs/homebrew-kenning/releases/download/v0.1.0/kenning-0.1.0-aarch64-apple-darwin.tar.gz"
  sha256 "266c9c6a60c2aa06dc443e23a6a10fc438e400aa51b0bec0191766decb33890b"

  def install
    bin.install "kenning"
    doc.install "LICENSE"
    doc.install "THIRD-PARTY-NOTICES" if File.exist?("THIRD-PARTY-NOTICES")
  end

  test do
    assert_match "kenning", shell_output("#{bin}/kenning --version")
  end
end
