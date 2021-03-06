#!/bin/bash

set -eux

name="ecbuild"
repo=${1:-${STACK_ecbuild_repo:-"jcsda"}}
version=${2:-${STACK_ecbuild_version:-"release-stable"}}

if $MODULES; then
  set +x
  source $MODULESHOME/init/bash
  module try-load cmake
  module list
  set -x

  prefix="${PREFIX:-"/opt/modules"}/core/$name/$repo-$version"
  if [[ -d $prefix ]]; then
    [[ $OVERWRITE =~ [yYtT] ]] && ( echo "WARNING: $prefix EXISTS: OVERWRITING!"; $SUDO rm -rf $prefix; $SUDO mkdir $prefix ) \
                               || ( echo "WARNING: $prefix EXISTS, SKIPPING"; exit 1 )
  fi
else
  prefix=${ECBUILD_ROOT:-"/usr/local"}
fi

software=$name-$repo-$version
cd ${HPC_STACK_ROOT}/${PKGDIR:-"pkg"}
[[ -d $software ]] || git clone https://github.com/$repo/$name.git $software
[[ -d $software ]] && cd $software || ( echo "$software does not exist, ABORT!"; exit 1 )
git fetch --tags
git checkout $version
[[ ${DOWNLOAD_ONLY} =~ [yYtT] ]] && exit 0
[[ -d build ]] && $SUDO rm -rf build
mkdir -p build && cd build

cmake -DCMAKE_INSTALL_PREFIX=$prefix ..
VERBOSE=$MAKE_VERBOSE make -j${NTHREADS:-4}
VERBOSE=$MAKE_VERBOSE $SUDO make install

# generate modulefile from template
$MODULES && update_modules core $name $repo-$version \
         || echo $name $repo-$version >> ${HPC_STACK_ROOT}/hpc-stack-contents.log
