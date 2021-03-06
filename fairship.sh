package: FairShip
version: master
source: https://github.com/PMunkes/FairShip
tag: master
requires:
  - generators
  - simulation
  - FairRoot
  - GENIE
  - PHOTOSPP
  - EvtGen
  - G4PY
build_requires:
  - googletest
incremental_recipe: |
  rsync -ar $SOURCEDIR/ $INSTALLROOT/
  make ${JOBS:+-j$JOBS}
  make test
  make install
  rsync -a $BUILDIR/bin $INSTALLROOT/
  #Get the current git hash
  cd $SOURCEDIR
  FAIRSHIP_HASH=$(git rev-parse HEAD)
  cd $BUILDDIR
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
  module load BASE/1.0                                                          \\
            ${GENIE_VERSION:+GENIE/$GENIE_VERSION-$GENIE_REVISION}              \\
            ${G4PY_VERSION:+G4PY/$G4PY_VERSION-$G4PY_REVISION}                  \\
            ${PHOTOSPP_VERSION:+PHOTOSPP/$PHOTOSPP_VERSION-$PHOTOSPP_REVISION}  \\
            ${EVTGEN_VERSION:+EvtGen/$EVTGEN_VERSION-$EVTGEN_REVISION}          \\
            FairRoot/$FAIRROOT_VERSION-$FAIRROOT_REVISION                       
  # Our environment
  setenv FAIRSHIP_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
  setenv FAIRSHIP \$::env(FAIRSHIP_ROOT)
  setenv FAIRSHIP_HASH $FAIRSHIP_HASH
  setenv VMCWORKDIR \$::env(FAIRSHIP)
  setenv GEOMPATH \$::env(FAIRSHIP)/geometry
  setenv CONFIG_DIR \$::env(FAIRSHIP)/gconfig
  prepend-path PATH \$::env(FAIRSHIP_ROOT)/bin
  prepend-path LD_LIBRARY_PATH \$::env(FAIRSHIP_ROOT)/lib
  setenv FAIRLIBDIR \$::env(FAIRSHIP_ROOT)/lib
  prepend-path ROOT_INCLUDE_PATH \$::env(FAIRSHIP_ROOT)/include
  prepend-path PYTHONPATH \$::env(FAIRSHIP_ROOT)/python
  append-path PYTHONPATH \$::env(FAIRSHIP_ROOT)/Developments/track_pattern_recognition
  $([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(FAIRSHIP_ROOT)/lib")
  EoF
---
#!/bin/sh

# Making sure people do not have SIMPATH set when they build fairroot.
# Unfortunately SIMPATH seems to be hardcoded in a bunch of places in
# fairroot, so this really should be cleaned up in FairRoot itself for
# maximum safety.
unset SIMPATH

case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
    [[ ! $ZEROMQ_ROOT ]] && ZEROMQ_ROOT=`brew --prefix zeromq`
    [[ ! $PROTOBUF_ROOT ]] && PROTOBUF_ROOT=`brew --prefix protobuf`
    [[ ! $NANOMSG_ROOT ]] && NANOMSG_ROOT=`brew --prefix nanomsg`
    [[ ! $GSL_ROOT ]] && GSL_ROOT=`brew --prefix gsl`
    SONAME=dylib
  ;;
  *) SONAME=so ;;
esac

rsync -a $SOURCEDIR/ $INSTALLROOT/

cmake $SOURCEDIR                                                 \
      -DFAIRBASE="$FAIRROOT_ROOT/share/fairbase"                 \
      -DFAIRROOTPATH="$FAIRROOT_ROOT"                            \
      -DCMAKE_CXX_FLAGS="$CXXFLAGS"                              \
      -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE                       \
      -DROOTSYS=$ROOTSYS                                         \
      -DROOT_CONFIG_SEARCHPATH=$ROOT_ROOT/bin                    \
      -DHEPMC_DIR=$HEPMC_ROOT                                    \
      -DHEPMC_INCLUDE_DIR=$HEPMC_ROOT/include/HepMC              \
      -DEVTGENPATH=$EVTGEN_ROOT                                  \
      -DEVTGEN_INCLUDE_DIR=$EVTGEN_ROOT/include/EvtGen           \
      -DPythia6_LIBRARY_DIR=$PYTHIA6_ROOT/lib                    \
      -DPYTHIA8_DIR=$PYTHIA_ROOT                                 \
      -DGEANT3_PATH=$GEANT3_ROOT                                 \
      -DGEANT3_LIB=$GEANT3_ROOT/lib                              \
      -DGEANT4_ROOT=$GEANT4_ROOT                                 \
      -DGEANT4_VMC_ROOT=$GEANT4_VMC_ROOT                         \
      -DVGM_ROOT=$VGM_ROOT                                       \
      -DGENIE_ROOT=$GENIE_ROOT                                   \
      -DLHAPDF5_ROOT="$LHAPDF5_ROOT/share/lhapdf"                \
      ${CMAKE_VERBOSE_MAKEFILE:+-DCMAKE_VERBOSE_MAKEFILE=ON}     \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                    \
      ${BOOST_ROOT:+-DBOOST_INCLUDEDIR=$BOOST_ROOT/include}      \
      ${BOOST_ROOT:+-DBOOST_LIBRARYDIR=$BOOST_ROOT/lib}          \
      ${BOOST_ROOT:+-DBoost_NO_SYSTEM=TRUE}                      \
      ${GSL_ROOT:+-DGSL_DIR=$GSL_ROOT}                           \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

make ${JOBS:+-j$JOBS}
make test
make install

rsync -a $BUILDIR/bin $INSTALLROOT/

#Get the current git hash
cd $SOURCEDIR
FAIRSHIP_HASH=$(git rev-parse HEAD)
cd $BUILDDIR

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
module load BASE/1.0                                                            \\
            ${GENIE_VERSION:+GENIE/$GENIE_VERSION-$GENIE_REVISION}              \\
            ${G4PY_VERSION:+G4PY/$G4PY_VERSION-$G4PY_REVISION}                  \\
            ${PHOTOSPP_VERSION:+PHOTOSPP/$PHOTOSPP_VERSION-$PHOTOSPP_REVISION}  \\
            ${EVTGEN_VERSION:+EvtGen/$EVTGEN_VERSION-$EVTGEN_REVISION}          \\
            FairRoot/$FAIRROOT_VERSION-$FAIRROOT_REVISION                       
# Our environment
setenv FAIRSHIP_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv FAIRSHIP \$::env(FAIRSHIP_ROOT)
setenv FAIRSHIP_HASH $FAIRSHIP_HASH
setenv VMCWORKDIR \$::env(FAIRSHIP)
setenv GEOMPATH \$::env(FAIRSHIP)/geometry
setenv CONFIG_DIR \$::env(FAIRSHIP)/gconfig
prepend-path PATH \$::env(FAIRSHIP_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(FAIRSHIP_ROOT)/lib
setenv FAIRLIBDIR \$::env(FAIRSHIP_ROOT)/lib
prepend-path ROOT_INCLUDE_PATH \$::env(FAIRSHIP_ROOT)/include
prepend-path PYTHONPATH \$::env(FAIRSHIP_ROOT)/python
append-path PYTHONPATH \$::env(FAIRSHIP_ROOT)/Developments/track_pattern_recognition
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(FAIRSHIP_ROOT)/lib")
EoF


