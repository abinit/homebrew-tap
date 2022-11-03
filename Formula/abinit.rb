class Abinit < Formula
  desc "Atomic-scale first-principles simulation software"
  homepage "https://www.abinit.org/"
  url "https://www.abinit.org/sites/default/files/packages/abinit-9.6.2.tar.gz"
  sha256 "b018c2ff24338a5952c5550a7e09d4c7793b62402c7aa4e09273e9a666e674fb"
  license "GPL-3.0-only"
  revision 1

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_ventura: "425d45b2b75c1adc0297dbf81b2320ec892aaeb59368e7520106e8df3aca8874"
    sha256 cellar: :any, arm64_monterey: "0a2b36680348c83154f3324088c54ea8ec1a160a5b39071be771be56f143d6ad"
    sha256 cellar: :any, ventura: "4af42a7e8e0d8f270f7d54f60360160f61266bf56e0c7f5d36184cb624f7dda4"
    sha256 cellar: :any, monterey: "4653470fb09c84c6dcb3dfb4d9b3e3420a13143513d1a740e970f3aa120da042"
    sha256 cellar: :any, big_sur:  "104d9c81e034a07652c7776295e41b3b8896ae65c770b0020211d97812cf6df2"
    sha256 cellar: :any, catalina: "01a8feef2a647e6e7cec205e53126943a6f192297cd86207ef3673ed2f954141"
    sha256 cellar: :any, mojave: "6e0315cca6ba01c94dd8b3b08823687aed1f8686f8d05bb528e03d6b9bd32fef"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "007ba5962207a147daa6881f8acad6f28771f5170e5f4fcf25eaf0a5aeb2dfc0"
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

  # From libxc5 to libXC6 (to be suppressed for 9.8+)
  patch do
    url "https://github.com/abinit/homebrew-tap/raw/master/Formula/libxc_5to6_patch.diff"
    sha256 "31b270eef51ddfd77b8a7169d993592dc4a73c4273699847ca49cf3fe58dd940"
  end

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
    compilers << "FCFLAGS_EXTRA=-fallow-argument-mismatch -Wno-missing-include-dirs"

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
      test_file.puts "SHAREDIR=\`brew --cellar\`\"/#{name}/#{ver}/share\""
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
