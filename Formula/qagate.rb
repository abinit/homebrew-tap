class Qagate < Formula
  desc "Qt interface for agate"
  homepage "https://github.com/piti-diablotin/qAgate"
  url "https://github.com/piti-diablotin/qAgate/releases/download/v1.2.2/qAgate1.2.2.tar.gz"
  sha256 "b1b70918c38288c0f9fea10e7b2762ec5638443eefc5992f084b7fe42365adf7"
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
