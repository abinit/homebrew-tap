class Wannier90 < Formula
  desc "Software that computes maximally-localised Wannier functions (MLWFs)"
  homepage "http://www.wannier.org/"
  url "https://github.com/wannier-developers/wannier90/archive/v3.1.0.tar.gz"
  sha256 "40651a9832eb93dec20a8360dd535262c261c34e13c41b6755fa6915c936b254"
  # doi:10.1088/1361-648X/ab51ff

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_tahoe: "514671227f230b7355d3a336c3821e3e0f1af4c5e485e57b6bd5436d6d4b7273"
    sha256 cellar: :any, arm64_sequoia: "64d71fc05b0f88461e2fe17e1ca5d8f2c9f46c109d7507dec8ce4453272c95b5"
    sha256 cellar: :any, arm64_sonoma: "d55103fb2f2d17cb3edfe7896856d010acad57b380acc02e39a3ace395d38be6"
    sha256 cellar: :any, arm64_ventura: "e9b92ad5a3b95f71b819b12ba16dfe38c2d5a487c95bcf0d2ea385008bf6e8da"
    sha256 cellar: :any, arm64_monterey: "8eca70f6ec6ea4f56dc7cd4430b587b1d974cb743d17b3b3a2e415d32d5a208e"
    sha256 cellar: :any, tahoe: "b4848e4147dbcff144bd3ed494be91628278dc9809e34a9fa8c6eacc3675ee7d"
    sha256 cellar: :any, sequoia: "1cd1f34e9bc3a2b6bc0fbb2f5428575d30e89e497f3e7a8e74876941882ec800"
    sha256 cellar: :any, sonoma: "016695f52e88cec7c4ba458cd151bceba9b17f96fedd4272454e3aeaa284be75"
    sha256 cellar: :any, ventura: "8d139e74331fe5fa7af8174ebf71193c247c22c493101d9e6de5aa7ec32a90a9"
    sha256 cellar: :any, monterey: "e66c2b1fd78ef87dd935dc6422b2c51de375e44155c5a3691761d0a3f07f0379"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "f978a911a0573809b45d14e9c20c9e01c19f72d06ca53597af97cc9d5a93c413"
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
