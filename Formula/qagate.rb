class Qagate < Formula
  desc "Qt interface for agate"
  homepage "https://github.com/piti-diablotin/qAgate"
  url "https://github.com/piti-diablotin/qAgate/releases/download/v1.2.1/qAgate1.2.1.tar.gz"
  sha256 "f84897d1bf057d1ae9d1776c3d684787654dcc879956509def1015f736d21b6d"
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
