class Qagate < Formula
  desc "Qt interface for agate"
  homepage "https://github.com/piti-diablotin/qAgate"
  url "https://github.com/piti-diablotin/qAgate/releases/download/v1.2.0/qAgate1.2.0.tar.gz"
  sha256 "1271ff9a25b7e06c9b5102306880096224f5fdd2b59fde823dea73559084de0b"
  license "GPL-3.0"

  depends_on "agate" => [:build, 'without-gnuplot']
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
