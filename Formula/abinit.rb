class Abinit < Formula
  desc "Atomic-scale first-principles simulation software"
  homepage "https://www.abinit.org/"
  url "https://www.abinit.org/sites/default/files/packages/abinit-8.10.3.tar.gz"
  sha256 "ed626424b4472b93256622fbb9c7645fa3ffb693d4b444b07d488771ea7eaa75"
  # tag "chemistry"
  # doi "10.1016/j.cpc.2016.04.003"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    cellar :any
    sha256 "0b02d4ff91cb2b4672d1acf5f708f899bcd1e036a873f3685280b92e7f18c4e0" => :mojave
  end

  option "without-openmp", "Disable OpenMP multithreading"
  option "without-test", "Skip build-time tests (not recommended)"
  option "with-testsuite", "Run full test suite (time consuming)"

  depends_on "gcc" if OS.mac? # for gfortran
  depends_on "open-mpi"
  depends_on "fftw" => :recommended
  depends_on "netcdf" => :recommended
  depends_on "libxc" => :recommended
  if OS.mac?
    depends_on "veclibfort"
    depends_on "scalapack" => :recommended
  end

  needs :openmp if build.with? "openmp"

# From libxc3 to libXC4
  patch do
    url "https://github.com/abinit/homebrew-tap/raw/master/Formula/libxc_3to4_patch.diff"
    sha256 "ede1f6b5ab75c94fe29084443d245f1d934d896d0ac64825ef3a15214f83a7f9"
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
      cd "tests"
      if build.with? "testsuite"
        system "./runtests.py 2>&1 | tee make-check.log"
      else
        system "./runtests.py built-in fast 2>&1 | tee make-check.log"
      end
      ohai `grep ", succeeded:" "make-check.log"`.chomp
      prefix.install "make-check.log"
      cd ".."
    end

    system "make", "install"
  end

  test do
    system "#{bin}/abinit", "-b"
  end
end
