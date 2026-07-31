# frozen_string_literal: true

# Linux amd64 binary. macOS: brew install --cask 0x-excali
# Formula file cannot be named 0x-excali.rb (invalid Ruby class name).

class OxExcali < Formula
  desc "Create, organize, and version your drawings with GitHub sync"
  homepage "https://github.com/krafterlabs/0x-excali"
  license "MIT"
  version "1.0.4"

  on_macos do
    odie "Install the macOS app with: brew install --cask 0x-excali"
  end

  on_linux do
    on_arm do
      odie "Linux arm64 builds are not published yet. Use amd64 or the macOS cask."
    end
    on_intel do
      url "https://github.com/krafterlabs/0x-excali/releases/download/v#{version}/0x-excali-production-linux-amd64-v#{version}.tar.gz"
      sha256 "e3e46bc0806add99ead1d56250cb37001d7bc7c32100ae4e2b31131d941f0949"
    end
  end

  def install
    bin.install "0x-excali"
  end

  def caveats
    <<~EOS
      Requires WebKitGTK / GTK on Linux, e.g. Debian/Ubuntu:
        sudo apt-get install -y libwebkit2gtk-4.1-0 libgtk-3-0
    EOS
  end

  test do
    assert_predicate bin/"0x-excali", :executable?
  end
end
