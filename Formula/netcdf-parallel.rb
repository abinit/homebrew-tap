class NetcdfParallel < Formula
  # Adapted from official netcdf formula to use MPI I/O
  desc "Libraries and data formats for array-oriented scientific data (parallel version)"
  homepage "https://www.unidata.ucar.edu/software/netcdf/"
  url "https://downloads.unidata.ucar.edu/netcdf-c/4.9.2/netcdf-c-4.9.2.tar.gz"
  sha256 "cf11babbbdb9963f09f55079e0b019f6d0371f52f8e1264a5ba8e9fdab1a6c48"
  license "BSD-3-Clause"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_ventura: "9286e9d7d7881cb7b67811379f567743b8df9db831eb3a5215fc8cea3683f72e"
    sha256 cellar: :any, arm64_monterey: "cdda03fbeee4ab945c9b16ccef14e722cef55b8a61bdc8c59b40bc8b5fc60e4c"
    sha256 cellar: :any, ventura: "4ed2493e9550980f52f1f3827baca0e383c94d6c66460fa85c2072d124b05f47"
    sha256 cellar: :any, monterey: "9ae52ec2e28fec161856e57e59c827e2e64350f4f7d7b0778600b9e160421d2e"
    sha256 cellar: :any, big_sur: "29000b7f0b71cde4ab7847361e1f55eb22acdca87e0ef75042587cae23e3f4ba"
    sha256 cellar: :any, catalina: "7abc6c12dbc38170bb13c755a92e36a142f11cdf52495908f9a7aeb62cabc611"
    sha256 cellar: :any, mojave: "edfc54d98407b2c7d4771d7d2ef7c534e7b9a445c91909001e13857e6f9a43cd"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "9bc8585dda051c46d8bb6d0c9f29d557cdc5812d6fef84f4edf64b8bb59e29b6"
  end

  keg_only "conflict with serial netcdf and pnetcdf packages"

  depends_on "cmake" => :build
  depends_on "open-mpi"
  depends_on "hdf5-parallel"

  uses_from_macos "curl"
  uses_from_macos "libxml2"

  def install

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
