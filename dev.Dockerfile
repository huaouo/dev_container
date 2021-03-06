FROM ubuntu:20.04 AS builder
RUN apt update -y && apt install -y gcc
COPY pause.c /
RUN gcc -O3 -o /pause /pause.c

FROM ubuntu:20.04
RUN apt update -y && apt upgrade -y && \
DEBIAN_FRONTEND="noninteractive" TZ="Asia/Shanghai" apt install -y locales openssh-server sudo \
git tmux p7zip-rar zip unzip curl vim-nox && apt clean all
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
RUN sh -c 'yes | unminimize'
RUN sed -E -i 's/(archive|security).ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
RUN useradd -s /bin/bash -G sudo huaouo && sh -c 'echo "huaouo:d" | chpasswd'
RUN mkdir -p /home/huaouo/.ssh && chmod 700 /home/huaouo/.ssh
COPY authorized_keys /home/huaouo/.ssh/
RUN chmod 600 /home/huaouo/.ssh/authorized_keys && chown -R huaouo:huaouo /home/huaouo
COPY docker-entrypoint.sh /
COPY --from=builder /pause /
RUN chmod 755 /docker-entrypoint.sh
EXPOSE 22
ENTRYPOINT /docker-entrypoint.sh
