class Agate < Formula
  desc "Agate is a Graphical Analysis Tool Engine for DFT calculations"
  homepage "https://github.com/piti-diablotin/agate"
  url "https://github.com/piti-diablotin/agate/releases/download/v1.3.4/agate-1.3.4.tar.gz"
  sha256 "2a30c0dca6cdfe4001662200563ece3c59cf5e05f2354386413037b3866abe39"
  license "GPL-3.0"

# Tests are optional: bad idea but temporary hack
  option "with-test", "Skip build-time quick tests (not recommended)"

  depends_on "automake" => :build
  depends_on "autoconf" => :build
  depends_on "libtool" => :build
  depends_on "cxxtest" => :build
  depends_on "curl" => :build
  depends_on "eigen" => :build
  depends_on "fftw" => :build
  depends_on "freetype" => :build
  depends_on "glfw" => :build
  depends_on "jpeg" => :build
  depends_on "libpng" => :build
  depends_on "libssh" => :build
  depends_on "libxml2" => :build
  depends_on "netcdf" => :build
  depends_on "yaml-cpp" => :build
  depends_on "readline" => :build
  depends_on "icu4c" => :build
# depends_on "gnuplot" => :optional

  def install

    #Dirty hack to adjust window size
    if OS.mac?
      inreplace "src/window/winglfw3.cpp",
                "glfwWindowHint(GLFW_COCOA_RETINA_FRAMEBUFFER, GLFW_FALSE);",
                "_width/=3; _height=_width; glfwWindowHint(GLFW_COCOA_RETINA_FRAMEBUFFER, GLFW_FALSE);"
    end

    # Remove unrecognized options if warned by configure
    system "./autogen.sh"
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--with-readline=#{Formula["readline"].opt_prefix}",
                          "--with-curl=#{Formula["curl"].opt_prefix}",
                          "--with-eigen=#{Formula["eigen"].opt_prefix}/include",
                          "--with-libxml2=#{Formula["libxml2"].opt_prefix}",
                          "--with-yaml-cpp=#{Formula["yaml-cpp"].opt_prefix}",
                          "--with-fftw3=#{Formula["fftw"].opt_prefix}",
                          "--with-ssh=#{Formula["libssh"].opt_prefix}",
                          "--with-glfw=#{Formula["glfw"].opt_prefix}",
                          "--with-libjpeg=#{Formula["jpeg"].opt_prefix}",
                          "--with-libpng=#{Formula["libpng"].opt_prefix}",
                          "--with-freetype=#{Formula["freetype"].opt_prefix}",
                          "--with-netcdf=#{Formula["netcdf"].opt_prefix}",
                          "--prefix=#{prefix}"
    system "make"

    if build.with? "test"
      system "make", "check","|| echo"
    end

    system "make", "install"
  end

  test do
    system "make", "check"
  end
end
