class NetcdfParallel < Formula
  # Adapted from official netcdf formula to use MPI I/O
  desc "Libraries and data formats for array-oriented scientific data (parallel version)"
  homepage "https://www.unidata.ucar.edu/software/netcdf/"
  url "https://downloads.unidata.ucar.edu/netcdf-c/4.9.3/netcdf-c-4.9.3.tar.gz"
  sha256 "a474149844e6144566673facf097fea253dc843c37bc0a7d3de047dc8adda5dd"
  license "BSD-3-Clause"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_tahoe: "bd09d992d55df9dd08d0ef257d0e49150602d5d067f8d80978b2ef35b15fbb6c"
    sha256 cellar: :any, arm64_sequoia: "380c8e704a087c5bc315290af2d01167c43424f2cafbe796e02588e83d329a8d"
    sha256 cellar: :any, arm64_sonoma: "562d2e9124f45c2bbb1ba41078e8ff78923392669a7158e69ce69cdd7e5fa515"
    sha256 cellar: :any, arm64_ventura: "667e43fd371fccb475d3aa066efe966664eb676442e9515c7ab586aa32a60d13"
    sha256 cellar: :any, arm64_monterey: "076a395c7a436bacb11210798e3ddc61536d7544c3af2091c312ae06ffb41e99"
    sha256 cellar: :any, tahoe: "9cbc85cd34cf59f5aa6dd33516e61b813fc80e5ae41e9cdc181184ec2819e282"
    sha256 cellar: :any, sequoia: "619da5c53e5effa813009eff9053ce7dd3590f10a7129bcd1d611472656e7cdf"
    sha256 cellar: :any, sonoma: "0d4502fdfad516bee185a19032eca6f2c85f2bb2403b75ee81d2bf23962cc8be"
    sha256 cellar: :any, ventura: "095bd8d201ce2fded42a8640e428cc6254a18e41d91d94b6eb73667a3c739f20"
    sha256 cellar: :any, monterey: "80aff1ffcbb54b121aa0a6288523cce788fb61ebde38c21f60ad00a08d4fcfdd"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "86c31ed9c9830a3e9e646124467f45d5179628d3f6942eb586b0b10c7193a1db"
  end

  keg_only "conflict with serial netcdf and pnetcdf packages"

  depends_on "cmake" => :build
  depends_on "open-mpi"
  depends_on "hdf5-parallel"

  uses_from_macos "m4" => :build
  uses_from_macos "bzip2"
  uses_from_macos "curl"
  uses_from_macos "libxml2"

  on_macos do
    depends_on "zstd"
  end

  def install

    args = std_cmake_args + %w[-DCMAKE_C_COMPILER=mpicc
                               -DCMAKE_CXX_COMPILER=mpicxx
                               -DBUILD_TESTING=OFF
                               -DENABLE_TESTS=OFF
                               -DENABLE_NETCDF_4=ON
                               -DENABLE_PARALLEL4=ON
                               -DENABLE_DOXYGEN=OFF]

    # Fixes wrong detection of hdf5-parallel
    args << "-DHDF5_ROOT=#{Formula["hdf5-parallel"].opt_prefix}"

    # Fixes "relocation R_X86_64_PC32 against symbol `stderr@@GLIBC_2.2.5' can not be used" on Linux
    args << "-DCMAKE_POSITION_INDEPENDENT_CODE=ON" if OS.linux?

    system "cmake", "-S", ".", "-B", "build_shared", *args, "-DBUILD_SHARED_LIBS=ON"
    system "cmake", "--build", "build_shared"
    system "cmake", "--install", "build_shared"
    system "cmake", "-S", ".", "-B", "build_static", *args, "-DBUILD_SHARED_LIBS=OFF"
    system "cmake", "--build", "build_static"
    lib.install "build_static/libnetcdf.a"

    # Remove shim paths
    #inreplace [bin/"nc-config", lib/"pkgconfig/netcdf.pc", lib/"cmake/netCDF/netCDFConfig.cmake",
    #           lib/"libnetcdf.settings"], Superenv.shims_path/ENV.cc, ENV.cc
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include "netcdf_meta.h"
      int main()
      {
        printf(NC_VERSION);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-I#{include}", "-lnetcdf",
                   "-o", "test"
    if head?
      assert_match(/^\d+(?:\.\d+)+/, `./test`)
    else
      assert_equal version.to_s, `./test`
    end
  end
end
