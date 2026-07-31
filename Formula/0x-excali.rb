# frozen_string_literal: true

# Linux formula for 0x-excali desktop app (Wails).
# macOS users should install via: brew install --cask 0x-excali

class OxExcali < Formula
  desc "Create, organize, and version your drawings with GitHub sync"
  homepage "https://github.com/krafterlabs/0x-excali"
  license "MIT"
  version "1.0.4"

  bottle :unneeded

  # Published for linux/amd64 only (see krafterlabs/0x-excali releases).
  on_linux do
    on_intel do
      url "https://github.com/krafterlabs/0x-excali/releases/download/v1.0.4/0x-excali-production-linux-amd64-v1.0.4.tar.gz"
      sha256 "e3e46bc0806add99ead1d56250cb37001d7bc7c32100ae4e2b31131d941f0949"
    end
  end

  def install
    bin.install "0x-excali"
  end

  test do
    assert_predicate bin/"0x-excali", :executable?
  end
end
