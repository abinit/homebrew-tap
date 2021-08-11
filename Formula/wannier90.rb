class Wannier90 < Formula
  desc "Software that computes maximally-localised Wannier functions (MLWFs)"
  homepage "http://www.wannier.org/"
  url "https://github.com/wannier-developers/wannier90/archive/v3.1.0.tar.gz"
  sha256 "40651a9832eb93dec20a8360dd535262c261c34e13c41b6755fa6915c936b254"
  # doi:10.1088/1361-648X/ab51ff

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, big_sur:     "2efe9e5a390412e58d8a2be4841bce41738067c859ed5717c42aceed137e9362"
    sha256 cellar: :any, catalina:    "a23dbf46956f3b7d5932988fb6d8b918e821dc8349b2839cceeec35b1d0fb5df"
    sha256 cellar: :any, mojave:      "1443b162052525b9000c9b210e1c969df0310b55aa13ee65b9f43f410e05e84c"
    sha256 cellar: :any, high_sierra: "bacb585c45ef6c8f6b45243812c6d7063d30f5ed7db6cceaca7b73c1963ba70a"
  end

  option "without-test", "Skip build-time quick tests (not recommended)"
  depends_on "gcc" if OS.mac? # for gfortran
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
      inreplace "make.inc", "FCOPTS=-O2", "FCOPTS=-fallow-argument-mismatch -O2"
    end
    system "make", "all"
    system "make", "install", "PREFIX=#{prefix}"
    cd lib.to_s
    ln_s "libwannier.a", "libwannier90.a", force: true
  end
  test do
    system "#{bin}/wannier90.x", "examples/example01/gaas"
  end
end
