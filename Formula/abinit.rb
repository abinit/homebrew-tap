class Abinit < Formula
  desc "Atomic-scale first-principles simulation software"
  homepage "https://www.abinit.org/"
  url "https://www.abinit.org/sites/default/files/packages/abinit-8.10.3.tar.gz"
  sha256 "ed626424b4472b93256622fbb9c7645fa3ffb693d4b444b07d488771ea7eaa75"
  revision 1
  # tag "chemistry"
  # doi "10.1016/j.cpc.2016.04.003"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    cellar :any
    sha256 "e02436dfb7d126c69a52ba32e2f574c150602b2c8134993fe2bd1b42d56d7f05" => :mojave
  end

  option "without-openmp", "Disable OpenMP multithreading"
  option "without-test", "Skip build-time quick tests (not recommended)"
  option "with-testsuite", "Install script to run full test suite (see: brew test abinit)"

  depends_on "gcc" if OS.mac? # for gfortran
  depends_on "gcc" if build.with? "openmp"
  depends_on "open-mpi"
  depends_on "fftw" => :recommended
  depends_on "libxc" => :recommended
  depends_on "netcdf" => :recommended
  if OS.mac?
    depends_on "veclibfort"
    depends_on "scalapack" => :recommended
  end

# From libxc3 to libXC4
  patch do
    url "https://github.com/abinit/homebrew-tap/raw/master/Formula/libxc_3to4_patch.diff"
    sha256 "257a493f6ab3079886631a488f52f2d4d1e0559c6553456bd21c0c3070311b41"
  end

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

    trio_flavor = "none"
    dft_flavor = "none"
    linalg_flavor = "none"
    fft_flavor = "none"

    if OS.mac?
      if build.with? "scalapack"
        linalg_flavor = "custom+scalapack"
        args << "--with-linalg-libs=-L#{Formula["veclibfort"].opt_lib} -lvecLibFort -L#{Formula["scalapack"].opt_lib} -lscalapack"
      else
        linalg_flavor = "custom"
        args << "--with-linalg-libs=-L#{Formula["veclibfort"].opt_lib} -lvecLibFort"
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
      args << "--with-fft-libs=-L#{Formula["fftw"].opt_lib} -lfftw3 -lfftw3f -lfftw3_mpi -lfftw3f_mpi"
    end

    if build.with? "libxc"
      dft_flavor="libxc"
      args << "--with-libxc-incs=-I#{Formula["libxc"].opt_include}"
      args << "--with-libxc-libs=-L#{Formula["libxc"].opt_lib} -lxcf90 -lxc"
    end

    args << "--with-linalg-flavor=#{linalg_flavor}"
    args << "--with-fft-flavor=#{fft_flavor}"
    args << "--with-trio-flavor=#{trio_flavor}"
    args << "--with-dft-flavor=#{dft_flavor}"

    system "./configure", *args
    system "make"

    if build.with? "test"
      #Execute quick tests
      system "./tests/runtests.py built-in fast 2>&1 | tee make-check.log"
      ohai `grep ", succeeded:" "make-check.log"`.chomp
      prefix.install "make-check.log"
    elsif build.with? "testsuite"
      #Generate test database only
      system "./tests/runtests.py 2>&1 fast[00] >/dev/null"
    end

    system "make", "install"

    if build.with? "testsuite"
      #Create a wrapper to runtests.py script
      test_path = share/"abinit-test"
      test_file = File.new("abinit-runtests", "w")
      test_file.puts "#!/bin/sh"
      revision == 0 ? ver = "#{version}" : ver = "#{version}_#{revision}"
      test_file.puts "SHAREDIR=\`brew --cellar\`\"/#{name}/#{ver}/share\""
      test_file.puts "TESTDIR=${SHAREDIR}\"/abinit-test\""
      test_file.puts "if [ -w \"${TESTDIR}/test_suite.cpkl\" ];then"
      test_file.puts " PYTHONPATH=${SHAREDIR}\":\"${PYTHONPATH} ${TESTDIR}\"/runtests.py\" -b\"${TESTDIR}\" $@"
      test_file.puts "else"
      test_file.puts " echo \"You dont have write access to \"${TESTDIR}\"! use sudo?\""
      test_file.puts "fi"
      test_file.close
      bin.install "abinit-runtests"
      #Copy some needed files
      test_dir = Pathname.new("#{test_path}")
      test_dir.install "config.h"
      test_dir.install "tests/test_suite.cpkl"
      Pathname.new("#{test_path}/runtests.py").chmod 0555
      #Create symlinks to have a fake test environment
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
