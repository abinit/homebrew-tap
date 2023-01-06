class NetcdfParallel < Formula
  # Adapted from official netcdf formula to use MPI I/O
  desc "Libraries and data formats for array-oriented scientific data (parallel version)"
  homepage "https://www.unidata.ucar.edu/software/netcdf/"
  url "https://downloads.unidata.ucar.edu/netcdf-c/4.9.0/netcdf-c-4.9.0.tar.gz"
  sha256 "4c956022b79c08e5e14eee8df51b13c28e6121c2b7e7faadc21b375949400b49"
  license "BSD-3-Clause"
  revision 1

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_ventura: "e0bee312197fcde04755a6f0408f74f934d7056c33457eda18f3c8dec7183f99"
    sha256 cellar: :any, arm64_monterey: "e64e1c4ed569069aa9d1ba94cae998b59fd0474c6b0673a9a4b1ef76e2dfc5ca"
    sha256 cellar: :any, ventura: "267ead3d9268b2d6dfae55cc7d7246ae1f8b6431e4debe84f7734d7f26a16b6b"
    sha256 cellar: :any, monterey: "9bcabcca67e2f86f5d4b5415a3a1e4c9de45437148105f00e5df3cc05409ddf9"
    sha256 cellar: :any, big_sur: "8169253be51992dc983cfd52a6f81a11b6d386bad039462fd685e4a7d336593d"
    sha256 cellar: :any, catalina: "666c989aec6ede1161da2e5e13c64906307055367f97f4c5c226b0fb9f5d7e57"
    sha256 cellar: :any, mojave: "45e7ff821d2207011d3a1b960dda7549959c22f67c1d138f43f6e50933d22e92"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "ca76cbe121d1ab50ded133b2629b93df8cb49ff3c1ea2f13a2399c1511a25fe6"
  end

  keg_only "conflict with serial netcdf and pnetcdf packages"

  depends_on "cmake" => :build
  depends_on "open-mpi"
  depends_on "hdf5-parallel"

  uses_from_macos "curl"
  uses_from_macos "libxml2"

  # Patch for JSON collision. Remove in 4.9.1
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/1383fd8c15feb09c942665601d58fba3d6d5348f/netcdf/netcdf-json.diff"
    sha256 "6a5183dc734509986713a00451d7f98c5ab2e00ab0df749027067b0880fa9e92"
  end

  def install

    # Remove when this is resolved: https://github.com/Unidata/netcdf-c/issues/2390
    inreplace "CMakeLists.txt", "SET(netCDF_LIB_VERSION 19})", "SET(netCDF_LIB_VERSION 19)"

    args = std_cmake_args + %w[-DCMAKE_Fortran_COMPILER=mpifort
                               -DCMAKE_C_COMPILER=mpicc
                               -DCMAKE_CXX_COMPILER=mpicxx
                               -DBUILD_TESTING=OFF
                               -DENABLE_TESTS=OFF
                               -DENABLE_NETCDF_4=ON
                               -DENABLE_PARALLEL4=ON
                               -DENABLE_DOXYGEN=OFF]

    # Fixes "relocation R_X86_64_PC32 against symbol `stderr@@GLIBC_2.2.5' can not be used" on Linux
    args << "-DCMAKE_POSITION_INDEPENDENT_CODE=ON" if OS.linux?

    system "cmake", "-S", ".", "-B", "build_shared", *args, "-DBUILD_SHARED_LIBS=ON"
    system "cmake", "--build", "build_shared"
    system "cmake", "--install", "build_shared"
    system "cmake", "-S", ".", "-B", "build_static", *args, "-DBUILD_SHARED_LIBS=OFF"
    system "cmake", "--build", "build_static"
    lib.install "build_static/liblib/libnetcdf.a"

    # Remove shim paths
    #inreplace [bin/"nc-config", lib/"pkgconfig/netcdf.pc", lib/"cmake/netCDF/netCDFConfig.cmake",
    #           lib/"libnetcdf.settings"], Superenv.shims_path/ENV.cc, ENV.cc
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <stdio.h>
      #include "netcdf_meta.h"
      int main()
      {
        printf(NC_VERSION);
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-L#{lib}", "-I#{include}", "-lnetcdf",
                   "-o", "test"
    if head?
      assert_match(/^\d+(?:\.\d+)+/, `./test`)
    else
      assert_equal version.to_s, `./test`
    end
  end
end
