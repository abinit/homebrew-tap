class NetcdfFortranParallel < Formula
  # Adapted from official netcdf-fortran formula to use MPI I/O
  desc "Fortran libraries and utilities for NetCDF (parallel version)"
  homepage "https://www.unidata.ucar.edu/software/netcdf/"
  url "https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.6.2.tar.gz"
  sha256 "44cc7b5626b0b054a8503b8fe7c1b0ac4e0a79a69dad792c212454906a9224ca"
  license "NetCDF"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_tahoe: "156e6f38c8829754cdaed7cff1a2af66f7c32526754cb12f0873c14891f90d61"
    sha256 cellar: :any, arm64_sequoia: "080d9c424f6d93041d4475f189abfd4bcfa646b28f66bb3b31e288701fd3f716"
    sha256 cellar: :any, arm64_sonoma: "7b107a5dcb15ca15bbb11a0bdb0b81160afc29889ce4a28f67407674b3026c70"
    sha256 cellar: :any, arm64_ventura: "1868fd48057e89d45c2df08e85ef8a2198cba005e638efb9a0fb9753ba960ae5"
    sha256 cellar: :any, arm64_monterey: "8fed2165df2cc2f9c33de0a1be7d3279a85e693a6c2658abe2d749c6171b1e85"
    sha256 cellar: :any, tahoe: "fd15450f51be9dc980e42947ceb8446a14e425373a396389e4bee6604ff3cb7e"
    sha256 cellar: :any, sequoia: "dca5a4d7873f5863ce447a075160ad54383ad0a805c4dbbf7669307e10772206"
    sha256 cellar: :any, sonoma: "a7b2fa85edfda2c865a038654428e9f1cb911594d9580aab85866b9b9abba5ca"
    sha256 cellar: :any, ventura: "b2413e50309b24b97057e33e2312b6c1bab2939fdeb7e8c4d3ae8e9850a74ca3"
    sha256 cellar: :any, monterey: "1eaffe34a410ff26a35343488a01977ca783190829643fa0531c722f8b7fb63d"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "6bdf2591152f710809aae6165a4ab968138e69a8ebbbe666bbbc5917f8e1410e"
  end

  keg_only "conflict with serial netcdf-fortran packages"

  depends_on "cmake" => :build
  depends_on "gcc" # for gfortran
  depends_on "hdf5-parallel"
  depends_on "netcdf-parallel"

  def install

   args = std_cmake_args + %w[-DCMAKE_Fortran_COMPILER=mpifort
                              -DCMAKE_C_COMPILER=mpicc
                              -DBUILD_TESTING=OFF
                              -DENABLE_TESTS=OFF
                              -DENABLE_NETCDF_4=ON
                              -DENABLE_DOXYGEN=OFF]

    # Fixes wrong detection of netcdf-parallel
    args << "-DNETCDF_ROOT=#{Formula["netcdf-parallel"].opt_prefix}"

    system "cmake", "-S", ".", "-B", "build_shared", *args, "-DBUILD_SHARED_LIBS=ON"
    system "cmake", "--build", "build_shared"
    system "cmake", "--install", "build_shared"

    system "cmake", "-S", ".", "-B", "build_static", *args, "-DBUILD_SHARED_LIBS=OFF"
    system "cmake", "--build", "build_static"
    lib.install "build_static/fortran/libnetcdff.a"

    # Remove shim paths
    #inreplace [bin/"nf-config", lib/"libnetcdff.settings", lib/"pkgconfig/netcdf-fortran.pc"],
    #  Superenv.shims_path/ENV.cc, ENV.cc
  end

  test do
    (testpath/"test.f90").write <<~FORTRAN
      program test
        use netcdf
        integer :: ncid, varid, dimids(2)
        integer :: dat(2,2) = reshape([1, 2, 3, 4], [2, 2])
        call check( nf90_create("test.nc", NF90_CLOBBER, ncid) )
        call check( nf90_def_dim(ncid, "x", 2, dimids(2)) )
        call check( nf90_def_dim(ncid, "y", 2, dimids(1)) )
        call check( nf90_def_var(ncid, "data", NF90_INT, dimids, varid) )
        call check( nf90_enddef(ncid) )
        call check( nf90_put_var(ncid, varid, dat) )
        call check( nf90_close(ncid) )
      contains
        subroutine check(status)
          integer, intent(in) :: status
          if (status /= nf90_noerr) call abort
        end subroutine check
      end program test
    FORTRAN
    system "gfortran", "test.f90", "-L#{lib}", "-I#{include}", "-lnetcdff",
                       "-o", "testf"
    system "./testf"
  end
end
