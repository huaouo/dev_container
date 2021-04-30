#!/bin/bash

set -e

PREFIX=/usr/local/mapd-deps

apt update -y
apt install -y \
    software-properties-common \
    build-essential \
    ccache \
    git \
    curl \
    g++-8 \
    libboost-all-dev \
    libgoogle-glog-dev \
    libssl-dev \
    libevent-dev \
    openjdk-8-jdk-headless \
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
    flex \
    libpng-dev \
    rsync \
    unzip \
    jq \
    python-dev \
    python-yaml \
    swig \
    pkg-config \
    libxerces-c-dev \
    libxmlsec1-dev

sudo update-alternatives \
  --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-8      

PROFPATH=/etc/profile.d/xx-mapd-deps.sh
ln -sf $PREFIX/mapd-deps.sh $PROFPATH
echo "Done. A file at $PROFPATH has been created and will be run on startup"
echo "Source this file or reboot to load vars in this shell"
