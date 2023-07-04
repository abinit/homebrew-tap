cask "qagate" do
  arch arm: "arm64", intel: "x86_64"

  version "1.2.3"
  sha256 arm:   "c9ebf02d6a8943acccb63746451dda62b77f8027863f6167cff8158f70814c41",
         intel: "f0df5e0bf8fcce79f46654b437aaaf4e25e3cafeb042591466d1ab9e0e655942"

# To create the dmg file:
#   brew install qagate
#   cd $(brew --prefix)/Cellar/qagate/*/bin
#   $(brew --prefix)/Cellar/qt@5/*/bin/macdeployqt qAgate.app -dmg
  url "http://forge.abinit.org/homebrew/qAgate-#{version}-#{arch}.dmg"

  name "qAgate"
  desc "Qt interface for agate"
  homepage "https://github.com/piti-diablotin/qAgate"

  depends_on macos: ">= :catalina"

  app "qAgate.app"
end
