class Libxc4 < Formula
  desc "Library of exchange and correlation functionals for codes (abinit version)"
  homepage "https://tddft.org/programs/libxc/"
  url "https://gitlab.com/libxc/libxc/-/archive/4.3.4/libxc-4.3.4.tar.bz2"
  sha256 "0efe8b33d151de8787e33c4ba8e2161ffb9da978753f3bd12c5c0a018e7d3ef5"
  license "MPL-2.0"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256                               arm64_big_sur: "f1751f44cf837dfb6316ac989ce971efaa8d695e1d0872b147a01ec1937859bf"
    sha256 cellar: :any,                 big_sur:       "4c753f3313d0be80b227a7c493eaa047aac3c2988f8c1e3439312081cd7ff534"
    sha256 cellar: :any,                 catalina:      "88f4d8195e9f7c8e142a1d200989a1e75fb40181cb7ab853c77ac0f68602ef14"
    sha256 cellar: :any,                 mojave:        "07d379208b40693ebe0026b6cc2c8ede3d68f4000d2e3b065dc755956aa035ce"
    sha256 cellar: :any,                 high_sierra:   "95ebdcf8c3c10f7d5e69ac5bf3446b31a904a083e120def84d55ca585d69f2ea"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "3d2b35b0f07621c34facd0b0496b6c2403404717ff98277c6a79e31e75fa845a"
  end

  keg_only "conflict with official libxc library"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "gcc" # for gfortran

  def install
    system "autoreconf", "-fiv"
    system "./configure", "--prefix=#{prefix}",
                          "--enable-shared",
                          "FCCPP=gfortran -E -x c",
                          "CC=#{ENV.cc}"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <stdio.h>
      #include <xc.h>
      int main()
      {
        int major, minor, micro;
        xc_version(&major, &minor, &micro);
        printf(\"%d.%d.%d\", major, minor, micro);
      }
    EOS
    system ENV.cc, "test.c", "-L#{lib}", "-I#{include}", "-lxc", "-o", "ctest", "-lm"
    system "./ctest"

    (testpath/"test.f90").write <<~EOS
      program lxctest
        use xc_f03_lib_m
      end program lxctest
    EOS
    system "gfortran", "test.f90", "-L#{lib}", "-lxc", "-I#{include}",
                       "-o", "ftest"
    system "./ftest"
  end
end
