FROM ubuntu:20.04 AS builder
COPY mapd-deps-ubuntu-20.04-latest.tar.xz /
RUN apt update -y && apt install -y xz-utils && mkdir -p /usr/local/mapd-deps && \
    cd /usr/local/mapd-deps && tar xvf /mapd-deps-ubuntu-20.04-latest.tar.xz

FROM huaouo/dev_cuda:latest
COPY --from=builder /usr/local/mapd-deps /usr/local
COPY mapd-deps.sh /usr/local/mapd-deps/
RUN ln -sf /usr/local/mapd-deps/mapd-deps.sh /etc/profile.d/xx-mapd-deps.sh && \
    apt update -y && \
    apt install -y software-properties-common build-essential \
    ccache cmake wget gcc-8 g++-8 libboost-all-dev libgoogle-glog-dev \
    golang libssl-dev libevent-dev default-jdk-headless maven libncurses5-dev \
    libldap2-dev binutils-dev google-perftools libdouble-conversion-dev libevent-dev \
    libgflags-dev libgoogle-perftools-dev libiberty-dev libjemalloc-dev \
    libglu1-mesa-dev liblz4-dev liblzma-dev libbz2-dev libarchive-dev \
    libcurl4-openssl-dev libedit-dev uuid-dev libsnappy-dev zlib1g-dev libxerces-c-dev \
    libxmlsec1-dev autoconf autoconf-archive automake bison flex-old libpng-dev \
    rsync jq python-dev python-yaml swig && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 800 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-8