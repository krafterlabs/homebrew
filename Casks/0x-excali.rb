# frozen_string_literal: true

cask "0x-excali" do
  version "1.0.4"
  sha256 "48e27abe7775374e552f5bb7c822c9be280e6e7a6179df07deb8cc1afaba79e4"

  url "https://github.com/krafterlabs/0x-excali/releases/download/v#{version}/0x-excali-production-macOS-universal-v#{version}.dmg"
  name "0x-excali"
  desc "Create, organize, and version your drawings with GitHub sync"
  homepage "https://github.com/krafterlabs/0x-excali"

  app "0x-excali.app"

  zap trash: [
    "~/Library/Application Support/0x-excali",
    "~/Library/Preferences/com.wails.0x-excali.plist",
    "~/Library/Saved Application State/com.wails.0x-excali.savedState",
  ]
end
