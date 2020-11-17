class Qagate < Formula
  desc "Qt interface for agate"
  homepage ""
  url "https://github.com/piti-diablotin/qAgate/releases/download/v1.1.1/qAgate1.1.1.tar.gz"
  sha256 "4dfe6ed4ac008284b918ced6dcdb29db35a641069a6d3bc41b09917fe196eea7"
  license ""

  depends_on "agate" => :build
  depends_on "freetype" => :build
  depends_on "libssh" => :build
  depends_on "qt" => :build

  def install
    system "lrelease", "qAgate.pro"

    system "qmake", "PREFIX=#{prefix}",
                          "PREFIX_AGATE=/usr/local",
                          "PREFIX_FREETYPE=/usr/local",
                          "PREFIX_SSH=/usr/local",
                          "qAgate.pro"

    system "make", "install"
  end

end
