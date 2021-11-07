class Abinit8 < Formula
  desc "Atomic-scale first-principles simulation software"
  homepage "https://www.abinit.org/"
  url "https://www.abinit.org/sites/default/files/packages/abinit-8.10.3.tar.gz"
  sha256 "ed626424b4472b93256622fbb9c7645fa3ffb693d4b444b07d488771ea7eaa75"
  license "GPL-3.0-only"
  revision 1

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any,                 monterey:     "e1da3e4f4cc2aea101d5c8df5ef451f4e8f27915acb5616543109814d08f6a9a"
    sha256 cellar: :any,                 big_sur:      "e562817edcd105d54f4c7fccf21f2fc2973c2172aaf1d203e9919ed1523ee3fc"
    sha256 cellar: :any,                 catalina:     "c35ff30a69d93f38a42a4ff012c672e41630fd11060bb2ff36cbae0be294ae4c"
    sha256 cellar: :any,                 mojave:       "8e9f1333d9f543ce942ab833bee86eb08e940e5552355706d50ad03cd0aa62f6"
    sha256 cellar: :any,                 high_sierra:  "82f7d7ed579dd8949f60123ca3670e34be5597f75bc36b1af0f215c6af44b3ec"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "8b2b3fda75071e6c6350fefe79260ca41ec312f3b4ef956536324472bccf3712"
  end

  option "without-openmp", "Disable OpenMP multithreading"
  option "without-test", "Skip build-time quick tests (not recommended)"
  option "with-testsuite", "Install script to run full test suite (see: brew test abinit)"

  depends_on "gcc"
  depends_on "open-mpi"
  depends_on "fftw" => :recommended
  depends_on "libxc4" => :recommended
  depends_on "netcdf" => :recommended
  depends_on "scalapack" => :recommended
  if OS.mac?
    depends_on "veclibfort"
  else
    depends_on "lapack"
  end

  conflicts_with "abinit", because: "abinit 9 and abinit 8 share the same executables"

  # From libxc3 to libXC4
  patch do
    url "https://github.com/abinit/homebrew-tap/raw/master/Formula/libxc_3to4_patch.diff"
    sha256 "257a493f6ab3079886631a488f52f2d4d1e0559c6553456bd21c0c3070311b41"
  end

  # Multibinit 8.10.3 needs to be patched with gcc9.3
  patch :DATA

  def install
    ENV.delete "CC"
    ENV.delete "CXX"
    ENV.delete "F77"
    ENV.delete "FC"

    args = %W[
      CC=mpicc
      CXX=mpicxx
      FC=mpif90
      --prefix=#{prefix}
      --enable-mpi=yes
      --with-mpi-prefix=#{HOMEBREW_PREFIX}
      --enable-optim=standard
      --enable-gw-dpc
    ]
    args << ("--enable-openmp=" + (build.with?("openmp") ? "yes" : "no"))

    # Workaround to compile with gcc10+
    args << "FCFLAGS_EXTRA=-fallow-argument-mismatch"

    trio_flavor = "none"
    dft_flavor = "none"
    linalg_flavor = "none"
    fft_flavor = "none"

    if build.with? "scalapack"
      linalg_flavor = "custom+scalapack"
      args << if OS.mac?
        "--with-linalg-libs=-L#{Formula["veclibfort"].opt_lib} -lvecLibFort " \
          "-L#{Formula["scalapack"].opt_lib} -lscalapack"
      else
        "--with-linalg-libs=-L#{Formula["lapack"].opt_lib} -lblas -llapack " \
          "-L#{Formula["scalapack"].opt_lib} -lscalapack"
      end
    else
      linalg_flavor = "custom"
      args << if OS.mac?
        "--with-linalg-libs=-L#{Formula["veclibfort"].opt_lib} -lvecLibFort"
      else
        "--with-linalg-libs=-L#{Formula["lapack"].opt_lib} -lblas -llapack"
      end
    end

    if build.with? "netcdf"
      trio_flavor = "netcdf"
      args << "--with-netcdf-incs=-I#{Formula["netcdf"].opt_include}"
      args << "--with-netcdf-libs=-L#{Formula["netcdf"].opt_lib} -lnetcdff -lnetcdf"
    end

    # Need to link against single precision as well,
    #  see https://trac.macports.org/ticket/45617
    #  and http://forum.abinit.org/viewtopic.php?f=3&t=2631
    if build.with? "fftw"
      fft_flavor = "fftw3"
      args << "--with-fft-incs=-I#{Formula["fftw"].opt_include}"
      args << "--with-fft-libs=-L#{Formula["fftw"].opt_lib} " \
              "-lfftw3 -lfftw3f -lfftw3_mpi -lfftw3f_mpi"
    end

    if build.with? "libxc4"
      dft_flavor="libxc"
      args << "--with-libxc-incs=-I#{Formula["libxc4"].opt_include}"
      args << "--with-libxc-libs=-L#{Formula["libxc4"].opt_lib} -lxcf90 -lxc"
    end

    args << "--with-linalg-flavor=#{linalg_flavor}"
    args << "--with-fft-flavor=#{fft_flavor}"
    args << "--with-trio-flavor=#{trio_flavor}"
    args << "--with-dft-flavor=#{dft_flavor}"

    system "./configure", *args
    system "make"

    if build.with? "test"
      # Execute quick tests
      system "./tests/runtests.py built-in fast 2>&1 | tee make-check.log"
      ohai `grep ", succeeded:" "make-check.log"`.chomp
      prefix.install "make-check.log"
    elsif build.with? "testsuite"
      # Generate test database only
      system "./tests/runtests.py 2>&1 fast[00] >/dev/null"
    end

    system "make", "install"

    if build.with? "testsuite"
      # Create a wrapper to runtests.py script
      test_path = share/"abinit-test"
      test_file = File.new("abinit-runtests", "w")
      test_file.puts "#!/bin/sh"
      ver = revision.zero? ? version.to_s : "#{version}_#{revision}"
      test_file.puts "SHAREDIR=\`brew --cellar\`\"/#{name}/#{ver}/share\""
      test_file.puts "TESTDIR=${SHAREDIR}\"/abinit-test\""
      test_file.puts "if [ -w \"${TESTDIR}/test_suite.cpkl\" ];then"
      test_file.puts " PYTHONPATH=${SHAREDIR}\":\"${PYTHONPATH} ${TESTDIR}\"/runtests.py\" -b\"${TESTDIR}\" $@"
      test_file.puts "else"
      test_file.puts " echo \"You dont have write access to \"${TESTDIR}\"! use sudo?\""
      test_file.puts "fi"
      test_file.close
      bin.install "abinit-runtests"
      # Copy some needed files
      test_dir = Pathname.new(test_path.to_s)
      test_dir.install "config.h"
      test_dir.install "tests/test_suite.cpkl"
      Pathname.new("#{test_path}/runtests.py").chmod 0555
      # Create symlinks to have a fake test environment
      cd share
      ln_s "abinit-test", "tests", force: true
      mkdir_p "#{test_path}/src"
      cd "#{test_path}/src"
      ln_s bin.relative_path_from("#{test_path}/src"), "98_main", force: true
      cd buildpath
    end
  end

  test do
    system "#{bin}/abinit", "-b"
    if build.with? "testsuite"
      system "#{bin}/abinit-runtests", "--help"
      puts
      puts "The entire ABINIT test suite is available"
      puts "thanks to the 'abinit-runtests' script."
      puts "Type 'abinit-runtests --help' to learn more."
      puts "Note that you need write access to #{share}/abinit-test"
      puts "and that some libXC tests (based on libXC v3) will failed."
    else
      puts
      puts "ABINIT test suite is not available because it"
      puts "has not been activated at the installation stage."
      puts "Action: install with 'brew install abinit --with-testsuite'."
    end
  end
end

__END__
diff --git a/src/78_effpot/m_polynomial_coeff.F90 b/src/78_effpot/m_polynomial_coeff.F90
index 2eb330b..f5aade1 100644
--- a/src/78_effpot/m_polynomial_coeff.F90
+++ b/src/78_effpot/m_polynomial_coeff.F90
@@ -2502,8 +2502,8 @@ recursive subroutine computeNorder(cell,coeffs_out,compatibleCoeffs,list_coeff,l
 
 !Arguments ---------------------------------------------
 !scalar
- integer,intent(in) :: natom,ncoeff,power_disp,power_disp_min,power_disp_max,ncoeff_out,nsym,nrpt,nstr
- integer,intent(inout) :: icoeff,icoeff_tot
+ integer,intent(in) :: icoeff,natom,ncoeff,power_disp,power_disp_min,power_disp_max,ncoeff_out,nsym,nrpt,nstr
+ integer,intent(inout) :: icoeff_tot
  logical,optional,intent(in) :: compute,anharmstr,spcoupling,distributed
  integer,optional,intent(in) :: nbody
 !arrays
@@ -2554,7 +2554,9 @@ recursive subroutine computeNorder(cell,coeffs_out,compatibleCoeffs,list_coeff,l
 !    If the distance between the 2 coefficients is superior than the cut-off,
 !    we cycle
 !    If the power_disp is one, we need to set icoeff to icoeff1
-     if(power_disp==1) icoeff = icoeff1
+     if(power_disp==1) then
+       if(icoeff1 <= ncoeff .and. compatibleCoeffs(icoeff1,icoeff1)==0) cycle
+     end if
 
      if(compatibleCoeffs(icoeff,icoeff1)==0) cycle

@@ -2757,9 +2757,9 @@ recursive subroutine computeCombinationFromList(cell,compatibleCoeffs,list_coeff
 
 !Arguments ---------------------------------------------
 !scalar
- integer,intent(in) :: natom,ncoeff,power_disp,power_disp_min,power_disp_max
+ integer,intent(in) :: icoeff,natom,ncoeff,power_disp,power_disp_min,power_disp_max
  integer,intent(in) :: max_power_strain,nmodel,nsym,nrpt,nstr
- integer,intent(inout) :: icoeff,nmodel_tot
+ integer,intent(inout) :: nmodel_tot
  logical,optional,intent(in) :: compute,anharmstr,spcoupling
  integer,optional,intent(in) :: nbody
  logical,optional,intent(in) :: only_odd_power,only_even_power
@@ -2807,16 +2807,15 @@ recursive subroutine computeCombinationFromList(cell,compatibleCoeffs,list_coeff
 
 !    If the power_disp is one, we need to set icoeff to icoeff1
      if(power_disp==1) then
-       icoeff = icoeff1
-       if(compatibleCoeffs(icoeff,icoeff1)==0)then
+       if(icoeff1<=ncoeff .and. compatibleCoeffs(icoeff,icoeff1)==0)then
          compatible = .FALSE.
        end if
      end if
 !    If the distance between the 2 coefficients is superior than the cut-off, we cycle.
     do icoeff2=1,power_disp-1
-      if(compatibleCoeffs(index_coeff(icoeff2),icoeff1)==0)then
-        compatible = .FALSE.
-      end if
+      if(icoeff1 <= ncoeff .and. index_coeff(icoeff2) <=ncoeff)then
+        if(compatibleCoeffs(index_coeff(icoeff2),icoeff1)==0) compatible=.FALSE.
+      endif
     end do
 
      if (.not.compatible) cycle !The distance is not compatible
