class Abinit < Formula
  desc "Atomic-scale first-principles simulation software"
  homepage "https://www.abinit.org/"
  url "https://www.abinit.org/sites/default/files/packages/abinit-10.0.5.tar.gz"
  sha256 "07fed4df03ae32178933373b990bbda4431ea836fc7bebec05b17e4267bb7f4e"
  license "GPL-3.0-only"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_sonoma: "ce0e37b3fef4cf377241d273f5bd9a45a3ec80e6ac5a535dddf90d363c8b399a"
    #sha256 cellar: :any, arm64_ventura: "f5d148c85408de2f8077bcb51d17aeb4da618d6bdf685d36781c62db93cc31bb"
    #sha256 cellar: :any, arm64_monterey: "513ca3d7b299c8b5d1d39d1330ab8282ff8220dd835e7b42ac4827612ed7f6b8"
    #sha256 cellar: :any, ventura: "a557f549f7c99f49bc551bff47ab3929544c3b1bfdf80824083d9d1336ca69be"
    #sha256 cellar: :any, monterey: "0bca7894357bb7cbb3c57d7fe35419b25323cfeefe3d6a5f326ff344902a2a0a"
    #sha256 cellar: :any, big_sur: "0b1a6e59f04194b1c0057aacef878b3284b2d68c208e59b6f81d939af6721e91"
    #sha256 cellar: :any, catalina: "f65cbdfa048b8e759fa9013bade18297be99db563edf6f2c6145f09a5c713c91"
    #sha256 cellar: :any_skip_relocation, x86_64_linux: "d20af4be1cf331efda6589f5d6fa43143663d1e76ec282d96a4092aa4a1eb7dd"
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

  conflicts_with "abinit8", because: "abinit 9 and abinit 8 share the same executables"

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

    # This is temporary
    compilers << "CFLAGS=-g -O2 -march=native"
    compilers << "CXXFLAGS=-g -O2 -march=native"
    compilers << "FCFLAGS=-g -O2 -march=native -fallow-argument-mismatch -Wno-missing-include-dirs"

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
