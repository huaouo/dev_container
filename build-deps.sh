#!/usr/bin/env bash

set -e
set -x

HTTP_DEPS="https://dependencies.mapd.com/thirdparty"

PREFIX=/usr/local/mapd-deps

SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ARROW_TSAN=""

function download() {
    wget --continue "$1"
}

function extract() {
    tar xvf "$1"
}

function makej() {
  os=$(uname)
  if [ "$os" = "Darwin" ]; then
    nproc=$(sysctl -n hw.ncpu)
  else
    nproc=$(nproc)
  fi
  make -j ${nproc:-8}
}

function make_install() {
  # sudo is needed on osx
  os=$(uname)
  if [ "$os" = "Darwin" ]; then
    sudo make install
  else
    make install
  fi
}

function download_make_install() {
    name="$(basename $1)"
    download "$1"
    extract $name
    if [ -z "$2" ]; then
        pushd ${name%%.tar*}
    else
        pushd $2
    fi

    if [ -x ./Configure ]; then
        ./Configure --prefix=$PREFIX $3
    else
        ./configure --prefix=$PREFIX $3
    fi
    makej
    make_install
    popd
}

CMAKE_VERSION=3.16.5

function install_cmake() {
  CXXFLAGS="-pthread" CFLAGS="-pthread" download_make_install ${HTTP_DEPS}/cmake-${CMAKE_VERSION}.tar.gz
}

ARROW_VERSION=apache-arrow-1.0.0

function install_arrow() {
  download https://github.com/apache/arrow/archive/$ARROW_VERSION.tar.gz
  extract $ARROW_VERSION.tar.gz

  mkdir -p arrow-$ARROW_VERSION/cpp/build
  pushd arrow-$ARROW_VERSION/cpp/build
  cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DARROW_BUILD_SHARED=ON \
    -DARROW_BUILD_STATIC=ON \
    -DARROW_BUILD_TESTS=OFF \
    -DARROW_BUILD_BENCHMARKS=OFF \
    -DARROW_CSV=ON \
    -DARROW_JSON=ON \
    -DARROW_WITH_BROTLI=BUNDLED \
    -DARROW_WITH_ZLIB=BUNDLED \
    -DARROW_WITH_LZ4=BUNDLED \
    -DARROW_WITH_SNAPPY=BUNDLED \
    -DARROW_WITH_ZSTD=BUNDLED \
    -DARROW_USE_GLOG=OFF \
    -DARROW_JEMALLOC=BUNDLED \
    -DARROW_BOOST_USE_SHARED=${ARROW_BOOST_USE_SHARED:="OFF"} \
    -DARROW_PARQUET=ON \
    -DARROW_FILESYSTEM=ON \
    -DARROW_S3=ON \
    -DARROW_CUDA=ON \
    -DTHRIFT_HOME=${THRIFT_HOME:-$PREFIX} \
    ${ARROW_TSAN} \
    ..
  makej
  make_install
  popd
}

SNAPPY_VERSION=1.1.7
function install_snappy() {
  download https://github.com/google/snappy/archive/$SNAPPY_VERSION.tar.gz
  extract $SNAPPY_VERSION.tar.gz
  mkdir -p snappy-$SNAPPY_VERSION/build
  pushd snappy-$SNAPPY_VERSION/build
  cmake \
    -DCMAKE_CXX_FLAGS="-fPIC" \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DSNAPPY_BUILD_TESTS=OFF \
    ..
  makej
  make_install
  popd
}

AWSCPP_VERSION=1.7.301

function install_awscpp() {
    # default c++ standard support
    CPP_STANDARD=14
    # check c++17 support
    GNU_VERSION1=$(g++ --version|head -n1|awk '{print $4}'|cut -d'.' -f1)
    if [ "$GNU_VERSION1" = "7" ]; then
        CPP_STANDARD=17
    fi
    rm -rf aws-sdk-cpp-${AWSCPP_VERSION}
    download https://github.com/aws/aws-sdk-cpp/archive/${AWSCPP_VERSION}.tar.gz
    tar xvfz ${AWSCPP_VERSION}.tar.gz
    pushd aws-sdk-cpp-${AWSCPP_VERSION}
    mkdir build
    cd build
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$PREFIX \
        -DBUILD_ONLY="s3;transfer;config" \
        -DBUILD_SHARED_LIBS=0 \
        -DCUSTOM_MEMORY_MANAGEMENT=0 \
        -DCPP_STANDARD=$CPP_STANDARD \
        -DENABLE_TESTING=off \
        ..
    make $*
    make_install
    popd
}

LLVM_VERSION=9.0.1

function install_llvm() {
    VERS=${LLVM_VERSION}
    download ${HTTP_DEPS}/llvm/$VERS/llvm-$VERS.src.tar.xz
    download ${HTTP_DEPS}/llvm/$VERS/clang-$VERS.src.tar.xz
    download ${HTTP_DEPS}/llvm/$VERS/compiler-rt-$VERS.src.tar.xz
    download ${HTTP_DEPS}/llvm/$VERS/lldb-$VERS.src.tar.xz
    download ${HTTP_DEPS}/llvm/$VERS/lld-$VERS.src.tar.xz
    download ${HTTP_DEPS}/llvm/$VERS/libcxx-$VERS.src.tar.xz
    download ${HTTP_DEPS}/llvm/$VERS/libcxxabi-$VERS.src.tar.xz
    download ${HTTP_DEPS}/llvm/$VERS/clang-tools-extra-$VERS.src.tar.xz
    rm -rf llvm-$VERS.src
    extract llvm-$VERS.src.tar.xz
    extract clang-$VERS.src.tar.xz
    extract compiler-rt-$VERS.src.tar.xz
    extract lld-$VERS.src.tar.xz
    extract lldb-$VERS.src.tar.xz
    extract libcxx-$VERS.src.tar.xz
    extract libcxxabi-$VERS.src.tar.xz
    extract clang-tools-extra-$VERS.src.tar.xz
    mv clang-$VERS.src llvm-$VERS.src/tools/clang
    mv compiler-rt-$VERS.src llvm-$VERS.src/projects/compiler-rt
    mv lld-$VERS.src llvm-$VERS.src/tools/lld
    mv lldb-$VERS.src llvm-$VERS.src/tools/lldb
    mv libcxx-$VERS.src llvm-$VERS.src/projects/libcxx
    mv libcxxabi-$VERS.src llvm-$VERS.src/projects/libcxxabi
    mkdir -p llvm-$VERS.src/tools/clang/tools
    mv clang-tools-extra-$VERS.src llvm-$VERS.src/tools/clang/tools/extra
    rm -rf build.llvm-$VERS
    mkdir build.llvm-$VERS
    pushd build.llvm-$VERS
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX -DLLVM_ENABLE_RTTI=on -DLLVM_USE_INTEL_JITEVENTS=on ../llvm-$VERS.src
    makej
    make install
    popd
}

PROJ_VERSION=5.2.0
GDAL_VERSION=2.4.2

function install_gdal() {
    # expat
    download_make_install https://github.com/libexpat/libexpat/releases/download/R_2_2_5/expat-2.2.5.tar.bz2

    # kml
    download ${HTTP_DEPS}/libkml-master.zip
    unzip -u libkml-master.zip
    pushd libkml-master
    ./autogen.sh || true
    CXXFLAGS="-std=c++03" ./configure --with-expat-include-dir=$PREFIX/include/ --with-expat-lib-dir=$PREFIX/lib --prefix=$PREFIX --enable-static --disable-java --disable-python --disable-swig
    makej
    make install
    popd

    # proj
    download_make_install ${HTTP_DEPS}/proj-${PROJ_VERSION}.tar.gz

    # gdal
    download_make_install ${HTTP_DEPS}/gdal-${GDAL_VERSION}.tar.gz "" "--without-geos --with-libkml=$PREFIX --with-proj=$PREFIX"
}

GEOS_VERSION=3.8.1

function install_geos() {
    download_make_install ${HTTP_DEPS}/geos-${GEOS_VERSION}.tar.bz2 "" "--enable-shared --disable-static"

}

RDKAFKA_VERSION=1.1.0

function install_rdkafka() {
    if [ "$1" == "static" ]; then
      STATIC="ON"
    else
      STATIC="OFF"
    fi
    VERS=${RDKAFKA_VERSION}
    download https://github.com/edenhill/librdkafka/archive/v$VERS.tar.gz
    extract v$VERS.tar.gz
    BDIR="librdkafka-$VERS/build"
    mkdir -p $BDIR
    pushd $BDIR
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$PREFIX \
        -DRDKAFKA_BUILD_STATIC=$STATIC \
        -DRDKAFKA_BUILD_EXAMPLES=OFF \
        -DRDKAFKA_BUILD_TESTS=OFF \
        -DWITH_SASL=OFF \
        -DWITH_SSL=ON \
        ..
    makej
    make install
    popd
}

GO_VERSION=1.14

function install_go() {
    VERS=${GO_VERSION}
    ARCH=$(uname -m)
    ARCH=${ARCH//x86_64/amd64}
    ARCH=${ARCH//aarch64/arm64}
    # https://dl.google.com/go/go$VERS.linux-$ARCH.tar.gz
    download ${HTTP_DEPS}/go$VERS.linux-$ARCH.tar.gz
    extract go$VERS.linux-$ARCH.tar.gz
    rm -rf $PREFIX/go || true
    mv go $PREFIX
}

NINJA_VERSION=1.10.0

function install_ninja() {
  download https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-linux.zip
  unzip -u ninja-linux.zip
  mkdir -p $PREFIX/bin/
  mv ninja $PREFIX/bin/
}

TBB_VERSION=2020.2

function install_tbb() {
  download https://github.com/oneapi-src/oneTBB/archive/v${TBB_VERSION}.tar.gz
  extract v${TBB_VERSION}.tar.gz
  pushd oneTBB-${TBB_VERSION}
  if [ "$1" == "static" ]; then
    make extra_inc=big_iron.inc
    install -d $PREFIX/lib
    install -m755 build/linux_*/*.a* $PREFIX/lib
  else
    make
    install -d $PREFIX/lib
    install -m755 build/linux_*/*.so* $PREFIX/lib
  fi
  install -d $PREFIX/include
  cp -R include/tbb $PREFIX/include
  popd
}

# Establish distro
source /etc/os-release
if [ "$ID" == "ubuntu" ] ; then
  PACKAGER="apt -y"
  if [ "$VERSION_ID" != "19.10" ] && [ "$VERSION_ID" != "19.04" ] && [ "$VERSION_ID" != "18.04" ] && [ "$VERSION_ID" != "16.04" ]; then
    echo "Ubuntu 19.10, 19.04, 18.04, and 16.04 are the only debian-based releases supported by this script"
    exit 1
  fi
else
  echo "Only Ubuntu is supported by this script"
  exit 1
fi

sudo mkdir -p $PREFIX
sudo chown -R $(id -u) $PREFIX

sudo apt update
sudo apt install -y \
    software-properties-common \
    build-essential \
    ccache \
    git \
    wget \
    curl \
    gcc-8 \
    g++-8 \
    libboost-all-dev \
    libgoogle-glog-dev \
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

# Set up gcc-8 as default gcc
sudo update-alternatives \
  --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 \
  --slave /usr/bin/g++ g++ /usr/bin/g++-8

# Needed to find sqlite3, xmltooling, and xml_security_c
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig:$PKG_CONFIG_PATH
export PATH=$PREFIX/bin:$PATH

install_ninja

install_cmake

# llvm
# (see common-functions.sh)
install_llvm

# Geo Support
install_gdal
install_geos

# install AWS core and s3 sdk
install_awscpp -j $(nproc)

VERS=0.13.0
wget --continue http://apache.claz.org/thrift/$VERS/thrift-$VERS.tar.gz
tar xvf thrift-$VERS.tar.gz
pushd thrift-$VERS
CFLAGS="-fPIC" CXXFLAGS="-fPIC" JAVA_PREFIX=$PREFIX/lib ./configure \
    --with-lua=no \
    --with-python=no \
    --with-php=no \
    --with-ruby=no \
    --with-qt4=no \
    --with-qt5=no \
    --with-java=no \
    --prefix=$PREFIX
make -j $(nproc)
make install
popd

#c-blosc
VERS=1.14.4
wget --continue https://github.com/Blosc/c-blosc/archive/v$VERS.tar.gz
tar xvf v$VERS.tar.gz
BDIR="c-blosc-$VERS/build"
rm -rf "$BDIR"
mkdir -p "$BDIR"
pushd "$BDIR"
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DBUILD_BENCHMARKS=off \
    -DBUILD_TESTS=off \
    -DPREFER_EXTERNAL_SNAPPY=off \
    -DPREFER_EXTERNAL_ZLIB=off \
    -DPREFER_EXTERNAL_ZSTD=off \
    ..
make -j $(nproc)
make install
popd

VERS=2019.04.29.00
download https://github.com/facebook/folly/archive/v$VERS.tar.gz
extract v$VERS.tar.gz
pushd folly-$VERS/build/
CXXFLAGS="-fPIC -pthread" cmake -DCMAKE_INSTALL_PREFIX=$PREFIX -DBUILD_SHARED_LIBS=on ..
makej
make install
popd

download_make_install ${HTTP_DEPS}/bisonpp-1.21-45.tar.gz bison++-1.21

# TBB
install_tbb

# Apache Arrow (see common-functions.sh)
ARROW_BOOST_USE_SHARED="ON"
install_arrow

# Go
install_go

VERS=3.0.2
wget --continue https://github.com/cginternals/glbinding/archive/v$VERS.tar.gz
tar xvf v$VERS.tar.gz
mkdir -p glbinding-$VERS/build
pushd glbinding-$VERS/build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DOPTION_BUILD_DOCS=OFF \
    -DOPTION_BUILD_EXAMPLES=OFF \
    -DOPTION_BUILD_GPU_TESTS=OFF \
    -DOPTION_BUILD_TESTS=OFF \
    -DOPTION_BUILD_TOOLS=OFF \
    -DOPTION_BUILD_WITH_BOOST_THREAD=OFF \
    ..
make -j $(nproc)
make install
popd

# librdkafka
install_rdkafka

# glslang (with spirv-tools)
VERS=7.12.3352 # 8/20/19
rm -rf glslang
mkdir -p glslang
pushd glslang
wget --continue https://github.com/KhronosGroup/glslang/archive/$VERS.tar.gz
tar xvf $VERS.tar.gz
pushd glslang-$VERS
./update_glslang_sources.py
mkdir build
pushd build
cmake \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    ..
make -j $(nproc)
make install
popd # build
popd # glslang-$VERS
popd # glslang

# spirv-cross
VERS=2019-09-04
rm -rf spirv-cross
mkdir -p spirv-cross
pushd spirv-cross
wget --continue https://github.com/KhronosGroup/SPIRV-Cross/archive/$VERS.tar.gz
tar xvf $VERS.tar.gz
pushd SPIRV-Cross-$VERS
mkdir build
pushd build
cmake \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_POSITION_INDEPENDENT_CODE=on \
    -DSPIRV_CROSS_ENABLE_TESTS=off \
    ..
make -j $(nproc)
make install
popd # build
popd # SPIRV-Cross-$VERS
popd # spirv-cross

# Vulkan
# Custom tarball which excludes the spir-v toolchain
VERS=1.1.126.0 # 11/1/19
rm -rf vulkan
mkdir -p vulkan
pushd vulkan
wget --continue ${HTTP_DEPS}/vulkansdk-linux-x86_64-no-spirv-$VERS.tar.gz -O vulkansdk-linux-x86_64-no-spirv-$VERS.tar.gz
tar xvf vulkansdk-linux-x86_64-no-spirv-$VERS.tar.gz
rsync -av $VERS/x86_64/* $PREFIX
popd # vulkan

# OpenSAML
download_make_install ${HTTP_DEPS}/xml-security-c-2.0.2.tar.gz "" "--without-xalan"
download_make_install ${HTTP_DEPS}/xmltooling-3.0.4-nolog4shib.tar.gz
download_make_install ${HTTP_DEPS}/opensaml-3.0.1-nolog4shib.tar.gz

cat > $PREFIX/mapd-deps.sh <<EOF
PREFIX=$PREFIX
LD_LIBRARY_PATH=/usr/local/cuda/lib64:\$LD_LIBRARY_PATH
LD_LIBRARY_PATH=\$PREFIX/lib:\$LD_LIBRARY_PATH
LD_LIBRARY_PATH=\$PREFIX/lib64:\$LD_LIBRARY_PATH
PATH=/usr/local/cuda/bin:\$PATH
PATH=\$PREFIX/go/bin:\$PATH
PATH=\$PREFIX/bin:\$PATH
VULKAN_SDK=\$PREFIX
VK_LAYER_PATH=\$PREFIX/etc/vulkan/explicit_layer.d
CMAKE_PREFIX_PATH=\$PREFIX:\$CMAKE_PREFIX_PATH
GOROOT=\$PREFIX/go
export LD_LIBRARY_PATH PATH VULKAN_SDK VK_LAYER_PATH CMAKE_PREFIX_PATH GOROOT
EOF

echo
echo "Done. Be sure to source the 'mapd-deps.sh' file to pick up the required environment variables:"
echo "    source $PREFIX/mapd-deps.sh"

tar acvf /mapd-deps.tar.xz -C ${PREFIX} .
