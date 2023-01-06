class Libxc4 < Formula
  desc "Library of exchange and correlation functionals for codes (abinit version)"
  homepage "https://tddft.org/programs/libxc/"
  url "https://gitlab.com/libxc/libxc/-/archive/4.3.4/libxc-4.3.4.tar.bz2"
  sha256 "ff7228953b39c79189ed31f78a082f36badfd0f25cdc125c3ca153ad1cc1ea84"
  license "MPL-2.0"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_ventura: "b135fd7a5631cb30f71971a4edec14793167d76479a3f08a7bc5a802a2747c5a"
    sha256 cellar: :any, arm64_monterey: "cec62da62415989e7e6ee71a57276c6ec2e127b25c52f0d60581458276352cce"
    sha256 cellar: :any, ventura: "1872d20983d0ae645f821870f45ec5dcd21415f8240112475e33965d2da2b3f9"
    sha256 cellar: :any, monterey: "b347b43079ec6c12420c55aae121c546229ce42bc1f86b0bd2360ce18ebce0af"
    sha256 cellar: :any, big_sur: "5e82e0be63069eeec500d0dbd4b36233415dc6cac7dd5c27cf467cbdf1c26010"
    sha256 cellar: :any, catalina: "f07640af6787f9b008b50d31f53e3aed7022c5da4c238d1d98211c65a6adcb99"
    sha256 cellar: :any, mojave: "fa6d3cd5bd774a52e1d76812907acc5085cc9e37a922d2495ff8b8b6942c2f79"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "74318fead619a39ee2e8017bfd4f0391a8660cd11b41babf4ee00c9abe4b3d72"
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
