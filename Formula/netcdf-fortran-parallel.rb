class NetcdfFortranParallel < Formula
  # Adapted from official netcdf-fortran formula to use MPI I/O
  desc "Fortran libraries and utilities for NetCDF (parallel version)"
  homepage "https://www.unidata.ucar.edu/software/netcdf/"
  url "https://downloads.unidata.ucar.edu/netcdf-fortran/4.6.0/netcdf-fortran-4.6.0.tar.gz"
  sha256 "198bff6534cc85a121adc9e12f1c4bc53406c403bda331775a1291509e7b2f23"
  license "BSD-3-Clause"
  revision 1

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_ventura: "c5cc27bf78f5432b597655f213bee641a1f73392b5a63bdfb47bdd5028d87fe6"
    sha256 cellar: :any, arm64_monterey: "a5c0b44f9fe741895d2d2c0a164dee86095a23edc87a334af6a1693825f2d95d"
    sha256 cellar: :any, ventura: "39fd198694c084b95db73b18a818b9c136cc7052a7eee563aaa8d49621d8075b"
    sha256 cellar: :any, monterey: "a01ef08872f3a624919ad9c63e4c4197a553b47027b273b154963bd245231667"
    sha256 cellar: :any, big_sur: "83b0170c87fd37ab3a2db190a350db17a0c59c46a0a16ba28ffef29d5b967824"
    sha256 cellar: :any, catalina: "ee107175b883e77fcb08f411b95c5dfd32af1fd77a22c576f8056be25e943af0"
    sha256 cellar: :any, mojave: "f5fa69d70c436bfce9fbf638ef4a14cb1bf1929777e0f5a9dc2fa4f3f2c97628"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "7651d1cf3cc7aa4dd2a1b3bbe58a1187ea077158d7758a93662b66d0d139e962"
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

    # Remove shim paths
    # inreplace [bin/"nf-config", lib/"libnetcdff.settings", lib/"pkgconfig/netcdf-fortran.pc"],
    #  Superenv.shims_path/ENV.cc, ENV.cc
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
