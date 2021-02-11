class Agate < Formula
  desc "Agate is a Graphical Analysis Tool Engine for DFT calculations"
  homepage "https://github.com/piti-diablotin/agate"
  url "https://github.com/piti-diablotin/agate/releases/download/v1.2.1/agate-1.2.1.tar.gz"
  sha256 "918f500541d1bb34b64592b1584b56a77009ee3f0cb82f950bf5e97570c5e951"
  license "GPL-3.0"

  depends_on "automake" => :build
  depends_on "autoconf" => :build
  depends_on "curl" => :build
  depends_on "cxxtest" => :build
  depends_on "eigen" => :build
  depends_on "fftw" => :build
  depends_on "freetype" => :build
  depends_on "glfw" => :build
  depends_on "gnuplot" => :recommended
  depends_on "jpeg" => :build
  depends_on "libpng" => :build
  depends_on "libssh" => :build
  depends_on "libtool" => :build
  depends_on "libxml2" => :build
  depends_on "netcdf" => :build
  depends_on "yaml-cpp" => :build
  depends_on "readline" => :build

  def install
    # Remove unrecognized options if warned by configure
    system "./autogen.sh"
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make"
    system "make check"
    system "make install"
  end
end
