#!/bin/bash -x

set -e

NCPUS=$1
ARCH=$2

echo "Arguments:"
echo "NCPUS: ${NCPUS}"
echo "ARCH: ${ARCH}"


# Install dependencies
apt-get install -y build-essential gcc-multilib g++-multilib libc6-dev wget libmpc-dev libgmp-dev libmpfr-dev 

# Download source
TMP=$(mktemp -d)
cd ${TMP}
wget https://mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-9.4.0/gcc-9.4.0.tar.gz
tar -xvzf gcc-9.4.0.tar.gz

# Configure
mkdir ${TMP}/gcc-build
cd ${TMP}/gcc-build

if [ "${ARCH}" == "arm32v7" ]; then
    ../gcc-9.4.0/configure --prefix=/usr \
                           --enable-languages=c,c++,lto \
                           --with-arch=armv7-a \
                           --with-fpu=vfpv3-d16 \
                           --with-float=hard \
                           --with-mode=thumb \
                           --disable-werror \
                           --enable-checking=yes \
                           --program-suffix=-9 \
                           --disable-bootstrap \
                           --disable-multilib \
                           --disable-docs \
                           --disable-nls
else
    ../gcc-9.4.0/configure --prefix=/usr \
                           --enable-languages=c,c++,lto \
                           --disable-werror \
                           --enable-checking=yes \
                           --program-suffix=-9 \
                           --disable-bootstrap \
                           --disable-multilib \
                           --disable-docs \
                           --disable-nls    
fi

# Build
make -j${NCPUS}

# Install
make -j${NCPUS} install

# Update alternatives for gcc and g++
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 50
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 50

