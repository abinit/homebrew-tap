#WARNING: THIS FORMULA IS NOT COMPLETE: THERE IS STILL WORK TO PORT IT TO Qt6 !!! 
class Qagate < Formula
  desc "Qt interface for agate"
  homepage "https://github.com/piti-diablotin/qAgate"
  url "https://github.com/piti-diablotin/qAgate/releases/download/v1.2.3/qAgate1.2.3.tar.gz"
  sha256 "104a21533d20dd5ee61bb08278ea946aec2f7a1742a00490540bda10df26d02f"
  license "GPL-3.0"
  revision 1

  depends_on "agate" => :build
  depends_on "freetype" => :build
  depends_on "libssh" => :build
  depends_on "qt" => :build

  def install

    # Adapt to homebrew location
    if OS.mac?
      inreplace "qAgate.pro", "/usr/local", "#{HOMEBREW_PREFIX}"
    end

    # For Retina displays, need to use the pixel ratio
    inreplace "gui/view.cpp", "_width = width;", "_width = width * devicePixelRatio();"
    inreplace "gui/view.cpp", "_height = height;", "_height = height * devicePixelRatio();"

    # Fixes for Qt6 compatibility
    inreplace "qAgate.pro", "core gui opengl network", "core gui openglwidgets network core5compat"
    inreplace "qAgate.pro", "QT_DEPRECATED_WARNING", "QT_DEPRECATED_WARNING QT_DISABLE_DEPRECATED_BEFORE=0x060000"

    inreplace "tabs/multibinittab.cpp", "QRegExpValidator", "QRegularExpressionValidator"
    inreplace "qtdep/qtdepoptions.cpp", "QRegExpValidator", "QRegularExpressionValidator"
    inreplace "qdispersion/qdispersion.h", "QRegExpValidator", "QRegularExpressionValidator"
    inreplace "gui/view.h", "QRegExpValidator", "QRegularExpressionValidator"
    inreplace "dialogs/remotedialog.h", "QRegExpValidator", "QRegularExpressionValidator"

    inreplace "gui/view.cpp", "->delta()", "->angleDelta().y()"
    inreplace "tabs/visuals.cpp", "itemData(newPos)>data", "itemData(newPos).toInt()>data.toInt()"

    inreplace "tabs/visuals.cpp", "QVector<int>::fromStdVector(znucl)", "QVector<int>(znucl.begin(), znucl.end())"
    inreplace "tabs/home.cpp", "QVector<int>::fromStdVector(view->getCanvas()->histdata()->znucl())",
              "QVector<int>(view->getCanvas()->histdata()->znucl().begin(), view->getCanvas()->histdata()->znucl().end())"
    inreplace "tools/qplot.cpp", "QVector<double>::fromStdVector(x)", "QVector<double>(x.begin(), x.end())"
    inreplace "tools/qplot.cpp", "QVector<double>::fromStdVector(*yp)", "QVector<double>(yp->begin(), yp->end())"
    inreplace "tools/qplot.cpp", "QVector<double>::fromStdVector(xyp->first)", "QVector<double>(xyp->first.begin(), xyp->first.end())"
    inreplace "tools/qplot.cpp", "QVector<double>::fromStdVector(xyp->second)", "QVector<double>(xyp->second.begin(), xyp->second.end())"


    inreplace "dialogs/straindialog.cpp", "QRegExp", "QRegularExpression"
    inreplace "dialogs/straindialog.cpp", "#include <QMessageBox>", "#include <QMessageBox>\n#include <QRegularExpression>"
    inreplace "gui/view.cpp", "QRegExp", "QRegularExpression"
    inreplace "gui/view.cpp", "#include <QMessageBox>", "#include <QMessageBox>\n#include <QRegularExpression>"
    inreplace "dialogs/polarizationdialog.cpp", "QRegExp", "QRegularExpression"
    inreplace "dialogs/polarizationdialog.cpp", "#include <QMessageBox>", "#include <QMessageBox>\n#include <QRegularExpression>"
    inreplace "tabs/home.cpp", "QRegExp", "QRegularExpression"
    inreplace "tabs/home.cpp", "#include <QFileDialog>", "#include <QFileDialog>\n#include <QRegularExpression>"
    inreplace "tools/qplot.cpp", "QRegExp", "QRegularExpression"
    inreplace "tools/qplot.cpp", "#include <QFileDialog>", "#include <QFileDialog>\n#include <QRegularExpression>"


#   WARNING: THIS FORMULA IS NOT COMPLETE: THERE IS STILL WORK TO PORT IT TO Qt6 !!! 


    system "lrelease", "qAgate.pro"

    system "qmake", "PREFIX=#{prefix}",
                    "PREFIX_AGATE=#{Formula["agate"].opt_prefix}",
                    "PREFIX_FREETYPE=#{Formula["freetype"].opt_prefix}",
                    "PREFIX_SSH=#{Formula["libssh"].opt_prefix}",
                    "qAgate.pro"

    system "make", "install"
  end

end
