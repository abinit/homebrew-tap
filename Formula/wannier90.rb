class Wannier90 < Formula
  desc "Software that computes maximally-localised Wannier functions (MLWFs)"
  homepage "http://www.wannier.org/"
  url "https://github.com/wannier-developers/wannier90/archive/v3.1.0.tar.gz"
  sha256 "40651a9832eb93dec20a8360dd535262c261c34e13c41b6755fa6915c936b254"
  # doi:10.1088/1361-648X/ab51ff

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any,                 arm64_big_sur: "d47a6a22c439fa659aeb70f7cef70f3e1636d6fad1456cb51313e13bd6fab251"
    sha256 cellar: :any,                 monterey:      "f24230479e42240f815975f6757dbd1990d0f3bbbfcb7134fcc7843ec610b4f3"
    sha256 cellar: :any,                 big_sur:       "2efe9e5a390412e58d8a2be4841bce41738067c859ed5717c42aceed137e9362"
    sha256 cellar: :any,                 catalina:      "a23dbf46956f3b7d5932988fb6d8b918e821dc8349b2839cceeec35b1d0fb5df"
    sha256 cellar: :any,                 mojave:        "1443b162052525b9000c9b210e1c969df0310b55aa13ee65b9f43f410e05e84c"
    sha256 cellar: :any,                 high_sierra:   "bacb585c45ef6c8f6b45243812c6d7063d30f5ed7db6cceaca7b73c1963ba70a"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "af509c98f1357c0fa7220293e5f1378e52b28793780074c235f1106b659d4e1c"
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
