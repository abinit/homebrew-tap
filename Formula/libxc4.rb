class Libxc4 < Formula
  desc "Library of exchange and correlation functionals for codes (abinit version)"
  homepage "https://tddft.org/programs/libxc/"
  url "https://gitlab.com/libxc/libxc/-/archive/4.3.4/libxc-4.3.4.tar.bz2"
  sha256 "ff7228953b39c79189ed31f78a082f36badfd0f25cdc125c3ca153ad1cc1ea84"
  license "MPL-2.0"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_ventura: "9f80776397961a90f4b2276a3c10f8f1d945fb4b94bcfa39eb5158f75fb9d707"
    sha256 cellar: :any, arm64_monterey: "786dd1c5d4a979d7274a0ce45196a5d54f823330556081ba2cd697d22e4aeb77"
    sha256 cellar: :any, ventura: "5237eb849b3ef85610410e797b55f2693f534e4db10abdd012b922fd8cfab210"
    sha256 cellar: :any, monterey: "76b15e1aa9caddf652795e1707ea6a907c6cfa865c28e6e05f9071ecd485f2f4"
    sha256 cellar: :any, big_sur: "bf28c8b6d488880bd570b86e203d1d9361d2fafc1aaa8c04b8d52f14a79e8c69"
    sha256 cellar: :any, catalina: "9af71198af1cc4b3cc9a72323aec9d604b075a8c0e76d835b98c8aa57016997d"
    sha256 cellar: :any, mojave: "3bf011d878a324a7fdfaa0cbe3c4390cc5415ebbbdb1bce32e49070999140971"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "19a3bd982888af386828a8ca7fc9864bb5ba254f874429481a35da3b248483e1"
  end

  keg_only "conflict with official libxc library"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "gcc" # for gfortran

  def install
    # Since monterey, need some patch for Fortran detection
    inreplace "m4/fc_integer.m4", "write(1,'(i1)') i", "write(1,'(i1)') i ; close(1)"
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
