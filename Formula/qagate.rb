class Qagate < Formula
  desc "Qt interface for agate"
  homepage "https://github.com/piti-diablotin/qAgate"
  url "https://github.com/piti-diablotin/qAgate/releases/download/v1.2.3/qAgate1.2.3.tar.gz"
  sha256 "104a21533d20dd5ee61bb08278ea946aec2f7a1742a00490540bda10df26d02f"
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
