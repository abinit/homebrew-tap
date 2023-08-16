#!/bin/sh
 
QAGATE_PREFIX=$(brew --prefix qagate 2>/dev/null)
QAGATE_TOOLS_PREFIX=$(brew --repository)/Library/Taps/abinit/homebrew-tap/Casks/tools
QT_PREFIX=$(brew --prefix qt 2>/dev/null)

if [ ! -d "${QAGATE_PREFIX}" ]; then
  echo "qagate homebrew formula not found, stopping now!"
  exit 1
fi
if [ ! -d "${QAGATE_TOOLS_PREFIX}" ]; then
  echo "qagate tools not found in abinit tap, stopping now!"
  exit 1
fi
if [ ! -d "${QT_PREFIX}" ]; then
  echo "Qt homebrew formula not found, stopping now!"
  exit 1
fi

cd ${QAGATE_PREFIX}/bin

echo "\n==============================================="
echo "== Changing permissions"
chmod u+w qAgate.app/Contents/MacOS/qAgate

echo "\n==============================================="
echo "== Executing macdeployqt\n"
${QT_PREFIX}/bin/macdeployqt qAgate.app

echo "\n==============================================="
echo "== Executing macdeployqt_fix\n"
python3 ${QAGATE_TOOLS_PREFIX}/my_macdeployqt_fix.py qAgate.app/Contents/MacOS/qAgate $(brew --prefix qt)

echo "\n==============================================="
echo "== Copying missing file(s)"
cp ${QT_PREFIX}/share/qt/plugins/imageformats/libqsvg.dylib \
   qAgate.app/Contents/PlugIns/imageformats

echo "\n==============================================="
echo "== Creating DMG\n"
rm -rf qAgate.dmg
${QT_PREFIX}/bin/macdeployqt qAgate.app -dmg

echo "\nqAgate.dmg created in "${QAGATE_PREFIX}"/bin"

