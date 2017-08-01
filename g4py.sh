package: G4PY
version: "%(tag_basename)s%(defaults_upper)s"
source: https://github.com/alisw/geant4
tag: v4.10.01.p03
requires:
  - GEANT4
  - Python-modules
  - ROOT
  - boost
  - XercesC
  - opengl
build_requires:
  - CMake
  - "Xcode:(osx.*)"
env:
  G4PYINSTALL: "$G4PY_ROOT"
---
#!/bin/bash -e
rsync -a $SOURCEDIR/environments/g4py/* $INSTALLROOT
source $GEANT4_ROOT/bin/geant4.sh
cmake $INSTALLROOT                               \
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}     \
      -DBoost_NO_SYSTEM_PATHS=TRUE               \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
      -DBOOST_ROOT=${BOOST_ROOT}                 \
      -DXERCESC_ROOT_DIR=${XERCESC_ROOT}         \
      -DBoost_NO_BOOST_CMAKE=TRUE

make  VERBOSE=1
make ${JOBS+-j $JOBS} install
ctest



# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ROOT/$ROOT_VERSION-$ROOT_REVISION ${GEANT4_VERSION:+GEANT4/$GEANT4_VERSION-$GEANT4_REVISION} XercesC/$XERCESC_VERSION-$XERCESC_REVISION boost/$BOOST_VERSION-$BOOST_REVISION
# Our environment
setenv G4PY_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv PYTHONPATH \$::env(G4PY_ROOT)/lib:\$::env(G4PY_ROOT)/lib/examples:\$::env(G4PY_ROOT)/lib/tests
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(G4PY_ROOT)/lib")
EoF
