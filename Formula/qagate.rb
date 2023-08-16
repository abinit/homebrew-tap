class Qagate < Formula
  desc "Qt interface for agate"
  homepage "https://github.com/piti-diablotin/qAgate"
  url "https://github.com/piti-diablotin/qAgate/releases/download/v1.3.0/qAgate1.3.0.tar.gz"
  sha256 "46b63d120adb67fcc0c7379309bf330020404b98d48369d346af2458a66c2c40"
  license "GPL-3.0"

  depends_on "agate" => :build
  depends_on "qt" => :build

  def install

    # Adapt to homebrew location
    inreplace "qAgate.pro", "/usr/local", "#{HOMEBREW_PREFIX}"

    system "lrelease", "qAgate.pro"

    system "qmake",
           "PREFIX=#{prefix}",
           "PREFIX_AGATE=#{Formula["agate"].opt_prefix}",
           "qAgate.pro"

    system "make", "install"
  end

end
