FROM nvidia/cuda:10.1-devel-ubuntu18.04

RUN apt update -y
RUN sh -c 'yes | unminimize'
RUN apt install -y openssh-server sudo fish cmake clang valgrind git openjdk-8-jdk-headless
RUN apt clean all
RUN sed -i s/archive.ubuntu.com/mirrors.ustc.edu.cn/g /etc/apt/sources.list
RUN sed -i s/security.ubuntu.com/mirrors.ustc.edu.cn/g /etc/apt/sources.list

RUN useradd -s /usr/bin/fish -G sudo huaouo
RUN mkdir -p /home/huaouo/.ssh
RUN chmod 700 /home/huaouo/.ssh
RUN echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC33kTAzc4fO73GYu2B/TJ25VgXi+QzVCp2SFz+paq\
yQv0IpfBywa+sgzHjjcEROh+EmjWtwd0jxJPX0tPzZQG2r4+yP3lLkBAjOzxABZtX8Fzu4jfsfdppGw0k49HFF4WN\
CjDqd8NqDyNI6hkaR3kjSWQrDPQDC66vW8A4Nf/MxYKQ2eBWQme4Zko4yeBjbatfj+u9j4196gDvnOu1BTbijAh8j\
SX/CPHHVJdo2l4ziJdzG2CBj7xPMfxFPtt2rmTEwMga68QGXXPVN04sb5dIX0oilskOmoPr79LwIjI4Rnf2vZK5j5\
RULE7yi3rkeiFmtWC3xiDeyemJcKfVVGT79fsThG+qtp4jvF5nyaxnVBuLAiTOouRl6Db1VJREe1RbreAfSgmrRJGr\
T98b8cSp+itJX6Ta0FqgQW9XDY2VruBB6XEU4aBEQ6U7Sp0Q/6hWZs75AfagSMx0RT+CH3YYcJ7MLPQ3d3+nxsSooM\
vCdvRHDUc2M3J/EtnxQKqd8VSxF/X1KUgKmKQlRIfoljfQR7RSShujU0xN5ZO3Dq8H59ur1WoxOEkt4lHl2TfMWDYJ\
qNSIIrAbT2IlXzm3XOnmGlDp8Ncd5RrEK9xpaX2EjRevK5r3iZN77aXaGoUpfWfc/e/IrFDVEZ5dtZzmNSEEVn15iNY\
7KRL0CKwQpAhaRQ== d" >> /home/huaouo/.ssh/authorized_keys
RUN chmod 600 /home/huaouo/.ssh/authorized_keys
RUN chown -R huaouo:huaouo /home/huaouo
RUN sh -c 'echo "huaouo:d" | chpasswd'

RUN echo -e "#!/bin/sh\n\
service ssh start 2>&1 >/dev/null\n\
read" >> /docker-entrypoint.sh
RUN chmod 755 /docker-entrypoint.sh

EXPOSE 22
ENTRYPOINT /docker-entrypoint.sh
