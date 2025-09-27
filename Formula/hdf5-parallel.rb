class Hdf5Parallel < Formula
  # Adapted from official hdf5 formula to use MPI I/O
  desc "File format designed to store large amounts of data (parallel version)"
  homepage "https://www.hdfgroup.org/HDF5"
  url "https://github.com/HDFGroup/hdf5/releases/download/hdf5_1.14.6/hdf5-1.14.6.tar.gz"
  sha256 "e4defbac30f50d64e1556374aa49e574417c9e72c6b1de7a4ff88c4b1bea6e9b"
  license "BSD-3-Clause"
  version_scheme 1

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_tahoe: "d504feb3c11e5c2d8563d124ccae881ba56c166a78ccfaffdac22063e95c2397"
    sha256 cellar: :any, arm64_sequoia: "f08dc1c534409794cf19c1aabe8b96f5e1f22b151064333f445f04566a08fdfc"
    sha256 cellar: :any, arm64_sonoma: "40bc0bc18ae42deba49dfaa964cfe21904604f73630fd2df6f79da1ffda55bb0"
    sha256 cellar: :any, arm64_ventura: "f145e2b4f43188462267feb03c8a8e3c703a72cd9ca1f2887a3910ab479d9762"
    sha256 cellar: :any, arm64_monterey: "c6d1a7404e402ea69f83339ccbab3a27f0c93c52f7c384c0a57e4faf61eea479"
    sha256 cellar: :any, tahoe: "87444b4719e9a92e4e372cc32105a5d2eef85900a4413fbd265f718b25779909"
    sha256 cellar: :any, sequoia: "014a4900e93d56e5bb48c55ca4705fe26cdccfc378d13c316c9ad977ee69ca04"
    sha256 cellar: :any, sonoma: "43f48c2fbc583bb799c77cdc503e83e5f5ed7d6bf6e4eded0159638c00082f6c"
    sha256 cellar: :any, ventura: "274ca4d08d40d8d72c52f85bc6aa3b5c56deedbabdb53be52d96c9a204077134"
    sha256 cellar: :any, monterey: "13930aa51ad0a010e27fd49fa9e2f61566a8f8cf072fe319ece21934209e3067"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "fbbfc7e293694e25dc3e36d1d3b8470c86a40d4d18c624a5badfcb328e7d23d9"
  end

  depends_on "cmake" => :build
  depends_on "gcc" # for gfortran
  depends_on "libaec"
  depends_on "pkgconf"
  depends_on "open-mpi"

  uses_from_macos "zlib"

  keg_only "conflict with serial hdf5 and hdf5-mpi packages"

  def install
    args = %w[
      -DHDF5_USE_GNU_DIRS:BOOL=ON
      -DHDF5_INSTALL_CMAKE_DIR=lib/cmake/hdf5
      -DHDF5_BUILD_FORTRAN:BOOL=ON
      -DHDF5_BUILD_CPP_LIB:BOOL=ON
      -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=ON
      -DHDF5_ENABLE_PARALLEL:BOOL=ON
      -DHDF5_BUILD_CPP_LIB:BOOL=OFF
      -DHDF5_BUILD_FORTRAN:BOOL=ON
      -DCMAKE_C_COMPILER=mpicc
      -DCMAKE_CXX_COMPILER=mpic++
      -DCMAKE_Fortran_COMPILER=mpif90
    ]

    # https://github.com/HDFGroup/hdf5/issues/4310
    args << "-DHDF5_ENABLE_NONSTANDARD_FEATURE_FLOAT16:BOOL=OFF"

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args

    # Avoid c shims in settings files
    inreplace_c_files = %w[
      build/src/H5build_settings.c
      build/src/libhdf5.settings
      build/CMakeFiles/h5pcc
      build/CMakeFiles/h5cc
      build/CMakeFiles/h5hlcc
    ]
    #inreplace inreplace_c_files, Superenv.shims_path/ENV.cc, ENV.cc

    # Avoid cpp shims in settings files
    inreplace_cxx_files = %w[
      build/CMakeFiles/h5c++
      build/CMakeFiles/h5hlc++
    ]
    inreplace_cxx_files << "build/src/libhdf5.settings" if OS.linux?
    #inreplace inreplace_cxx_files, Superenv.shims_path/ENV.cxx, ENV.cxx

    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include "hdf5.h"
      int main()
      {
        printf("%d.%d.%d\\n", H5_VERS_MAJOR, H5_VERS_MINOR, H5_VERS_RELEASE);
        return 0;
      }
    C
    system "#{bin}/h5pcc", "test.c"
    assert_equal version.major_minor_patch.to_s, shell_output("./a.out").chomp

    (testpath/"test.f90").write <<~FORTRAN
      use hdf5
      integer(hid_t) :: f, dspace, dset
      integer(hsize_t), dimension(2) :: dims = [2, 2]
      integer :: error = 0, major, minor, rel

      call h5open_f (error)
      if (error /= 0) call abort
      call h5fcreate_f ("test.h5", H5F_ACC_TRUNC_F, f, error)
      if (error /= 0) call abort
      call h5screate_simple_f (2, dims, dspace, error)
      if (error /= 0) call abort
      call h5dcreate_f (f, "data", H5T_NATIVE_INTEGER, dspace, dset, error)
      if (error /= 0) call abort
      call h5dclose_f (dset, error)
      if (error /= 0) call abort
      call h5sclose_f (dspace, error)
      if (error /= 0) call abort
      call h5fclose_f (f, error)
      if (error /= 0) call abort
      call h5close_f (error)
      if (error /= 0) call abort
      CALL h5get_libversion_f (major, minor, rel, error)
      if (error /= 0) call abort
      write (*,"(I0,'.',I0,'.',I0)") major, minor, rel
      end
    FORTRAN
    system "#{bin}/h5pfc", "test.f90"
    assert_equal version.major_minor_patch.to_s, shell_output("./a.out").chomp

    # Make sure that it was built with SZIP/libaec
    config = shell_output("#{bin}/h5pcc -showconfig")
    assert_match %r{I/O filters.*DECODE}, config
  end
end
