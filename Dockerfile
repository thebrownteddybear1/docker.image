FROM ubuntu:latest

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Update apt and install initial packages
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    tree \
    nano \
    openssh-server \
    iproute2 \
    iputils-ping \
    net-tools \
    git \
    gh \
    ansible \
    ssh \
    sudo \
    bash-completion \
    vim \
    sshpass \
    openssl \
    tcpdump \
    wget \
    ca-certificates \
    perl \
    netplan.io \
    frr \
    dnsmasq \
    curl \
    gzip \
    zip \
    unzip \
    software-properties-common \
    python3 \
    python3-pip \
    python3-pyvmomi\
    && rm -rf /var/lib/apt/lists/*
#install for the ansible community.vmware  module
#RUN pip3 install PyVmomi --break-system-packages;\
RUN ansible-galaxy collection install community.vmware
RUN ansible-galaxy collection install git+https://github.com/vmware/ansible-for-nsxt.git

RUN ansible-galaxy collection install community.general
RUN ansible-galaxy collection install ansible.posix



RUN cd /root; unzip VMware-ovftool-5.0.0-24781994-lin.x86_64.zip && \
    chmod +x /root/ovftool/ovftool

# Install Carvel tools
RUN wget -O install.sh https://carvel.dev/install.sh && \
    chmod +x install.sh && \
    bash ./install.sh
RUN git clone https://x-access-token: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@github.com/thebrownteddybear1/tonjiak.git
# SSH Setup
RUN mkdir -p /var/run/sshd && \
    echo 'root:VMware1!VMware1!' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh
# Copy your application files
COPY path /root/path
COPY 50-cloud-init.yaml /root/
COPY /root/docker.image/VMware-ovftool-5.0.0-24781994-lin.x86_64.zip /root
COPY vcenter.install.scripts /root/vcenter.install.scripts


RUN cp /root/path/kubectl /usr/local/bin && \
    cp /root/path/kubectl-vsphere /usr/local/bin

# Set a working directory
WORKDIR /root

# *** HARCODED TOKEN ***
ENV TOKEN=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
RUN   git config --global user.email "thebrownteddybear@gmail.com" &&\ 
  git config --global user.name "teddy"
# Configure Git and clone repository
RUN git config --global credential.helper store

# Copy ansible.cfg
COPY ansible.cfg /root/

# Expose SSH port
EXPOSE 22

# Create a startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'mkdir -p /var/run/sshd' >> /start.sh && \
    echo '/usr/sbin/sshd -D &' >> /start.sh && \
    echo 'echo "SSH server started on port 22"' >> /start.sh && \
    echo 'echo "Connect using: ssh root@localhost -p 2222"' >> /start.sh && \
    echo 'echo "Password:VMware1!VMware1!"' >> /start.sh && \
    echo 'echo ""' >> /start.sh && \
    echo 'echo "Repository cloned to /root/tonjiak"' >> /start.sh && \
    echo 'ls -la /root/tonjiak/' >> /start.sh && \
    echo export token=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  &&\
    echo  export clone="git clone https://x-access-token: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@github.com/thebrownteddybear1/tonjiak.git" &&\
    git clone https://x-access-token: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@github.com/thebrownteddybear1/tonjiak.git && \
    echo 'tail -f /dev/null' >> /start.sh && \
    chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
