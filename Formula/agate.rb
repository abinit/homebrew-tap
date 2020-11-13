class Agate < Formula
  desc "A graphical analysis tool engine for DFT calculations"
  homepage "https://github.com/piti-diablotin/agate"
  url "https://github.com/piti-diablotin/agate/releases/download/v1.1.1/agate-1.1.1.tar.gz"
  sha256 "ed6706eb1196b69d882a41d02a7683fa33f33f39faf9f81d70db812b31db1321"
  license "GPL-3.0"

  depends_on "automake" => :build
  depends_on "autoconf" => :build
  depends_on "curl" => :build
  depends_on "cxxtest" => :build
  depends_on "eigen" => :build
  depends_on "fftw" => :build
  depends_on "freetype" => :build
  depends_on "glfw" => :build
  depends_on "gnuplot" => :build
  depends_on "libpng" => :build
  depends_on "libssh" => :build
  depends_on "libtool" => :build
  depends_on "libxml2" => :build
  depends_on "netcdf" => :build
  depends_on "yaml-cpp" => :build

  def install
    # Remove unrecognized options if warned by configure
    system "./autogen.sh"
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make check"
    system "make install"
  end
end
