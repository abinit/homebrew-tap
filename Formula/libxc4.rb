class Libxc4 < Formula
  desc "Library of exchange and correlation functionals for codes (abinit version)"
  homepage "https://tddft.org/programs/libxc/"
  url "https://gitlab.com/libxc/libxc/-/archive/4.3.4/libxc-4.3.4.tar.bz2"
  sha256 "ff7228953b39c79189ed31f78a082f36badfd0f25cdc125c3ca153ad1cc1ea84"
  license "MPL-2.0"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_ventura: "3ba3e9886eba197f119763b11387370c67d7cf9c7b8d8f8c54cfa46446ebd88f"
    sha256 cellar: :any, arm64_monterey: "d2e68d5c5119baac343b7691403586cfdd879ee821932717ce069b9fa75f1d4d"
    sha256 cellar: :any, ventura: "95e62b491ac8dbc1723c059bf302f20210fd5416c172e181a1abbb71bd166185"
    sha256 cellar: :any, monterey: "13a88c809e6182dc146e897fabd526df32a49359ce43f945c5c29b127e9b4150"
    sha256 cellar: :any, big_sur:  "18e48b10cff3d12ec9f8fc0a489944a7905e7cc2d41166e299cf4870aa579aff"
    sha256 cellar: :any, catalina: "48586ad13671559dc8631445dca16ea147602dd51c03d2536413abceb927a3fa"
    sha256 cellar: :any, mojave:   "ba417cef01d084aed667605278f4896beccbf9ba0fb6950a19f9cc31ef024c4e"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "614393513c09b8d3fc1b7fdf46e8e227c798024e36846015ce61216259479f2c"
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
