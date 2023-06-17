class Hdf5Parallel < Formula
  # Adapted from official hdf5 formula to use MPI I/O
  desc "File format designed to store large amounts of data (parallel version)"
  homepage "https://www.hdfgroup.org/HDF5"
  url "https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.14/hdf5-1.14.1/src/hdf5-1.14.1-2.tar.bz2"
  version "1.14.1"
  sha256 "06ca141d1a3c312b5d7cc4826a12737293ae131031748861689f6a2ec8219dbd"
  license "BSD-3-Clause"
  version_scheme 1

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_ventura: "4b4377ae8dfc99acc2c1a2569f8b7adc5c82b7f7991aeb2f1a9cbd643a8d18c0"
    sha256 cellar: :any, arm64_monterey: "c4cb08c9c3f5ff91e13f9e897f34d6b0efa719ce98120d4f51361c5207a403ea"
    sha256 cellar: :any, ventura: "efef5a40db67c107dc3f97d359c8e6ae879694fe9fda522bb9b71f63f6b57717"
    sha256 cellar: :any, monterey: "fb23ff1d4e33e30c57b4e1568e320a31c8e90a8d074cfb9a0d2ed75cc6045bd4"
    sha256 cellar: :any, big_sur: "454ba67e6a4a77dae38bf3bdf3fcda13e54527abf40b1db1154f02de665be8fe"
    sha256 cellar: :any, catalina: "43c6b59fbde52c4f28e8feb6b86b11de2dc0f08966b4b18e70acdfbb674ef5ea"
    sha256 cellar: :any, mojave: "402cec82f3908ab530db88e47e031758657e230c1edfd95100368228015b8ca0"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "593f90c3a7727d5a4a12b65e9df394de203d8c5f99188de9832407b34cc82f9d"
  end

  keg_only "conflict with serial hdf5 and hdf5-mpi packages"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "gcc" # for gfortran
  depends_on "libaec"
  depends_on "open-mpi"

  uses_from_macos "zlib"

  def install
    inreplace %w[c++/src/h5c++.in fortran/src/h5fc.in bin/h5cc.in],
              "${libdir}/libhdf5.settings",
              "#{pkgshare}/libhdf5.settings"

    inreplace "src/Makefile.am",
              "settingsdir=$(libdir)",
              "settingsdir=#{pkgshare}"

    if OS.mac?
      system "autoreconf", "--force", "--install", "--verbose"
    else
      system "./autogen.sh"
    end

    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --enable-build-mode=production
      --enable-fortran
      --enable-parallel
      --prefix=#{prefix}
      --with-szlib=#{Formula["libaec"].opt_prefix}
      CC=mpicc
      CXX=mpic++
      FC=mpifort
      F77=mpif77
      F90=mpif90
    ]
    args << "--with-zlib=#{Formula["zlib"].opt_prefix}" if OS.linux?

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
    system "#{bin}/h5pcc", "test.c"
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
    system "#{bin}/h5pfc", "test.f90"
    assert_equal version.to_s, shell_output("./a.out").chomp
  end
end
