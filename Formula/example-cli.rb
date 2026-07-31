# frozen_string_literal: true

# Example formula — replace with real project data or delete after scaffolding.
# Demonstrates the recommended multi-platform release layout for private repos.

class ExampleCli < Formula
  desc "Example CLI distributed via private GitHub releases"
  homepage "https://github.com/my-org/example-cli"
  license "MIT"
  version "1.0.0"

  bottle :unneeded

  on_macos do
    on_arm do
      url "https://github.com/my-org/example-cli/releases/download/v1.0.0/example-cli-1.0.0-darwin-arm64.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
    on_intel do
      url "https://github.com/my-org/example-cli/releases/download/v1.0.0/example-cli-1.0.0-darwin-amd64.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/my-org/example-cli/releases/download/v1.0.0/example-cli-1.0.0-linux-arm64.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
    on_intel do
      url "https://github.com/my-org/example-cli/releases/download/v1.0.0/example-cli-1.0.0-linux-amd64.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end

  def install
    bin.install "example-cli"
  end

  test do
    system "#{bin}/example-cli", "--version"
  rescue ErrorDuringExecution
    system "#{bin}/example-cli", "--help"
  end
end
