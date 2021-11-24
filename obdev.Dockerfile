FROM centos:centos7
RUN /bin/bash -c "yum install -y openssh-server sudo && yum clean all"
RUN sed -E -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config && sed -E -i 's/#ClientAliveInterval 0/ClientAliveInterval 60/g' /etc/ssh/sshd_config && sed -E -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 10/g' /etc/ssh/sshd_config
RUN ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' && ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' && ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
RUN useradd -s /bin/bash -G wheel ob && sh -c 'echo "ob:ob" | chpasswd'
EXPOSE 22
ENTRYPOINT ["/usr/sbin/sshd", "-D"]
