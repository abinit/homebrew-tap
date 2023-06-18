class Qagate < Formula
  desc "Qt interface for agate"
  homepage "https://github.com/piti-diablotin/qAgate"
  url "https://github.com/piti-diablotin/qAgate/releases/download/v1.2.3/qAgate1.2.3.tar.gz"
  sha256 "104a21533d20dd5ee61bb08278ea946aec2f7a1742a00490540bda10df26d02f"
  license "GPL-3.0"
  revision 1

  depends_on "agate" => :build
  depends_on "freetype" => :build
  depends_on "libssh" => :build
  depends_on "qt5" => :build

  def install

    # Adapt to homebrew location
    inreplace "qAgate.pro", "/usr/local/include",
              "#{HOMEBREW_PREFIX}/opt/qt5/include #{HOMEBREW_PREFIX}/opt/agate/include"
    inreplace "qAgate.pro", "/usr/local", "#{HOMEBREW_PREFIX}"

    # For Retina displays, need to use the pixel ratio
    inreplace "gui/view.cpp", "_width = width;", "_width = width * devicePixelRatio();"
    inreplace "gui/view.cpp", "_height = height;", "_height = height * devicePixelRatio();"

    system "lrelease", "qAgate.pro"

    system "#{Formula["qt5"].opt_prefix}/bin/qmake",
           "PREFIX=#{prefix}",
           "PREFIX_AGATE=#{Formula["agate"].opt_prefix}",
           "PREFIX_FREETYPE=#{Formula["freetype"].opt_prefix}",
           "PREFIX_SSH=#{Formula["libssh"].opt_prefix}",
           "qAgate.pro"

    system "make", "install"
  end

end
