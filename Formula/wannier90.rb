class Wannier90 < Formula
  desc "Software that computes maximally-localised Wannier functions (MLWFs)"
  homepage "http://www.wannier.org/"
  url "https://github.com/wannier-developers/wannier90/archive/v3.1.0.tar.gz"
  sha256 "40651a9832eb93dec20a8360dd535262c261c34e13c41b6755fa6915c936b254"
  # doi:10.1088/1361-648X/ab51ff

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_ventura: "e9997c660ef844f35bef5c977e8edf7b1e8ebd17067536ffaa817afbf9ced9ec"
    sha256 cellar: :any, arm64_monterey: "79dd49d93368462786d73cdb8fe1e4a4e0e32792ba1b6b500f24e68d5db7dfd3"
    sha256 cellar: :any, ventura: "6695737c4fcd9b92658d1f010e9e467c22c3af48771bc86e18c8dad676df8be6"
    sha256 cellar: :any, monterey: "9dcc613fc0c2324971f205890958f6de79e2a0ecd375fbb7209c8f3f9faf45c6"
    sha256 cellar: :any, big_sur:  "a338c8e588efc51ee47ad71814db68f7960f23b2d311820ae82ef904289ff8ab"
    sha256 cellar: :any, catalina: "d013a742180fc4b4d0f64813bfab07f36fd5f6928d9f707669ba10a430f99420"
    sha256 cellar: :any, mojave:   "3e1d9777cb9ee5b974ad8a15feb1735c5173b40212fa3bd147f8a7c0560250fe"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "1fb5fd48394e112699daef8c314cb5080506ce66c27897922d908b051aff83d5"
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
