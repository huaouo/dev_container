FROM ubuntu:20.04 AS builder
RUN apt update -y && DEBIAN_FRONTEND="noninteractive" apt install -y gcc
COPY pause.c /
RUN gcc -O3 -o /pause /pause.c

# CUDA version is limited by Nsight Systems v2021.3.1
FROM nvidia/cuda:11.2.2-devel-ubuntu20.04
RUN sed -E -i 's/(archive|security).ubuntu.com/cernet.mirrors.ustc.edu.cn/g' /etc/apt/sources.list \
&& apt update -y \
&& apt upgrade -y \
&& apt install -y apt-transport-https apt-utils \
&& sh -c 'yes | unminimize' \
&& echo 'deb https://apt.kitware.com/ubuntu/ focal main' | tee /etc/apt/sources.list.d/kitware.list \
&& printf "deb http://ddebs.ubuntu.com focal main restricted universe multiverse\ndeb http://ddebs.ubuntu.com focal-updates main restricted universe multiverse\ndeb http://ddebs.ubuntu.com focal-proposed main restricted universe multiverse\n" | tee /etc/apt/sources.list.d/ddebs.list \
&& apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DE19EB17684BA42D \
&& apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C8CAB6595FDFF622 \
&& apt update -y \
&& DEBIAN_FRONTEND="noninteractive" TZ="Asia/Shanghai" apt install -y locales openssh-server sudo git tmux p7zip-rar zip unzip curl vim-nox rsync cmake g++ clang libclang-dev gdb valgrind libstdc++6-dbgsym \
&& apt clean all \
&& locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
&& sed -E -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config \
&& useradd -s /bin/bash -G sudo -m huaouo \
&& sh -c 'echo "huaouo:d" | chpasswd' \
&& sh -c 'echo "root:d" | chpasswd' \
&& printf "PATH=/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games\nLD_LIBRARY_PATH=/usr/local/cuda/lib64\n" | tee /etc/environment \
&& printf '#!/bin/bash\n\nsource /etc/environment\ncmake "$@"\n' | tee /usr/local/bin/wcmake \
&& chmod +x /usr/local/bin/wcmake
COPY docker-entrypoint.sh /
COPY --from=builder /pause /
RUN chmod 755 /docker-entrypoint.sh
EXPOSE 22
ENTRYPOINT /docker-entrypoint.sh
