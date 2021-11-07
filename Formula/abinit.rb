class Abinit < Formula
  desc "Atomic-scale first-principles simulation software"
  homepage "https://www.abinit.org/"
  url "https://www.abinit.org/sites/default/files/packages/abinit-9.6.1.tar.gz"
  sha256 "b6a12760fd728eb4aacca431ae12150609565bedbaa89763f219fcd869f79ac6"
  license "GPL-3.0-only"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any,                 arm64_big_sur: "bb76cfe88794b21a1c07b0c416b1fb0a03e675a67181a3760a1d63333b674d67"
    sha256 cellar: :any,                 monterey:      "926e8e522c9b110331c64697145989827f3923306159d256d24aa5f4e2beba4e"
    sha256 cellar: :any,                 big_sur:       "72eea5cbe27897cc207016b804f9f6b51f50a3f5248860312d32e9bd0f153ada"
    sha256 cellar: :any,                 catalina:      "8c766f766a2eaf822d48e7acba0e28002b22cb9295f48bfbe82888e982279ddc"
    sha256 cellar: :any,                 mojave:        "ab525cff2be919469af750da2a827cdb4a6d2ff83b00492b8381cbdd24853207"
    sha256 cellar: :any,                 high_sierra:   "e495135519fbc235bbc538de796051b386d3f6b15c0fbe098856ce7be46dffcd"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "53be6fb6b15ec8a11f4090dcca64c787a8259b925ab549c4f6d6871f4ae7eee0"
  end

  option "without-openmp", "Disable OpenMP multithreading"
  option "without-test", "Skip build-time quick tests (not recommended)"
  option "with-testsuite", "Install script to run full test suite (see: brew test abinit)"

  depends_on "gcc"
  depends_on "libxc"
  depends_on "netcdf"
  depends_on "open-mpi"
  if OS.mac?
    depends_on "veclibfort"
  else
    depends_on "lapack"
  end
  depends_on "fftw" => :recommended
  depends_on "hdf5-parallel" => :recommended
  depends_on "libxml2" => :recommended
  depends_on "scalapack" => :recommended
  depends_on "wannier90" => :recommended

  conflicts_with "abinit8", because: "abinit 9 and abinit 8 share the same executables"

  def install
    ENV.delete "CC"
    ENV.delete "CXX"
    ENV.delete "F77"
    ENV.delete "FC"

    compilers = %w[
      CC=mpicc
      CXX=mpicxx
      FC=mpif90
    ]
    # Workaround to compile Abinit 9.0.4 with gcc10+
    compilers << "FCFLAGS_EXTRA=-fallow-argument-mismatch"

    args = %W[
      --prefix=#{prefix}
      --with-mpi=yes
      --enable-mpi-inplace=yes
      --with-optim-flavor=standard
      --with-netcdf=#{Formula["netcdf"].opt_prefix}
      --with-netcdf-fortran=#{Formula["netcdf"].opt_prefix}
      --with-libxc=#{Formula["libxc"].opt_prefix}
      --enable-zdot-bugfix=yes
    ]

    libs = %w[]

    args << ("--enable-openmp=" + (build.with?("openmp") ? "yes" : "no"))

    if build.with? "scalapack"
      args << "--with-linalg-flavor=netlib"
      libs << if OS.mac?
        "LINALG_LIBS=-L#{Formula["veclibfort"].opt_lib} -lvecLibFort " \
          "-L#{Formula["scalapack"].opt_lib} -lscalapack"
      else
        "LINALG_LIBS=-L#{Formula["lapack"].opt_lib} -lblas -llapack " \
          "-L#{Formula["scalapack"].opt_lib} -lscalapack"
      end
    else
      args << "--with-linalg-flavor=none"
      libs << if OS.mac?
        "LINALG_LIBS=-L#{Formula["veclibfort"].opt_lib} -lvecLibFort"
      else
        "LINALG_LIBS=-L#{Formula["lapack"].opt_lib} -lblas -llapack"
      end
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
    args << "--with-hdf5=#{Formula["hdf5-parallel"].opt_prefix}" if build.with? "hdf5-parallel"
    args << "--with-wannier90=#{Formula["wannier90"].opt_prefix}" if build.with? "wannier90"

    system "./configure", *args, *libs, *compilers
    system "make"

    if build.with? "test"
      # Execute quick tests
      if OS.mac?
        system "./tests/runtests.py built-in fast &> make-check.log"
        system "grep", "-A2", "Suite", "make-check.log"
      else
        python_exe = `which python3`.size.positive? ? "python3" : "python"
        system "#{python_exe} ./tests/runtests.py built-in fast &> make-check.log"
      end
      ohai `grep ", succeeded:" "make-check.log"`.chomp
      prefix.install "make-check.log"
    elsif build.with? "testsuite"
      # Generate test database only
      if OS.mac?
        system "./tests/runtests.py fast[00] &> /dev/null"
      else
        python_exe = `which python3`.size.positive? ? "python3" : "python"
        system "#{python_exe} ./tests/runtests.py fast[00] &> make-check.log"
      end
    end

    system "make", "install"

    if build.with? "testsuite"
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
      test_file.puts "SHAREDIR=\`brew --cellar\`\"/#{name}/#{ver}/share\""
      test_file.puts "TESTDIR=${SHAREDIR}\"/tests\""
      test_file.puts "if [ -w \"${TESTDIR}/test_suite.cpkl\" ];then"
      test_file.puts " PYTHONPATH=${SHAREDIR}\":\"${PYTHONPATH} ${TESTDIR}\"/runtests.py\" -b\"${TESTDIR}\" $@"
      test_file.puts "else"
      test_file.puts " echo \"You dont have write access to \"${TESTDIR}\"! use sudo?\""
      test_file.puts "fi"
      test_file.close
      bin.install "abinit-runtests"
      # Go back into buildpath
      cd buildpath
    end
  end

  test do
    system "#{bin}/abinit", "-b"
    if build.with? "testsuite"
      system "#{bin}/abinit-runtests", "--help"
      puts
      puts "The entire ABINIT test suite has been copied into:"
      puts "#{share}/tests"
      puts
      puts "This ABINIT test suite is available"
      puts "thanks to the 'abinit-runtests' script."
      puts "Type 'abinit-runtests --help' to learn more."
      puts "Note that you need write access to #{share}/tests."
    else
      puts
      puts "ABINIT test suite is not available because it"
      puts "has not been activated at the installation stage."
      puts "Action: install with 'brew install abinit --with-testsuite'."
    end
  end
end
