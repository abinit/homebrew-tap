class NetcdfFortranParallel < Formula
  # Adapted from official netcdf-fortran formula to use MPI I/O
  desc "Fortran libraries and utilities for NetCDF (parallel version)"
  homepage "https://www.unidata.ucar.edu/software/netcdf/"
  url "https://downloads.unidata.ucar.edu/netcdf-fortran/4.6.0/netcdf-fortran-4.6.0.tar.gz"
  sha256 "198bff6534cc85a121adc9e12f1c4bc53406c403bda331775a1291509e7b2f23"
  license "BSD-3-Clause"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_ventura: "5ba4e9193279b18c7b37ebfef7ba2c2a107c8b6bbde5d6fd6fb52186126707d8"
    sha256 cellar: :any, arm64_monterey: "95489a49e4a1bfb787704215b48e29e0c75862a1fab1a7a5a714a5822733b1a8"
    sha256 cellar: :any, ventura: "6b44b8e952287231a9577f75d8f9700f02ab9564ac867249e18e1cb537148ab0"
    sha256 cellar: :any, monterey: "2c1c9dbc0c4ad5dffbf0115333fa24eacc2aba0f9e94da1c728048f7cf25a857"
    sha256 cellar: :any, big_sur: "7cc9397e430794a40b123a3e3e06725959bc2a1476dccb1564ed31f97722ccda"
    sha256 cellar: :any, catalina: "51570e22d4c9b2a2cdd88980d7d1371a5a273959675cf09460e9d2e304814a84"
    sha256 cellar: :any, mojave: "04bd56a9fd1885b7232a53205a60a63ba0510e3e9631e59afca4e8e810928234"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "3976552b903a1bdfb5fbb8c334eabee7f224c6e86aa234ee1a31df47113110dc"
  end

  keg_only "conflict with serial netcdf-fortran packages"

  depends_on "cmake" => :build
  depends_on "gcc" # for gfortran
  depends_on "hdf5-parallel"
  depends_on "netcdf-parallel"

  def install
    ENV["OMPI_CXX"] = ENV["CXX"]
    ENV["CXX"] = "mpicxx"
    ENV["OMPI_CC"] = ENV["CC"]
    ENV["CC"] = "mpicc"
    ENV["OMPI_FC"] = "gfortran"
    ENV["FC"] = "mpifort"

    args = std_cmake_args + %w[-DBUILD_TESTING=OFF -DENABLE_TESTS=OFF -DENABLE_NETCDF_4=ON
                               -DENABLE_PARALLEL4=ON -DENABLE_DOXYGEN=OFF]

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
