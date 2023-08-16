cask "qagate" do
  arch arm: "arm64", intel: "x86_64"

  version "1.3.0"
  sha256 arm:   "13942ae6acacb61cdfb4ee789a7a97b3c9debb248d4b56a7cd652a7b2d97270d",
         intel: "e5a9826ba6344ca2f65dfb864bda24845c7dad0a17a3c88ed9da55e2ccb83e59"

  url "http://forge.abinit.org/homebrew/qAgate-#{version}-#{arch}.dmg"

  name "qAgate"
  desc "Qt interface for agate"
  homepage "https://github.com/piti-diablotin/qAgate"

  depends_on macos: ">= :catalina"

  app "qAgate.app"
end

# NOTE
# To create the dmg file:
#   brew reinstall qagate
#   $(brew --prefix)/Library/Taps/abinit/homebrew-tap/Casks/tools/make_qagate_dmg.sh 
