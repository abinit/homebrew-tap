class Hdf5Parallel < Formula
  desc "File format designed to store large amounts of data (parallel version)"
  homepage "https://www.hdfgroup.org/HDF5"
  url "https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-1.12.1/src/hdf5-1.12.1.tar.bz2"
  sha256 "aaf9f532b3eda83d3d3adc9f8b40a9b763152218fa45349c3bc77502ca1f8f1c"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any,                 arm64_big_sur: "608cbbf899a3b260ddf5ec573a4297ef91f2ccb44ab75ee7ef67852741b9e418"
    sha256 cellar: :any,                 big_sur:       "b49763e7edc8c7b75a11f37695f8096c51d47955742229e5e1169eea267d5be7"
    sha256 cellar: :any,                 catalina:      "54e5e204601606f4bbbc7adaf9029dfe549aba420083073f59cd4d3ee551c0ad"
    sha256 cellar: :any,                 mojave:        "344fa9795ddb0f6568570b9e51b1bd757f6f204fe18f6f507690cb649bb3bb2e"
    sha256 cellar: :any,                 high_sierra:   "e029225d21b02445de7a9105d16a81b83dff99e48441548aa27a50f18b870c9f"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "340898157149969c31710530b7f823bfbf7f6d6c7057b236ad1284ad1c8658c2"
  end

  keg_only "conflict with serial hdf5 package"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "gcc" # for gfortran
  depends_on "open-mpi"
  depends_on "szip"

  uses_from_macos "zlib"

  def install
    ENV["OMPI_CXX"] = ENV["CXX"]
    ENV["CXX"] = "mpicxx"
    ENV["OMPI_CC"] = ENV["CC"]
    ENV["CC"] = "mpicc"
    ENV["OMPI_FC"] = "gfortran"
    ENV["FC"] = "mpifort"

    inreplace %w[c++/src/h5c++.in fortran/src/h5fc.in bin/h5cc.in],
      "${libdir}/libhdf5.settings",
      "#{pkgshare}/libhdf5.settings"

    inreplace "src/Makefile.am",
              "settingsdir=$(libdir)",
              "settingsdir=#{pkgshare}"

    system "autoreconf", "-fiv"

    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --with-szlib=#{Formula["szip"].opt_prefix}
      --enable-build-mode=production
      --enable-fortran
      --enable-cxx
      --enable-unsupported
      --enable-parallel
    ]

    system "./configure", *args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <stdio.h>
      #include "hdf5.h"
      int main()
      {
        printf("%d.%d.%d\\n", H5_VERS_MAJOR, H5_VERS_MINOR, H5_VERS_RELEASE);
        return 0;
      }
    EOS
    system "#{bin}/h5cc", "test.c"
    assert_equal version.to_s, shell_output("./a.out").chomp

    (testpath/"test.f90").write <<~EOS
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
    EOS
    system "#{bin}/h5fc", "test.f90"
    assert_equal version.to_s, shell_output("./a.out").chomp
  end
end
