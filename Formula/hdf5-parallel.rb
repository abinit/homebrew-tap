class Hdf5Parallel < Formula
  # Adapted from official hdf5 formula to use MPI I/O
  desc "File format designed to store large amounts of data (parallel version)"
  homepage "https://www.hdfgroup.org/HDF5"
  url "https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-1.12.2/src/hdf5-1.12.2.tar.bz2"
  sha256 "1a88bbe36213a2cea0c8397201a459643e7155c9dc91e062675b3fb07ee38afe"
  license "BSD-3-Clause"
  revision 1
  version_scheme 1

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_ventura: "4d27d6d83d44e2cbfe02876f2f8181c704db30e57192fe8f2d6e6d0009789da8"
    sha256 cellar: :any, arm64_monterey: "f808f924fe69d94380c9f871ff98db83a8dfa56d07c19d8f0ff1b74c9595a921"
    sha256 cellar: :any, ventura: "0d5144fb1e19ae7907fb99ee5a70e412eb412e769e6a91656ebc451a061c2134"
    sha256 cellar: :any, monterey: "b043dfe2090b9781c026ef20c7a75e5e5d5a1cc6c6ede471c2bf75329c7c9855"
    sha256 cellar: :any, big_sur: "a37cf1abbf372af6ddc719e0ff997202c26d2a5a12944390287d33df0e82eea6"
    sha256 cellar: :any, catalina: "183ebc7ac14aa5a5cbd1883eb31d25a67ad374f99206d1f94f4e0c8bf5ceb76b"
    sha256 cellar: :any, mojave: "88ff6ff213079b907f2f991f8837ef76b35102ee2caf5ce9b3df200728237fa7"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "664d602a721289bb3ddf43169631c28ddb262c3290e5029f5554d71f4aca5810"
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
