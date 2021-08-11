class Hdf5Parallel < Formula
  desc "File format designed to store large amounts of data (parallel version)"
  homepage "https://www.hdfgroup.org/HDF5"
  url "https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-1.12.0/src/hdf5-1.12.0.tar.bz2"
  sha256 "97906268640a6e9ce0cde703d5a71c9ac3092eded729591279bf2e3ca9765f61"

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, big_sur:     "2fb7328f4b08fe154e2cebd915e11b5876aa8772976bf26b3edae680182b2eb9"
    sha256 cellar: :any, catalina:    "a5a34d1a09a3d796635c97fd51dda34cfba04fcdd4ddaf1be3052d1cd5d115f8"
    sha256 cellar: :any, mojave:      "af69e8c6dcb4e9b4c108b0de434253a71ffeb17f8f1337f572c7c57d8f6159f8"
    sha256 cellar: :any, high_sierra: "44f1ca7c4c452970aadc8a1d786c47e7c5dab616cd92d8721154461330125c32"
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
