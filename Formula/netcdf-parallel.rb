class NetcdfParallel < Formula
  # Adapted from official netcdf formula to use MPI I/O
  desc "Libraries and data formats for array-oriented scientific data (parallel version)"
  homepage "https://www.unidata.ucar.edu/software/netcdf/"
  url "https://downloads.unidata.ucar.edu/netcdf-c/4.9.0/netcdf-c-4.9.0.tar.gz"
  sha256 "4c956022b79c08e5e14eee8df51b13c28e6121c2b7e7faadc21b375949400b49"
  license "BSD-3-Clause"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, monterey: "4abdfdaba729e964cd5b03cca50e1c6a2e65fcd227fdcc4ae4c9af017eeb9f5e"
    sha256 cellar: :any, big_sur:  "a81d741c8fdc3d1e87c14e66fc4abf60c7062a7fd2f35757fa4e0508eb9b6664"
    sha256 cellar: :any, catalina: "fde7b705aad243a43d27adc52f0184676bf4c27fb87e699af0f0a24121f441a4"
    sha256 cellar: :any, mojave:   "3f9da4ce165431d8e641d953e55ffde590e8b530678f02fafd098a0efc5ebb6c"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "0abbec9b071718943fdbb07f75bbb94d62387c9df6f24bf41c2e702955c93615"
  end

  keg_only "conflict with serial netcdf and pnetcdf packages"

  depends_on "cmake" => :build
  depends_on "open-mpi"
  depends_on "hdf5-parallel"

  uses_from_macos "curl"

  # Patch for JSON collision. Remove in 4.9.1
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/1383fd8c15feb09c942665601d58fba3d6d5348f/netcdf/netcdf-json.diff"
    sha256 "6a5183dc734509986713a00451d7f98c5ab2e00ab0df749027067b0880fa9e92"
  end

  def install
    ENV["OMPI_CXX"] = ENV["CXX"]
    ENV["CXX"] = "mpicxx"
    ENV["OMPI_CC"] = ENV["CC"]
    ENV["CC"] = "mpicc"
    ENV["OMPI_FC"] = "gfortran"
    ENV["FC"] = "mpifort"

    # Remove when this is resolved: https://github.com/Unidata/netcdf-c/issues/2390
    inreplace "CMakeLists.txt", "SET(netCDF_LIB_VERSION 19})", "SET(netCDF_LIB_VERSION 19)"

    args = std_cmake_args + %w[-DBUILD_TESTING=OFF -DENABLE_TESTS=OFF -DENABLE_NETCDF_4=ON -DENABLE_PARALLEL4=ON -DENABLE_DOXYGEN=OFF]
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
