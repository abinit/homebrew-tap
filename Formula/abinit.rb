class Abinit < Formula
  desc "Atomic-scale first-principles simulation software"
  homepage "https://www.abinit.org/"
  url "https://www.abinit.org/sites/default/files/packages/abinit-9.8.2.tar.gz"
  sha256 "63be31cc8e9cb99e4b2d82be15c37e7a36512437d17c7d37f44042d6fec7c9bc"
  license "GPL-3.0-only"
  revision 1

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_ventura: "db26da5df2bdb749d4bad150f165dcf46f12624ae2f23145c79cbb469b5edf49"
    sha256 cellar: :any, arm64_monterey: "1b76e1e059db45d16798d965f76b00d5fff26b6f9c6cc426d51a48473a5104be"
    sha256 cellar: :any, ventura: "f9ca1c6c8dd81c1680999b0ff66c0c32c21507b24927f952ef7217532cafff76"
    sha256 cellar: :any, monterey: "63eb6b663f144827ceffdd5a3fc56753946454220e780beee51b9aca6a0efaf8"
    sha256 cellar: :any, big_sur: "f0fcf9b6967cdeaa93b40eda9d723360ae73a8a9ab2d02336232a7632ba5f46a"
    sha256 cellar: :any, catalina: "fb4600c4495d3f7004b4d917b21722fa33b6b94eabf32c00644da50dc81eef93"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "753caa49dc219ae52eec7601a7cf01f25c573db64a56c8066104a690ac9ea615"
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

  # Abinit 9.8 needs to be patched with gcc13 (in m_gwls_GenerateEpsilon.F90)
  patch :DATA

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
    # Workaround to compile with gcc10+
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

__END__
diff --git a/src/70_gw/m_gwls_GenerateEpsilon.F90 b/src/70_gw/m_gwls_GenerateEpsilon.F90
index 2ea0f6c..70772ed 100644
--- a/src/70_gw/m_gwls_GenerateEpsilon.F90
+++ b/src/70_gw/m_gwls_GenerateEpsilon.F90
@@ -156,7 +156,7 @@ end subroutine driver_generate_dielectric_matrix
 !!
 !! SOURCE
 
-subroutine GeneratePrintDielectricEigenvalues(epsilon_matrix_function,kmax,output_filename,Lbasis,alpha,beta)
+subroutine GeneratePrintDielectricEigenvalues(epsilon_matrix_function,nseeds,kmax,output_filename,Lbasis,alpha,beta)
 !----------------------------------------------------------------------
 ! This routine computes the Lanczos approximate representation of the
 ! implicit dielectic operator and then diagonalizes the banded
@@ -173,7 +173,7 @@ interface
   end subroutine epsilon_matrix_function
 end interface
 
-integer,       intent(in) :: kmax
+integer,       intent(in) :: nseeds,kmax
 
 character(*),  intent(in) :: output_filename
 
@@ -456,7 +456,7 @@ call set_dielectric_function_frequency([zero,zero])
 
 call cpu_time(time1)
 output_filename = 'EIGENVALUES_EXACT.dat'
-call GeneratePrintDielectricEigenvalues(matrix_function_epsilon_k, kmax_exact, &
+call GeneratePrintDielectricEigenvalues(matrix_function_epsilon_k, nseeds, kmax_exact, &
 output_filename, Lbasis_exact, alpha_exact, beta_exact)
 
 
@@ -471,7 +471,7 @@ call write_timing_log(timing_string,time)
 call cpu_time(time1)
 call setup_Pk_model(zero,second_model_parameter)
 output_filename = 'EIGENVALUES_MODEL.dat'
-call GeneratePrintDielectricEigenvalues(matrix_function_epsilon_model_operator, kmax_model, output_filename,&
+call GeneratePrintDielectricEigenvalues(matrix_function_epsilon_model_operator, nseeds, kmax_model, output_filename,&
 Lbasis_model, alpha_model, beta_model)
 call cpu_time(time2)
 time = time2-time1
