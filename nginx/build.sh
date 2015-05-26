#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

export TMPDIR=/tmp
export TMP=/tmp
NAME=nginx
VERSION=1.8.0
ROOT=/opt/syncloud-platform
PREFIX=${ROOT}/${NAME}

apt-get -y install build-essential flex bison libreadline-dev zlib1g-dev libpcre3-dev

rm -rf build
mkdir -p build
cd build

wget http://nginx.org/download/${NAME}-${VERSION}.tar.gz
tar xzf ${NAME}-${VERSION}.tar.gz
cd ${NAME}-${VERSION}
./configure --prefix=${PREFIX}
make
rm -rf ${PREFIX}
make install
cd ..

tar czf ${NAME}-${VERSION}.tar.gz -C ${ROOT} ${NAME}

cd ..