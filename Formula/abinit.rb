class Abinit < Formula
  desc "Atomic-scale first-principles simulation software"
  homepage "https://www.abinit.org/"
  url "https://forge.abinit.org/abinit-10.2.7.tar.gz"
  sha256 "e0e1049b01b4ebaec29be632cd554caeccb4b2a8acf2e148c8ac505e6b226dc1"
  license "GPL-3.0-only"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_sequoia: "31c7af920b923ddf07bfb6a13c79dfd4a33fb33a781d73819193c9df605fcedf"
    sha256 cellar: :any, arm64_sonoma: "66eae18fe4f85507d73a4511786fb7c7925a796254b3ccf55df55a81f5f9c582"
    sha256 cellar: :any, arm64_ventura: "c8a03a41cd162fed1134d8b17ee39b6123509cfc7201c1227f66480bd124a9a3"
    sha256 cellar: :any, arm64_monterey: "d93974913a6a0b00c100b5523692b589332667d6846ff4aea67a7cbcb0e0d1cf"
    sha256 cellar: :any, sequoia: "4f30749c451a9925e830cda6b14de0eb308b522a833488eb2587435d53f71cfa"
    sha256 cellar: :any, sonoma: "924da9f5b62f342f339027f1d3b5ea1b88881a63852b481092b86c74b41536fd"
    sha256 cellar: :any, ventura: "f801f58c1db2a891d835840a3ce4f0e9fcb8e1d8df716c65d7a5e88059d80581"
    sha256 cellar: :any, monterey: "f4bc8a6bcb9043182c7103e6b368e819beacd75594fa6af6d9fd41a11d0a8528"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "67caa8118770661f32834a69c95c16c9038fd6ff1a45f74ef3500ef3b3a70d8a"
  end

  option "without-openmp", "Disable OpenMP multithreading"
  option "without-test", "Skip build-time quick tests (not recommended)"
  option "with-testsuite", "Install script to run full test suite (see: brew test abinit)"

  depends_on "gcc"
  depends_on "libxc"
  depends_on "netcdf-fortran"
  depends_on "open-mpi"
  depends_on "openblas"
  depends_on "fftw" => :recommended
  depends_on "libxml2" => :recommended
  depends_on "scalapack" => :recommended
  depends_on "wannier90" => :recommended
  depends_on "netcdf-fortran-parallel" => :optional

  conflicts_with "abinit8", because: "abinit 9/10 and abinit 8 share the same executables"

  def install
    ENV.delete "CC"
    ENV.delete "CXX"
    ENV.delete "F77"
    ENV.delete "FC"

    compilers = %w[
      CC=mpicc
      CXX=mpicxx
      FC=mpifort
    ]

    compilers << "FCFLAGS_EXTRA=-fallow-argument-mismatch -Wno-missing-include-dirs"

    # mpicc (clang) does not handle correctly -march, -mtune and mcpu
    if OS.mac? && Hardware::CPU.arm?
      #inreplace "configure", "-mtune=native -march=native", "-march=native"
      if (DevelopmentTools.clang_build_version < 1500)
        inreplace "configure", "-march=native", ""
      end
    end
    if OS.mac? && Hardware::CPU.intel? 
      inreplace "configure", "-mtune=native -mcpu=native", "-mtune=native"
    end

    args = %W[
      --prefix=#{prefix}
      --with-mpi=yes
      --enable-mpi-inplace=yes
      --with-optim-flavor=standard
      --enable-zdot-bugfix=yes
      --with-libxc=#{Formula["libxc"].opt_prefix}
    ]

    if build.with? "netcdf-fortran-parallel"
      args << "--with-netcdf=#{Formula["netcdf-parallel"].opt_prefix}"
      args << "--with-netcdf-fortran=#{Formula["netcdf-fortran-parallel"].opt_prefix}"
    else
      args << "--with-netcdf=#{Formula["netcdf"].opt_prefix}"
      args << "--with-netcdf-fortran=#{Formula["netcdf-fortran"].opt_prefix}"
    end

    libs = %w[]

    args << ("--enable-openmp=" + (build.with?("openmp") ? "yes" : "no"))

    if build.with? "scalapack"
      args << "--with-linalg-flavor=netlib"
      libs << "LINALG_LIBS=-L#{Formula["openblas"].opt_lib} -lopenblas " \
              "-L#{Formula["scalapack"].opt_lib} -lscalapack"
    else
      args << "--with-linalg-flavor=none"
      libs << "LINALG_LIBS=-L#{Formula["openblas"].opt_lib} -lopenblas"
    end

    if build.with? "fftw"
      args << "--with-fft-flavor=fftw3"
      libs << "FFTW3_FCFLAGS=-I#{Formula["fftw"].opt_include}"
      libs << "FFTW3_LIBS=-L#{Formula["fftw"].opt_lib} " \
              "-lfftw3_threads -lfftw3 -lfftw3f -lfftw3_mpi -lfftw3f_mpi"
    else
      args << "--with-fft-flavor=goedecker"
    end

    args << "--with-libxml2=#{Formula["libxml2"].opt_prefix}" if build.with? "libxml2"
    args << "--with-hdf5=#{Formula["hdf5-mpi"].opt_prefix}" if build.with? "hdf5-mpi"
    args << "--with-wannier90=#{Formula["wannier90"].opt_prefix}" if build.with? "wannier90"

    system "./configure", *args, *libs, *compilers
    system "make"

    if build.with? "test"
      # Find python executable
      py = `which python3`.size.positive? ? "python3" : "python"
      py.prepend "OMP_NUM_THREADS=1 " if OS.linux? && build.with?("openmp")
      # Execute quick tests
      system "#{py} ./tests/runtests.py built-in fast 2>&1 >make-check.log"
      system "grep", "-A2", "Suite", "make-check.log"
      ohai `grep ", succeeded:" "make-check.log"`.chomp
      prefix.install "make-check.log"
    end

    system "make", "install"

    if build.with? "testsuite"
      # Find python executable
      py = `which python3`.size.positive? ? "python3" : "python"
      py.prepend "OMP_NUM_THREADS=1 " if OS.linux? && build.with?("openmp")
      # Generate test database
      system "#{py} ./tests/runtests.py fast[00] 2>&1 >/dev/null"
      # Test paths
      test_path = share/"tests"
      test_dir = Pathname.new(test_path.to_s)
      # Copy tests directory
      share.install "#{buildpath}/tests"
      # Delete some files
      rm_rf "#{test_path}/config"
      rm_rf "#{test_path}/config.*"
      rm_rf "#{test_path}/configure.*"
      rm_rf "#{test_path}/Makefile.*"
      rm_rf "#{test_path}/autogen.sh"
      rm_rf "#{test_path}/wipeout.sh"
      # Copy some needed files
      test_dir.install "config.h"
      Pathname.new("#{test_path}/runtests.py").chmod 0555
      # Create symlinks to have a fake test environment
      mkdir_p "#{test_path}/src"
      cd "#{test_path}/src"
      ln_s bin.relative_path_from("#{test_path}/src"), "98_main", force: true
      # Create a wrapper to runtests.py script
      test_file = File.new("abinit-runtests", "w")
      test_file.puts "#!/bin/sh"
      ver = revision.zero? ? version.to_s : "#{version}_#{revision}"
      test_file.puts "SHAREDIR=`brew --cellar`\"/#{name}/#{ver}/share\""
      test_file.puts "TESTDIR=${SHAREDIR}\"/tests\""
      test_file.puts "if [ -w \"${TESTDIR}/test_suite.cpkl\" ];then"
      test_file.puts " PYTHONPATH=${SHAREDIR}\":\"${PYTHONPATH} #{py} ${TESTDIR}\"/runtests.py\" -b\"${TESTDIR}\" $@"
      test_file.puts "else"
      test_file.puts " echo \"You dont have write access to \"${TESTDIR}\"! use sudo?\""
      test_file.puts "fi"
      test_file.close
      bin.install "abinit-runtests"
      # Go back into buildpath
      cd buildpath
    end
  end

  def caveats
    unless build.with?("testsuite")
      <<~EOS
        ABINIT test suite is not available because it
        has not been activated at the installation stage.
        Action: install with 'brew install abinit --with-testsuite'.

      EOS
    end
    if OS.linux? && build.with?("openmp")
      <<~EOS
        Note: if, running ABINIT without MPI, you experience
        a 'ompi_mpi_init' error, try setting:
        OMP_NUM_THREADS=1
      EOS
    end
  end

  test do
    system "#{bin}/abinit", "-b"
    if build.with?("testsuite")
      system "#{bin}/abinit-runtests", "--help"
      puts
      puts "The entire ABINIT test suite has been copied into:"
      puts "#{share}/tests"
      puts
      puts "This ABINIT test suite is available"
      puts "thanks to the 'abinit-runtests' script."
      puts "Type 'abinit-runtests --help' to learn more."
      puts "Note that you need write access to #{share}/tests."
    end
  end
end
