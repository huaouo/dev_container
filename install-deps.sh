#!/bin/bash

set -e

PREFIX=/usr/local/mapd-deps

apt -y update
apt -y install \
    software-properties-common \
    build-essential \
    ccache \
    cmake \
    cmake-curses-gui \
    git \
    wget \
    curl \
    gcc-8 \
    g++-8 \
    libboost-all-dev \
    libgoogle-glog-dev \
    golang \
    libssl-dev \
    libevent-dev \
    default-jre \
    default-jre-headless \
    default-jdk \
    default-jdk-headless \
    maven \
    libncurses5-dev \
    libldap2-dev \
    binutils-dev \
    google-perftools \
    libdouble-conversion-dev \
    libevent-dev \
    libgflags-dev \
    libgoogle-perftools-dev \
    libiberty-dev \
    libjemalloc-dev \
    libglu1-mesa-dev \
    liblz4-dev \
    liblzma-dev \
    libbz2-dev \
    libarchive-dev \
    libcurl4-openssl-dev \
    libedit-dev \
    uuid-dev \
    libsnappy-dev \
    zlib1g-dev \
    autoconf \
    autoconf-archive \
    automake \
    bison \
    flex-old \
    libpng-dev \
    rsync \
    unzip \
    jq \
    python-dev \
    python-yaml \
    swig \
    libxerces-c-dev \
    libxmlsec1-dev

sudo update-alternatives \
  --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-8      

mkdir -p $PREFIX
pushd $PREFIX
tar xvf /mapd-deps.tar.xz
rm -f mapd-deps.tar.xz
popd

cat << EOF | sudo tee -a $PREFIX/mapd-deps.sh
PREFIX=$PREFIX
LD_LIBRARY_PATH=/usr/local/cuda/lib64:\$LD_LIBRARY_PATH
LD_LIBRARY_PATH=\$PREFIX/lib:\$LD_LIBRARY_PATH
LD_LIBRARY_PATH=\$PREFIX/lib64:\$LD_LIBRARY_PATH
PATH=/usr/local/cuda/bin:\$PATH
PATH=\$PREFIX/bin:\$PATH
VULKAN_SDK=\$PREFIX
VK_LAYER_PATH=\$PREFIX/etc/vulkan/explicit_layer.d
CMAKE_PREFIX_PATH=\$PREFIX:\$CMAKE_PREFIX_PATH
export LD_LIBRARY_PATH PATH VULKAN_SDK VK_LAYER_PATH CMAKE_PREFIX_PATH
EOF

PROFPATH=/etc/profile.d/xx-mapd-deps.sh
ln -sf $PREFIX/mapd-deps.sh $PROFPATH
echo "Done. A file at $PROFPATH has been created and will be run on startup"
echo "Source this file or reboot to load vars in this shell"
