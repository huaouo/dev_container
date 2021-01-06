FROM nvidia/cuda:10.1-devel-ubuntu18.04

RUN sh -c 'yes | unminimize'
RUN apt update -y && apt install -y openssh-server sudo fish cmake gdb clang valgrind git openjdk-8-jdk-headless && apt clean all
RUN sed -E -i s/(archive|security).ubuntu.com/mirrors.ustc.edu.cn/g /etc/apt/sources.list

RUN useradd -s /usr/bin/fish -G sudo huaouo && sh -c 'echo "huaouo:d" | chpasswd'
RUN mkdir -p /home/huaouo/.ssh && chmod 700 /home/huaouo/.ssh && echo "ssh-rsa AAAAB3NzaC\
1yc2EAAAADAQABAAACAQC33kTAzc4fO73GYu2B/TJ25VgXi+QzVCp2SFz+paqyQv0IpfBywa+sgzHjjcEROh+EmjW\
twd0jxJPX0tPzZQG2r4+yP3lLkBAjOzxABZtX8Fzu4jfsfdppGw0k49HFF4WNCjDqd8NqDyNI6hkaR3kjSWQrDPQD\
C66vW8A4Nf/MxYKQ2eBWQme4Zko4yeBjbatfj+u9j4196gDvnOu1BTbijAh8jSX/CPHHVJdo2l4ziJdzG2CBj7xPMf\
xFPtt2rmTEwMga68QGXXPVN04sb5dIX0oilskOmoPr79LwIjI4Rnf2vZK5j5RULE7yi3rkeiFmtWC3xiDeyemJcKfV\
VGT79fsThG+qtp4jvF5nyaxnVBuLAiTOouRl6Db1VJREe1RbreAfSgmrRJGrT98b8cSp+itJX6Ta0FqgQW9XDY2Vru\
BB6XEU4aBEQ6U7Sp0Q/6hWZs75AfagSMx0RT+CH3YYcJ7MLPQ3d3+nxsSooMvCdvRHDUc2M3J/EtnxQKqd8VSxF/X1K\
UgKmKQlRIfoljfQR7RSShujU0xN5ZO3Dq8H59ur1WoxOEkt4lHl2TfMWDYJqNSIIrAbT2IlXzm3XOnmGlDp8Ncd5RrE\
K9xpaX2EjRevK5r3iZN77aXaGoUpfWfc/e/IrFDVEZ5dtZzmNSEEVn15iNY7KRL0CKwQpAhaRQ== d" \
>> /home/huaouo/.ssh/authorized_keys && chmod 600 /home/huaouo/.ssh/authorized_keys && \
chown -R huaouo:huaouo /home/huaouo

RUN sh -c 'echo -e "#!/bin/sh\n\
service ssh start 2>&1 >/dev/null\n\
read" >> /docker-entrypoint.sh' && chmod 755 /docker-entrypoint.sh

EXPOSE 22
ENTRYPOINT /docker-entrypoint.sh
