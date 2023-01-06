class Wannier90 < Formula
  desc "Software that computes maximally-localised Wannier functions (MLWFs)"
  homepage "http://www.wannier.org/"
  url "https://github.com/wannier-developers/wannier90/archive/v3.1.0.tar.gz"
  sha256 "40651a9832eb93dec20a8360dd535262c261c34e13c41b6755fa6915c936b254"
  # doi:10.1088/1361-648X/ab51ff

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_ventura: "0d443ea09aad0a6536a23a8419cef244851ada152ee4022e54c010a40cbaf4bb"
    sha256 cellar: :any, arm64_monterey: "d8e2ad699d838264f789e204091988df3a4330064694e0de6ecb5c0af6acddde"
    sha256 cellar: :any, ventura: "1e8fea5fca837e937e5e70136fce3f7e65705c48a2f90914d0c71ff038952128"
    sha256 cellar: :any, monterey: "de90a7b02e48446133e879442afd7d9b3d10dab3e34b4efe5ebd07637e40f2d0"
    sha256 cellar: :any, big_sur: "333cfed412a67f5ddace66869e0582d01edd60f5cd59d9bcc159636c99946646"
    sha256 cellar: :any, catalina: "0b3a5828f44c38f299fb2dfa137891a536b4cd446860888c24fa12ab514dc063"
    sha256 cellar: :any, mojave: "4a1d6f4eee84c813527713f0a2940de3cf74a47130e11db06c25508cdaa551b4"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "8e4abdcd43ea702853dd86711f5257560b832b1ab2cbaee048d26aa22131267e"
  end

  option "without-test", "Skip build-time quick tests (not recommended)"
  depends_on "gcc"
  depends_on "open-mpi"
  if OS.mac?
    depends_on "veclibfort"
  else
    depends_on "openblas"
  end

  def install
    cp "config/make.inc.macosx.homebrew", "make.inc"
    if OS.mac?
      inreplace "make.inc", "-L/usr/local/opt/openblas/lib -lblas -llapack",
"-L#{Formula["veclibfort"].opt_lib} -lvecLibFort"
    end
    inreplace "make.inc", "FCOPTS=-O2", "FCOPTS=-fallow-argument-mismatch -O2"
    system "make", "all"
    system "make", "install", "PREFIX=#{prefix}"
    cd lib.to_s
    ln_s "libwannier.a", "libwannier90.a", force: true
  end
  test do
    system "#{bin}/wannier90.x", "examples/example01/gaas"
  end
end
