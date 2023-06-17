class Wannier90 < Formula
  desc "Software that computes maximally-localised Wannier functions (MLWFs)"
  homepage "http://www.wannier.org/"
  url "https://github.com/wannier-developers/wannier90/archive/v3.1.0.tar.gz"
  sha256 "40651a9832eb93dec20a8360dd535262c261c34e13c41b6755fa6915c936b254"
  # doi:10.1088/1361-648X/ab51ff

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    sha256 cellar: :any, arm64_ventura: "8decb652d6fdbc243fb46a529e3d54ad528d0b0d402d99f2d27a8c2941da645b"
    sha256 cellar: :any, arm64_monterey: "74c52952ecfe6a34777f98c287f558909ba18d2450182a46de20895e885df655"
    sha256 cellar: :any, ventura: "5ecf8a16f61846a77f072367d0cfeb0a8011a3afd7751299bd2ec9703ada9c52"
    sha256 cellar: :any, monterey: "a86350f5a0a5bbe875dc9548c56f90a1bb084d31f45c9ad4932d4a551a672247"
    sha256 cellar: :any, big_sur: "6815690d4b715ad2652c645a1ff0151650ec35028e527240baec730679a9c8ed"
    sha256 cellar: :any, catalina: "b7904b6722691f06e7029137cb6236806f783dd56090b4912639e9e20f2ed837"
    sha256 cellar: :any, mojave: "048d6346310ad682f2d1bad03d5603238228cdbc174cd0d398fe69986c1b0b7d"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "1576151ce1227a520262489586f3aa0b3eb26c2ab378f488f6f81ae13779f5c5"
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
