class Wannier90 < Formula
  desc "Software that computes maximally-localised Wannier functions (MLWFs)"
  homepage "http://www.wannier.org/"
  url "https://github.com/wannier-developers/wannier90/archive/v3.1.0.tar.gz"
  sha256 "40651a9832eb93dec20a8360dd535262c261c34e13c41b6755fa6915c936b254"
  #doi:10.1088/1361-648X/ab51ff

  bottle do
    root_url "http://forge.abinit.org/homebrew"
    cellar :any
    sha256 "dd048b79f858881d95e562c641941922977e82350f8fd465a93d5228158a6b73" => :catalina
    sha256 "422c90304167b01b41f28f49023f873f820fb954d116cdbd52b18153cc104092" => :mojave
    sha256 "0597673252b1205daf986905f26e7c6186f43062a5c5d6ae3539e21d5b662421" => :high_sierra
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
      inreplace "make.inc", "-L/usr/local/opt/openblas/lib -lblas -llapack", "-L#{Formula["veclibfort"].opt_lib} -lvecLibFort"
      inreplace "make.inc", "FCOPTS=-O2", "FCOPTS=-fallow-argument-mismatch -O2"
    end
    system "make", "all"
    system "make", "install", "PREFIX=#{prefix}"
    cd "#{lib}"
    ln_s "libwannier.a", "libwannier90.a", force: true
  end
  test do
    system "#{bin}/wannier90.x", "examples/example01/gaas"
  end
end
