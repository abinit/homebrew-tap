class Wannier90 < Formula
  desc "Software that computes maximally-localised Wannier functions (MLWFs)"
  homepage "http://www.wannier.org/"
  url "https://github.com/wannier-developers/wannier90/archive/v3.1.0.tar.gz"
  sha256 "40651a9832eb93dec20a8360dd535262c261c34e13c41b6755fa6915c936b254"
  # doi:10.1088/1361-648X/ab51ff

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_sequoia: "58f601d4c2dfbc652e286aef315f1d42f44813a4bde73612e724731f9b34f1d6"
    sha256 cellar: :any, arm64_sonoma: "d66b9d7aacf21299e0eed6e790b429b45a4c6d2aeccd9822be38adab442d398e"
    sha256 cellar: :any, arm64_monterey: "7fd98a631af65046836ed8dce48b0c1268bb9527f8273e0a1f9804902ad6b4cf"
    sha256 cellar: :any, arm64_ventura: "07b2ec165b4e1537d6c6d92f5f77e6ffeefe1b4eafcda2ce6b603c17ad256a2d"
    sha256 cellar: :any, sequoia: "5df1401bd1d1c8306ac5cd070dc125eb425623be6ab74d68eed5407a68115e16"
    sha256 cellar: :any, sonoma: "784dc801ec06ba745d387886d6503dd37d74115be37c90ff6bc0129c73b482e6"
    sha256 cellar: :any, monterey: "3ed0079cd1934c28d8de88a8b204e62aeca478b83830983f58ad3aa30bbbd788"
    sha256 cellar: :any, ventura: "b9bcd7b1321ae3a8adc72fd744889126d048dbbe1161d4ec43953c1036e56a23"
    sha256 cellar: :any, big_sur: "080e4c2843a1e93b613a269ad043bc757fd3be1e93676494b36f7a8083d231f7"
    sha256 cellar: :any, catalina: "8455fa4e142912667f1814e1c04cafcd8a09f927d47161cf7ce714da49a663f1"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "dc3031d7b198de6b2b8b78f2d8f8e2fcadc5ea3aae676ab8c3fc23848d0e0ad0"
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
