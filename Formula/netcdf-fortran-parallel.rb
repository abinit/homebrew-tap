class NetcdfFortranParallel < Formula
  # Adapted from official netcdf-fortran formula to use MPI I/O
  desc "Fortran libraries and utilities for NetCDF (parallel version)"
  homepage "https://www.unidata.ucar.edu/software/netcdf/"
  url "https://downloads.unidata.ucar.edu/netcdf-fortran/4.6.1/netcdf-fortran-4.6.1.tar.gz"
  sha256 "b50b0c72b8b16b140201a020936aa8aeda5c79cf265c55160986cd637807a37a"
  license "NetCDF"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_ventura: "55dddbf2b653f243cbe61377314bae52384a0ff6bbd67658d3fc53c096c91507"
    sha256 cellar: :any, arm64_monterey: "658b6bf45526c7fd72731adde052c4d6dd5377656535530c749e75a12398a963"
    sha256 cellar: :any, ventura: "2f9d0be493e7fb148a486611f3f4c042ff1521d833ce034b514749b002cea8ce"
    sha256 cellar: :any, monterey: "f2f06355798b3c96afbd467158f9d6c0ca817632f06157e6510d539f9a6bb601"
    sha256 cellar: :any, big_sur: "fee671911bfd5912d9aceeeb4e30da62880e5a2e68480c28ba64a2a87da0a949"
    sha256 cellar: :any, catalina: "e2fdde0b0277917d08f63230ad2d1894c8e064d8ba8128df9c79b935bf423284"
    sha256 cellar: :any, mojave: "390775ad8b9f3acb4cd067ef340c3195f118cd6064ddbfced915bdea89460f2a"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "3278f6a97f57f87b9bd203d0e20ee76f70dee57e074ebef822a56b1f8f7a5c9b"
  end

  keg_only "conflict with serial netcdf-fortran packages"

  depends_on "cmake" => :build
  depends_on "gcc" # for gfortran
  depends_on "hdf5-parallel"
  depends_on "netcdf-parallel"

  def install

   args = std_cmake_args + %w[-DCMAKE_Fortran_COMPILER=mpifort
                              -DCMAKE_C_COMPILER=mpicc
                              -DCMAKE_CXX_COMPILER=mpicxx
                              -DBUILD_TESTING=OFF
                              -DENABLE_TESTS=OFF
                              -DENABLE_NETCDF_4=ON
                              -DENABLE_PARALLEL4=ON
                              -DENABLE_DOXYGEN=OFF]

    system "cmake", "-S", ".", "-B", "build_shared", *args, "-DBUILD_SHARED_LIBS=ON"
    system "cmake", "--build", "build_shared"
    system "cmake", "--install", "build_shared"

    system "cmake", "-S", ".", "-B", "build_static", *args, "-DBUILD_SHARED_LIBS=OFF"
    system "cmake", "--build", "build_static"
    lib.install "build_static/fortran/libnetcdff.a"

  end

  test do
    (testpath/"test.f90").write <<~EOS
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
    EOS
    system "gfortran", "test.f90", "-L#{lib}", "-I#{include}", "-lnetcdff",
                       "-o", "testf"
    system "./testf"
  end
end
